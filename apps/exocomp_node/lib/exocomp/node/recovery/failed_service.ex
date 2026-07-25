# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Recovery.FailedService do
  @moduledoc """
  Automatic, one-attempt recovery for an already-failed allow-listed service.

  The caller supplies deterministic evidence, audit, executor, and verification
  callbacks. The flow refreshes service state immediately before authorization,
  persists the `failed_and_allowed` transition before invoking the executor,
  and requires consecutive systemd-and-application-health samples before
  completing. Any execution or verification failure enters cooldown and
  terminal escalation without retrying the restart.
  """

  alias Exocomp.A2A.{Artifact, DataPart, Message, Task, TaskStatus}
  alias Exocomp.Node.Executor
  alias Exocomp.Node.Safety.ReplayLedger
  alias Exocomp.Recovery.{AuditEvent, Evidence, StateMachine}

  @action_id :restart_service

  @type callback_result :: {:ok, Evidence.t()} | {:error, term()}

  @type t :: %__MODULE__{
          task: Task.t(),
          machine: StateMachine.t(),
          evidence: Evidence.t(),
          allow_list: [String.t()],
          audit_fun: (AuditEvent.t() -> :ok | {:error, term()}),
          refresh_fun: (String.t(), String.t() -> callback_result()),
          verify_fun: (String.t(), String.t() -> callback_result()),
          executor: module() | function(),
          ledger: GenServer.server(),
          now_fun: (-> DateTime.t()),
          wait_fun: (-> :ok),
          verification_attempts: pos_integer(),
          stability_samples: pos_integer()
        }

  defstruct [
    :task,
    :machine,
    :evidence,
    :allow_list,
    :audit_fun,
    :refresh_fun,
    :verify_fun,
    :executor,
    :ledger,
    :now_fun,
    :wait_fun,
    :verification_attempts,
    :stability_samples
  ]

  @doc """
  Runs one automatic recovery episode to a terminal state.

  Required options are `:task_id`, `:allow_list`, and `:audit_fun`.
  Production callers must also configure fresh `:refresh_fun` and
  `:verify_fun` callbacks. `:stability_samples` defaults to two consecutive
  healthy samples within three `:verification_attempts`.
  """
  @spec recover(Evidence.t(), keyword()) ::
          {:ok, t()} | {:error, term()} | {:error, term(), t()}
  def recover(%Evidence{} = evidence, opts) do
    with {:ok, flow} <- start(evidence, opts) do
      if StateMachine.terminal?(flow.machine), do: {:ok, flow}, else: execute(flow)
    end
  end

  @doc """
  Validates and audits an automatic failed-service proposal.

  On success the returned flow is in `:executing`, but the executor has not
  been invoked. This gives the caller a durable audit boundary before the
  external action. If refreshed evidence shows that the service is no longer
  failed, the returned flow is terminal and no execution is attempted.
  """
  @spec start(Evidence.t(), keyword()) :: {:ok, t()} | {:error, term()}
  def start(%Evidence{} = evidence, opts) do
    task_id = Keyword.fetch!(opts, :task_id)
    node_id = Keyword.get(opts, :node_id, evidence.node_id)
    service = Keyword.get(opts, :service, evidence.service)
    audit_fun = Keyword.fetch!(opts, :audit_fun)
    now_fun = Keyword.get(opts, :now_fun, &DateTime.utc_now/0)
    now = now_fun.()

    with :ok <- validate_options(opts),
         :ok <- validate_target(evidence, node_id, service),
         :ok <- require_failed(evidence),
         :ok <- require_allowed(service, Keyword.fetch!(opts, :allow_list)),
         {:ok, machine, audits} <-
           build_machine(task_id, node_id, service, evidence, opts, now),
         :ok <- persist_all(audits, audit_fun) do
      flow = %__MODULE__{
        task: working_task(task_id, machine.correlation_id, evidence, now),
        machine: machine,
        evidence: evidence,
        allow_list: Keyword.fetch!(opts, :allow_list),
        audit_fun: audit_fun,
        refresh_fun: Keyword.get(opts, :refresh_fun, fn _, _ -> {:ok, evidence} end),
        verify_fun: Keyword.get(opts, :verify_fun, &missing_evidence/2),
        executor: Keyword.get(opts, :executor, Executor),
        ledger: Keyword.get(opts, :ledger, ReplayLedger),
        now_fun: now_fun,
        wait_fun: Keyword.get(opts, :wait_fun, fn -> :ok end),
        verification_attempts: Keyword.get(opts, :verification_attempts, 3),
        stability_samples: Keyword.get(opts, :stability_samples, 2)
      }

      authorize(flow)
    end
  end

  @doc "Invokes the exact executor once, then verifies and terminally records the result."
  @spec execute(t()) :: {:ok, t()} | {:error, term(), t()}
  def execute(%__MODULE__{} = flow) do
    cond do
      StateMachine.terminal?(flow.machine) ->
        {:error, :already_terminal, flow}

      flow.machine.state != :executing ->
        {:error, {:illegal_state, flow.machine.state}, flow}

      true ->
        case claim_execution(flow) do
          :proceed -> execute_claimed(flow)
          :already_claimed -> {:error, :already_terminal, flow}
          {:error, reason} -> {:error, reason, flow}
        end
    end
  end

  defp execute_claimed(flow) do
    result =
      invoke_executor(
        flow.executor,
        @action_id,
        flow.machine.service,
        flow.allow_list
      )

    case complete_execution_claim(flow, result) do
      :ok ->
        case result do
          {:ok, execution_result} -> execution_complete(flow, execution_result)
          {:error, reason} -> execution_failed(flow, reason)
          other -> execution_failed(flow, {:invalid_executor_result, other})
        end

      {:error, reason} ->
        # The external action may already have happened. Escalate without ever
        # reopening the durable claim or attempting the restart again.
        execution_failed(flow, {:replay_completion_failed, reason})
    end
  end

  @doc "Cancels a non-terminal episode before execution."
  @spec cancel(t(), String.t()) :: {:ok, t()} | {:error, term(), t()}
  def cancel(%__MODULE__{} = flow, reason) when is_binary(reason) do
    if StateMachine.terminal?(flow.machine) do
      {:error, :already_terminal, flow}
    else
      case transition(flow, {:cancel, reason}) do
        {:ok, canceled} ->
          {:ok, terminal_task(canceled, :canceled, :recovery_canceled, reason)}

        {:error, error, unchanged} ->
          {:error, error, unchanged}
      end
    end
  end

  defp validate_options(opts) do
    attempts = Keyword.get(opts, :verification_attempts, 3)
    samples = Keyword.get(opts, :stability_samples, 2)

    if is_integer(attempts) and attempts > 0 and is_integer(samples) and samples > 0 and
         samples <= attempts do
      :ok
    else
      {:error, :invalid_verification_window}
    end
  end

  defp build_machine(task_id, node_id, service, evidence, opts, now) do
    machine =
      StateMachine.new(task_id, node_id, service,
        correlation_id: Keyword.get(opts, :correlation_id),
        created_at: now,
        deadline: Keyword.get(opts, :deadline),
        max_evidence_age_seconds: Keyword.get(opts, :max_evidence_age_seconds, 300)
      )

    events = [{:unhealthy_observation, evidence}, {:evidence_complete, evidence}, :validate]

    Enum.reduce_while(events, {:ok, machine, []}, fn event, {:ok, current, audits} ->
      case StateMachine.apply_event(current, event, now: now) do
        {:ok, updated, audit} -> {:cont, {:ok, updated, audits ++ [audit]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp authorize(flow) do
    with {:ok, fresh} <- refresh(flow) do
      cond do
        not failed?(fresh) ->
          no_action(flow, state_change_reason(fresh))

        true ->
          case transition(flow, {:failed_and_allowed, fresh}) do
            {:ok, executing} -> {:ok, executing}
            {:error, reason, _flow} -> {:error, reason}
          end
      end
    else
      {:error, reason} -> no_action(flow, {:evidence_refresh_failed, reason})
    end
  end

  defp execution_complete(flow, result) do
    with {:ok, verifying} <- transition(flow, {:execution_complete, result}) do
      case verify_stability(verifying) do
        {:ok, stable} ->
          with {:ok, completed} <- transition(verifying, {:stable_health, stable}) do
            {:ok, terminal_task(completed, :completed, :recovery_completed, result)}
          end

        {:error, reason} ->
          verification_failed(verifying, reason)
      end
    end
  end

  defp execution_failed(flow, reason) do
    case transition(flow, {:execution_complete, %{error: inspect(reason)}}) do
      {:ok, verifying} -> verification_failed(verifying, {:execution_failed, reason})
      {:error, error, unchanged} -> {:error, error, unchanged}
    end
  end

  defp verify_stability(flow) do
    verify_stability(flow, flow.verification_attempts, 0, nil, nil)
  end

  defp verify_stability(_flow, 0, _stable_count, _last_evidence, last_error),
    do: {:error, {:health_timeout, last_error || :insufficient_stable_samples}}

  defp verify_stability(flow, attempts_left, stable_count, _last_evidence, _last_error) do
    result = flow.verify_fun.(flow.machine.node_id, flow.machine.service)

    case validated_health(flow, result) do
      {:ok, evidence} ->
        count = stable_count + 1

        if count >= flow.stability_samples do
          {:ok, evidence}
        else
          :ok = flow.wait_fun.()
          verify_stability(flow, attempts_left - 1, count, evidence, nil)
        end

      {:error, reason} ->
        if attempts_left == 1 do
          {:error, {:health_timeout, reason}}
        else
          :ok = flow.wait_fun.()
          verify_stability(flow, attempts_left - 1, 0, nil, reason)
        end
    end
  end

  defp validated_health(flow, {:ok, %Evidence{} = evidence}) do
    with :ok <- validate_target(evidence, flow.machine.node_id, flow.machine.service),
         :ok <-
           Evidence.check_freshness(
             evidence,
             flow.now_fun.(),
             flow.machine.max_evidence_age_seconds
           ) do
      if healthy?(evidence),
        do: {:ok, evidence},
        else: {:error, {:unhealthy, evidence.data}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp validated_health(_flow, {:error, reason}), do: {:error, reason}
  defp validated_health(_flow, other), do: {:error, {:invalid_verification_result, other}}

  defp verification_failed(flow, reason) do
    with {:ok, cooling} <- transition(flow, {:failure_or_instability, inspect(reason)}),
         {:ok, escalated} <- transition(cooling, :cooldown_expired) do
      {:ok, terminal_task(escalated, :failed, :recovery_escalated, reason)}
    end
  end

  defp no_action(flow, reason) do
    with {:ok, escalated} <- transition(flow, {:deny_or_no_safe_action, inspect(reason)}) do
      {:ok, terminal_task(escalated, :failed, :recovery_not_executed, reason)}
    end
  end

  defp transition(flow, event) do
    case StateMachine.apply_event(flow.machine, event, now: flow.now_fun.()) do
      {:ok, machine, audit} ->
        case flow.audit_fun.(audit) do
          :ok -> {:ok, %{flow | machine: machine, evidence: machine.evidence}}
          {:error, reason} -> {:error, {:audit_unavailable, reason}, flow}
        end

      {:error, reason} ->
        {:error, reason, flow}
    end
  end

  defp refresh(flow) do
    case flow.refresh_fun.(flow.machine.node_id, flow.machine.service) do
      {:ok, %Evidence{} = evidence} ->
        with :ok <- validate_target(evidence, flow.machine.node_id, flow.machine.service),
             :ok <-
               Evidence.check_freshness(
                 evidence,
                 flow.now_fun.(),
                 flow.machine.max_evidence_age_seconds
               ) do
          {:ok, evidence}
        end

      {:error, reason} ->
        {:error, reason}

      other ->
        {:error, {:invalid_refreshed_evidence, other}}
    end
  end

  defp require_failed(evidence) do
    if failed?(evidence),
      do: :ok,
      else: {:error, {:not_failed_service, value(evidence.data, :active_state)}}
  end

  defp require_allowed(service, allow_list) when is_list(allow_list) do
    if service in allow_list, do: :ok, else: {:error, {:service_not_allowed, service}}
  end

  defp require_allowed(service, _allow_list), do: {:error, {:service_not_allowed, service}}

  defp failed?(%Evidence{data: data}),
    do: value(data, :active_state) in ["failed", "inactive"]

  defp healthy?(%Evidence{data: data}) do
    value(data, :active_state) == "active" and
      value(data, :sub_state) in [nil, "running"] and
      value(data, :health) in ["healthy", "ok"]
  end

  defp state_change_reason(evidence) do
    if healthy?(evidence), do: :service_self_recovered, else: :approval_required_for_live_service
  end

  defp value(map, key) do
    Map.get(map, key, Map.get(map, Atom.to_string(key)))
    |> case do
      atom when is_atom(atom) -> Atom.to_string(atom)
      other -> other
    end
  end

  defp validate_target(%Evidence{node_id: node_id, service: service}, node_id, service),
    do: :ok

  defp validate_target(_evidence, _node_id, _service), do: {:error, :evidence_target_mismatch}

  defp working_task(task_id, correlation_id, evidence, now) do
    timestamp = DateTime.to_iso8601(now)

    message =
      message(
        task_id,
        correlation_id,
        :recovery_started,
        %{evidence_id: evidence.evidence_id, service: evidence.service},
        timestamp
      )

    %Task{
      id: task_id,
      contextId: correlation_id,
      status: %TaskStatus{state: :working, message: message, timestamp: timestamp},
      history: [message],
      artifacts: [],
      metadata: %{
        "action_id" => Atom.to_string(@action_id),
        "evidence_id" => evidence.evidence_id,
        "service" => evidence.service
      },
      created_at: timestamp,
      updated_at: timestamp
    }
  end

  defp terminal_task(flow, task_state, outcome, detail) do
    timestamp = DateTime.to_iso8601(flow.now_fun.())
    message = message(flow.task.id, flow.task.contextId, outcome, %{detail: detail}, timestamp)

    artifact = %Artifact{
      artifactId: id(),
      name: "service-recovery-result",
      parts: [
        %DataPart{
          data: %{
            "correlation_id" => flow.task.contextId,
            "detail" => json_safe(detail),
            "execution_attempted" => flow.machine.execution_attempted,
            "outcome" => Atom.to_string(outcome),
            "recovery_state" => Atom.to_string(flow.machine.state),
            "service" => flow.machine.service
          }
        }
      ],
      lastChunk: true,
      metadata: %{"task_id" => flow.task.id}
    }

    task = %{
      flow.task
      | status: %TaskStatus{state: task_state, message: message, timestamp: timestamp},
        history: flow.task.history ++ [message],
        artifacts: flow.task.artifacts ++ [artifact],
        updated_at: timestamp
    }

    %{flow | task: task}
  end

  defp message(task_id, correlation_id, event, data, timestamp) do
    %Message{
      role: :agent,
      parts: [
        %DataPart{data: %{"event" => Atom.to_string(event), "data" => json_safe(data)}}
      ],
      messageId: id(),
      taskId: task_id,
      contextId: correlation_id,
      timestamp: timestamp
    }
  end

  defp persist_all(audits, audit_fun) do
    Enum.reduce_while(audits, :ok, fn audit, :ok ->
      case audit_fun.(audit) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {:audit_unavailable, reason}}}
      end
    end)
  end

  defp invoke_executor(executor, action_id, target, allow_list) when is_atom(executor),
    do: executor.execute(action_id, target, allow_list)

  defp invoke_executor(executor, action_id, target, allow_list)
       when is_function(executor, 3),
       do: executor.(action_id, target, allow_list)

  defp missing_evidence(_node_id, _service), do: {:error, :evidence_collector_not_configured}

  defp claim_execution(flow) do
    attrs = %{
      task_id: flow.task.id,
      action_id: @action_id,
      target: flow.machine.service
    }

    case ReplayLedger.claim(flow.machine.correlation_id, attrs, flow.ledger) do
      {:ok, :proceed} -> :proceed
      {:error, :already_executed, _result} -> :already_claimed
      {:error, :incomplete_pending} -> :already_claimed
      {:error, reason} -> {:error, {:replay_state_unavailable, reason}}
    end
  catch
    :exit, reason -> {:error, {:replay_state_unavailable, reason}}
  end

  defp complete_execution_claim(flow, result) do
    ReplayLedger.complete(flow.machine.correlation_id, result, flow.ledger)
  catch
    :exit, reason -> {:error, {:replay_state_unavailable, reason}}
  end

  defp json_safe(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp json_safe(value) when is_struct(value), do: value |> Map.from_struct() |> json_safe()

  defp json_safe(value) when is_map(value) do
    Map.new(value, fn {key, item} -> {to_string(key), json_safe(item)} end)
  end

  defp json_safe(value) when is_list(value), do: Enum.map(value, &json_safe/1)
  defp json_safe(value) when is_boolean(value) or is_nil(value), do: value
  defp json_safe(value) when is_atom(value), do: Atom.to_string(value)
  defp json_safe(value), do: value

  defp id, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
end
