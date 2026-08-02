# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.RemediationLifecycle do
  @moduledoc """
  Fail-closed A2A lifecycle for controlled remediation.

  Model output enters only through `submit/2` as a structured proposal. Every
  subsequent step is delegated to a trusted typed adapter: validation, fresh
  evidence, policy, optional operator approval, restricted execution, and
  verification. Executors are intentionally not part of this public API.

  A durable `remediation_intent_accepted` audit event is required immediately
  before execution. If it cannot be persisted, the adapter's execution
  callback is never invoked. Audit failure after execution creates a
  reconciliation artifact and never retries the action.
  """

  use GenServer

  alias Exocomp.A2A.{AgentSkill, Artifact, DataPart, Message, Task, TaskStatus}
  alias Exocomp.Coordinator.Audit
  alias Exocomp.Coordinator.RemediationAdapter.FailClosed

  @skill_id "remediation.execute"
  @terminal_states [:completed, :failed, :canceled]
  @default_approval_timeout_ms 60_000
  @default_model_output_bytes 4_096

  @spec skill() :: AgentSkill.t()
  def skill do
    %AgentSkill{
      id: @skill_id,
      name: "Controlled remediation",
      description:
        "Validate and execute a typed, policy-controlled remediation proposal with audit",
      inputModes: ["application/json"],
      outputModes: ["application/json"]
    }
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @spec submit(map(), keyword()) :: {:ok, Task.t()} | {:error, term()}
  def submit(proposal, opts \\ [])

  def submit(proposal, opts) when is_map(proposal) do
    GenServer.call(Keyword.get(opts, :server, __MODULE__), {:submit, proposal})
  end

  def submit(_proposal, _opts), do: {:error, :malformed_proposal}

  @spec approve(String.t(), term(), keyword()) :: {:ok, Task.t()} | {:error, term()}
  def approve(task_id, approval, opts \\ []) do
    GenServer.call(Keyword.get(opts, :server, __MODULE__), {:approve, task_id, approval})
  end

  @spec deny(String.t(), String.t(), keyword()) :: {:ok, Task.t()} | {:error, term()}
  def deny(task_id, reason, opts \\ []) when is_binary(reason) do
    GenServer.call(Keyword.get(opts, :server, __MODULE__), {:deny, task_id, reason})
  end

  @spec cancel(String.t(), keyword()) :: {:ok, Task.t()} | {:error, term()}
  def cancel(task_id, opts \\ []) do
    GenServer.call(Keyword.get(opts, :server, __MODULE__), {:cancel, task_id})
  end

  @spec get(String.t(), keyword()) :: {:ok, Task.t()} | {:error, :not_found}
  def get(task_id, opts \\ []) do
    GenServer.call(Keyword.get(opts, :server, __MODULE__), {:get, task_id})
  end

  @impl true
  def init(opts) do
    audit_server = Keyword.get(opts, :audit, Audit)

    audit =
      Keyword.get(opts, :audit_fun, fn type, attributes, correlation_id ->
        Audit.emit(type, attributes, server: audit_server, correlation_id: correlation_id)
      end)

    audit_events =
      Keyword.get(opts, :audit_reader, fn ->
        Audit.events(audit_server)
      end)

    {:ok,
     %{
       tasks: %{},
       adapter: Keyword.get(opts, :adapter, FailClosed),
       audit: audit,
       audit_events: audit_events,
       durable_audit?:
         Keyword.has_key?(opts, :audit_reader) or
           not Keyword.has_key?(opts, :audit_fun),
       audit_server: audit_server,
       approval_timeout_ms: Keyword.get(opts, :approval_timeout_ms, @default_approval_timeout_ms),
       model_output_bytes: Keyword.get(opts, :model_output_bytes, @default_model_output_bytes),
       redactor: Keyword.get(opts, :redactor, &Audit.redact/1)
     }}
  end

  @impl true
  def handle_call({:submit, proposal}, _from, state) do
    task_id = uuid()
    correlation_id = Audit.correlation_id()
    recorded_proposal = sanitize(proposal, state)
    task = new_task(task_id, correlation_id, recorded_proposal)
    state = put_entry(state, task_id, %{task: task, evidence: nil, action: nil})

    case audit(state, :proposal_received, task, %{proposal: recorded_proposal}) do
      :ok ->
        {reply, state} = process_proposal(task_id, proposal, state)
        {:reply, reply, state}

      {:error, reason} ->
        {task, state} = terminal(state, task_id, :failed, :audit_unavailable, reason)
        {:reply, {:ok, task}, state}
    end
  end

  def handle_call({:get, task_id}, _from, state) do
    case Map.fetch(state.tasks, task_id) do
      {:ok, entry} -> {:reply, {:ok, entry.task}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:approve, task_id, approval}, _from, state) do
    with {:ok, entry} <- fetch_waiting(state, task_id),
         :ok <- audit(state, :approval_granted, entry.task, %{approval_provided: true}) do
      cancel_timer(entry)
      state = transition(state, task_id, :working, :approval_granted, %{})
      {task, state} = execute(task_id, approval, state)
      {:reply, {:ok, task}, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:deny, task_id, reason}, _from, state) do
    with {:ok, entry} <- fetch_waiting(state, task_id),
         :ok <- audit(state, :approval_denied, entry.task, %{reason: reason}) do
      cancel_timer(entry)
      {task, state} = terminal(state, task_id, :completed, :approval_denied, reason)
      {:reply, {:ok, task}, state}
    else
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:cancel, task_id}, _from, state) do
    case Map.fetch(state.tasks, task_id) do
      :error ->
        {:reply, {:error, :not_found}, state}

      {:ok, %{task: %{status: %{state: task_state}}}} when task_state in @terminal_states ->
        {:reply, {:error, :not_cancelable}, state}

      {:ok, entry} ->
        cancel_timer(entry)

        case audit(state, :remediation_canceled, entry.task, %{}) do
          :ok ->
            {task, state} = terminal(state, task_id, :canceled, :canceled, nil)
            {:reply, {:ok, task}, state}

          {:error, reason} ->
            {:reply, {:error, {:audit_unavailable, reason}}, state}
        end
    end
  end

  @impl true
  def handle_info({:approval_timeout, task_id}, state) do
    case fetch_waiting(state, task_id) do
      {:ok, entry} ->
        _ = audit(state, :approval_timed_out, entry.task, %{})
        {_task, state} = terminal(state, task_id, :failed, :approval_timeout, nil)
        {:noreply, state}

      {:error, _reason} ->
        {:noreply, state}
    end
  end

  defp process_proposal(task_id, raw, state) do
    state = transition(state, task_id, :working, :validation_started, %{})
    adapter_raw = adapter_context(raw, task!(state, task_id), state)

    with {:ok, proposal} <- invoke(state.adapter, :validate_proposal, [adapter_raw]),
         :ok <- stage_audit(state, task_id, :proposal_validated, %{proposal: proposal}),
         {:ok, evidence} <- invoke(state.adapter, :collect_evidence, [proposal]),
         :ok <- stage_audit(state, task_id, :evidence_collected, %{evidence: evidence}),
         decision <- invoke(state.adapter, :decide, [proposal, evidence]) do
      state = update_entry(state, task_id, &Map.put(&1, :evidence, evidence))
      apply_decision(task_id, decision, state)
    else
      {:error, reason} ->
        {task, state} = terminal(state, task_id, :failed, :validation_failed, reason)
        {{:ok, task}, state}
    end
  end

  defp apply_decision(task_id, {:deny, reason}, state) do
    case stage_audit(state, task_id, :policy_decided, %{decision: :deny, reason: reason}) do
      :ok ->
        {task, state} = terminal(state, task_id, :completed, :policy_denied, reason)
        {{:ok, task}, state}

      {:error, audit_error} ->
        {task, state} = terminal(state, task_id, :failed, :audit_unavailable, audit_error)
        {{:ok, task}, state}
    end
  end

  defp apply_decision(task_id, {:allow, action}, state) do
    case stage_audit(state, task_id, :policy_decided, %{decision: :allow, action: action}) do
      :ok ->
        action = correlate_action(action, task!(state, task_id), state)
        state = update_entry(state, task_id, &Map.put(&1, :action, action))

        case reconcile_execution(action, state) do
          {:ok, state} ->
            {{:ok, task!(state, task_id)}, state}

          {:error, reason, state} ->
            {task, state} =
              terminal(state, task_id, :failed, :audit_reconciliation_required, reason)

            {{:ok, task}, state}

          {:none, state} ->
            {task, state} = execute(task_id, nil, state)
            {{:ok, task}, state}
        end

      {:error, reason} ->
        {task, state} = terminal(state, task_id, :failed, :audit_unavailable, reason)
        {{:ok, task}, state}
    end
  end

  defp apply_decision(task_id, {:approval_required, action, request}, state) do
    action = correlate_action(action, task!(state, task_id), state)

    with :ok <-
           stage_audit(state, task_id, :policy_decided, %{
             decision: :approval_required,
             action: action
           }),
         :ok <- stage_audit(state, task_id, :approval_requested, %{request: request}) do
      timer = Process.send_after(self(), {:approval_timeout, task_id}, state.approval_timeout_ms)

      state =
        state
        |> update_entry(task_id, &Map.merge(&1, %{action: action, timer: timer}))
        |> transition(task_id, :input_required, :approval_required, request)

      {{:ok, task!(state, task_id)}, state}
    else
      {:error, reason} ->
        {task, state} = terminal(state, task_id, :failed, :audit_unavailable, reason)
        {{:ok, task}, state}
    end
  end

  defp apply_decision(task_id, {:error, reason}, state) do
    {task, state} = terminal(state, task_id, :failed, :policy_failed, reason)
    {{:ok, task}, state}
  end

  defp apply_decision(task_id, other, state) do
    {task, state} = terminal(state, task_id, :failed, :invalid_policy_decision, other)
    {{:ok, task}, state}
  end

  defp execute(task_id, approval, state) do
    entry = Map.fetch!(state.tasks, task_id)

    case audit(state, :remediation_intent_accepted, entry.task, %{
           action: entry.action,
           evidence: entry.evidence,
           approved: not is_nil(approval)
         }) do
      :ok ->
        state = transition(state, task_id, :working, :execution_started, %{})

        case invoke(state.adapter, :execute, [entry.action, entry.evidence, approval]) do
          {:ok, result} ->
            post_execute(task_id, result, state)

          {:error, reason} ->
            _ = stage_audit(state, task_id, :execution_failed, %{reason: reason})
            terminal(state, task_id, :failed, :execution_failed, reason)
        end

      {:error, reason} ->
        terminal(state, task_id, :failed, :audit_unavailable_before_action, reason)
    end
  end

  defp post_execute(task_id, result, state) do
    entry = Map.fetch!(state.tasks, task_id)
    execution_audit = audit(state, :execution_finished, entry.task, %{result: result})

    verification = invoke(state.adapter, :verify, [entry.action, entry.evidence, result])

    case {execution_audit, verification} do
      {:ok, {:ok, verified}} ->
        case stage_audit(state, task_id, :verification_completed, %{result: verified}) do
          :ok ->
            terminal(state, task_id, :completed, :verified, %{
              execution: result,
              verification: verified
            })

          {:error, reason} ->
            terminal(state, task_id, :failed, :audit_reconciliation_required, %{
              execution: result,
              verification: verified,
              audit_error: reason
            })
        end

      {{:error, reason}, _verification} ->
        terminal(state, task_id, :failed, :audit_reconciliation_required, %{
          execution: result,
          audit_error: reason
        })

      {:ok, {:error, reason}} ->
        _ = stage_audit(state, task_id, :verification_failed, %{reason: reason})
        terminal(state, task_id, :failed, :verification_failed, reason)
    end
  end

  defp terminal(state, task_id, task_state, event, detail) do
    state = transition(state, task_id, task_state, event, %{detail: detail})
    task = task!(state, task_id)
    artifact = artifact(task, event, sanitize(%{detail: detail}, state))
    task = %{task | artifacts: task.artifacts ++ [artifact]}
    state = update_entry(state, task_id, &Map.put(&1, :task, task))

    _ =
      audit(state, :remediation_terminal, task, %{
        state: task_state,
        outcome: event,
        detail: detail
      })

    terminal_audit_event =
      case task_state do
        :completed -> :remediation_completed
        :failed -> :remediation_failed
        _ -> nil
      end

    if terminal_audit_event do
      _ =
        audit(state, terminal_audit_event, task, %{
          state: task_state,
          outcome: event,
          detail: detail
        })
    end

    {task, state}
  end

  defp adapter_context(proposal, task, state) do
    proposal
    |> Map.put("_audit_server", state.audit_server)
    |> Map.put("_correlation_id", task.contextId)
  end

  defp correlate_action(action, task, state) when is_map(action) do
    action
    |> Map.put(:audit_server, state.audit_server)
    |> Map.put(:correlation_id, task.contextId)
  end

  defp correlate_action(action, _task, _state), do: action

  defp reconcile_execution(_action, %{durable_audit?: false} = state),
    do: {:none, state}

  defp reconcile_execution(action, state) do
    case safe_audit_events(state) do
      {:ok, events} ->
        case unfinished_execution(events, action) do
          nil ->
            {:none, state}

          %{intent: intent, execution: execution} ->
            detail = %{
              reason: :durable_execution_reconciled,
              intent: intent,
              execution: execution
            }

            {:error, detail, state}
        end

      {:error, reason} ->
        {:error, {:audit_history_unavailable, reason}, state}
    end
  end

  defp safe_audit_events(state) do
    case safe_call(fn -> state.audit_events.() end) do
      {:ok, {:ok, events}} when is_list(events) -> {:ok, events}
      {:ok, {:error, reason}} -> {:error, reason}
      {:ok, other} -> {:error, {:invalid_audit_reader_result, other}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp unfinished_execution(events, action) do
    events
    |> Enum.filter(fn event ->
      event_type(event) == "remediation_intent_accepted" and
        action_matches?(event_attributes(event)["action"], action)
    end)
    |> Enum.reverse()
    |> Enum.find_value(fn intent ->
      correlation_id = event_correlation_id(intent)

      if terminal_for_correlation?(events, correlation_id) do
        nil
      else
        execution =
          Enum.find(events, fn event ->
            event_type(event) == "execution_finished" and
              event_correlation_id(event) == correlation_id
          end)

        %{intent: intent_attributes(intent), execution: event_attributes(execution)}
      end
    end)
  end

  defp terminal_for_correlation?(events, correlation_id) do
    Enum.any?(events, fn event ->
      event_type(event) == "remediation_terminal" and
        event_correlation_id(event) == correlation_id
    end)
  end

  defp action_matches?(event_action, action) when is_map(event_action) and is_map(action) do
    Enum.all?([:action_id, :node_id, :daemon_id, :target_unit], fn key ->
      value(event_action, key) == Map.get(action, key)
    end)
  end

  defp action_matches?(_event_action, _action), do: false

  defp event_type(event), do: value(event, "event_type") || value(event, :event_type)
  defp event_attributes(event), do: value(event, "attributes") || value(event, :attributes) || %{}

  defp event_correlation_id(event),
    do: value(event, "correlation_id") || value(event, :correlation_id)

  defp intent_attributes(event), do: event_attributes(event)

  defp value(map, atom_key) when is_map(map) and is_atom(atom_key),
    do: Map.get(map, atom_key) || Map.get(map, Atom.to_string(atom_key))

  defp value(map, key) when is_map(map), do: Map.get(map, key)
  defp value(_map, _key), do: nil

  defp safe_call(function) do
    function.()
  rescue
    error -> {:error, {:exception, Exception.message(error)}}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp transition(state, task_id, new_state, event, data) do
    update_entry(state, task_id, fn entry ->
      timestamp = timestamp()
      message = message(entry.task, event, sanitize(data, state), timestamp)

      task = %{
        entry.task
        | status: %TaskStatus{state: new_state, message: message, timestamp: timestamp},
          history: entry.task.history ++ [message],
          updated_at: timestamp
      }

      %{entry | task: task}
    end)
  end

  defp stage_audit(state, task_id, type, attrs) do
    task = task!(state, task_id)

    case audit(state, type, task, attrs) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp audit(state, type, task, attrs) do
    state.audit.(type, sanitize(attrs, state), task.contextId)
  rescue
    error -> {:error, {:audit_exception, Exception.message(error)}}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp invoke(module, function, args) when is_atom(module) do
    apply(module, function, args)
  rescue
    error -> {:error, {:adapter_exception, Exception.message(error)}}
  catch
    kind, reason -> {:error, {:adapter_failure, kind, reason}}
  end

  defp new_task(task_id, correlation_id, proposal) do
    timestamp = timestamp()

    %Task{
      id: task_id,
      contextId: correlation_id,
      status: %TaskStatus{state: :submitted, timestamp: timestamp},
      history: [
        %Message{
          role: :user,
          parts: [%DataPart{data: %{"proposal" => proposal}}],
          messageId: uuid(),
          taskId: task_id,
          contextId: correlation_id,
          timestamp: timestamp
        }
      ],
      artifacts: [],
      metadata: %{"skill_id" => @skill_id, "correlation_id" => correlation_id},
      created_at: timestamp,
      updated_at: timestamp
    }
  end

  defp message(task, event, data, timestamp) do
    %Message{
      role: :agent,
      parts: [%DataPart{data: %{"event" => to_string(event), "data" => Audit.redact(data)}}],
      messageId: uuid(),
      taskId: task.id,
      contextId: task.contextId,
      timestamp: timestamp
    }
  end

  defp artifact(task, outcome, detail) do
    %Artifact{
      artifactId: uuid(),
      name: "remediation-result",
      parts: [
        %DataPart{
          data: %{
            "correlation_id" => task.contextId,
            "outcome" => to_string(outcome),
            "detail" => Audit.redact(detail)
          }
        }
      ],
      lastChunk: true,
      metadata: %{"task_id" => task.id, "correlation_id" => task.contextId}
    }
  end

  defp fetch_waiting(state, task_id) do
    case Map.fetch(state.tasks, task_id) do
      {:ok, %{task: %{status: %{state: :input_required}}} = entry} -> {:ok, entry}
      {:ok, _entry} -> {:error, :approval_not_pending}
      :error -> {:error, :not_found}
    end
  end

  defp cancel_timer(%{timer: timer}) when is_reference(timer), do: Process.cancel_timer(timer)
  defp cancel_timer(_entry), do: :ok

  defp sanitize(value, state) do
    redacted = state.redactor.(value)

    case Jason.encode(redacted) do
      {:ok, encoded} when byte_size(encoded) > state.model_output_bytes ->
        %{"truncated" => true, "sha256" => sha256(encoded)}

      _ ->
        redacted
    end
  rescue
    _ -> %{"redacted" => true, "reason" => "unencodable_model_output"}
  end

  defp sha256(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
  defp task!(state, task_id), do: state.tasks |> Map.fetch!(task_id) |> Map.fetch!(:task)

  defp put_entry(state, task_id, entry),
    do: %{state | tasks: Map.put(state.tasks, task_id, entry)}

  defp update_entry(state, task_id, function) do
    %{state | tasks: Map.update!(state.tasks, task_id, function)}
  end

  defp timestamp, do: DateTime.utc_now() |> DateTime.to_iso8601()

  defp uuid do
    <<a::32, b::16, c::16, d::16, e::48>> = :crypto.strong_rand_bytes(16)
    c = Bitwise.bor(Bitwise.band(c, 0x0FFF), 0x4000)
    d = Bitwise.bor(Bitwise.band(d, 0x3FFF), 0x8000)

    Enum.join(
      [
        Integer.to_string(a, 16) |> String.pad_leading(8, "0"),
        Integer.to_string(b, 16) |> String.pad_leading(4, "0"),
        Integer.to_string(c, 16) |> String.pad_leading(4, "0"),
        Integer.to_string(d, 16) |> String.pad_leading(4, "0"),
        Integer.to_string(e, 16) |> String.pad_leading(12, "0")
      ],
      "-"
    )
  end
end
