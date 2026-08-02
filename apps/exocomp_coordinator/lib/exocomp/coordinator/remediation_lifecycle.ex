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
  alias Exocomp.Coordinator.Safety.ApprovalSigner
  alias Exocomp.Core.ApprovalToken

  @skill_id "remediation.execute"
  @terminal_states [:completed, :failed, :canceled]
  @default_approval_timeout_ms 60_000
  @default_model_output_bytes 4_096
  @default_approval_token_ttl_ms 300_000
  @approval_command_fields ~w(
    action_id
    correlation_id
    decision
    denial_reason
    evidence_hash
    node_id
    operator
    parameters
    proposal_id
    target_id
    task_id
  )

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

  @doc "Handles an authenticated, typed proposal.approve command payload."
  @spec approve_command(map(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def approve_command(payload, context \\ %{}, opts \\ [])

  def approve_command(payload, context, opts) when is_map(payload) and is_map(context) do
    GenServer.call(
      Keyword.get(opts, :server, __MODULE__),
      {:approve_command, payload, context}
    )
  end

  def approve_command(_payload, _context, _opts), do: {:error, :invalid_approval_command}

  @doc "Handles an authenticated, typed proposal.deny command payload."
  @spec deny_command(map(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def deny_command(payload, context \\ %{}, opts \\ [])

  def deny_command(payload, context, opts) when is_map(payload) and is_map(context) do
    GenServer.call(
      Keyword.get(opts, :server, __MODULE__),
      {:deny_command, payload, context}
    )
  end

  def deny_command(_payload, _context, _opts), do: {:error, :invalid_approval_command}

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

    {:ok,
     %{
       tasks: %{},
       adapter: Keyword.get(opts, :adapter, FailClosed),
       audit: audit,
       signer: Keyword.get(opts, :signer, ApprovalSigner),
       signer_opts: Keyword.get(opts, :signer_opts, []),
       now_fn: Keyword.get(opts, :now_fn, &DateTime.utc_now/0),
       approval_timeout_ms: Keyword.get(opts, :approval_timeout_ms, @default_approval_timeout_ms),
       approval_token_ttl_ms:
         Keyword.get(opts, :approval_token_ttl_ms, @default_approval_token_ttl_ms),
       model_output_bytes: Keyword.get(opts, :model_output_bytes, @default_model_output_bytes),
       redactor: Keyword.get(opts, :redactor, &Audit.redact/1)
     }}
  end

  @impl true
  def handle_call({:submit, proposal}, _from, state) do
    task_id =
      case map_get(proposal, :task_id) do
        value when is_binary(value) and byte_size(value) > 0 ->
          if Map.has_key?(state.tasks, value), do: uuid(), else: value

        _other ->
          uuid()
      end

    correlation_id =
      case map_get(proposal, :correlation_id) do
        value when is_binary(value) and byte_size(value) > 0 -> value
        _other -> Audit.correlation_id()
      end

    recorded_proposal = sanitize(proposal, state)
    task = new_task(task_id, correlation_id, recorded_proposal)

    state =
      put_entry(state, task_id, %{
        task: task,
        proposal: proposal,
        source_proposal: proposal,
        proposal_id: map_get(proposal, :proposal_id),
        evidence: nil,
        action: nil,
        policy: nil,
        approval_command_id: nil
      })

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

  def handle_call({:approve_command, payload, context}, _from, state) do
    case handle_typed_approval(payload, context, state) do
      {:ok, result, state} -> {:reply, {:ok, result}, state}
      {:error, reason, state} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:deny_command, payload, context}, _from, state) do
    case handle_typed_denial(payload, context, state) do
      {:ok, result, state} -> {:reply, {:ok, result}, state}
      {:error, reason, state} -> {:reply, {:error, reason}, state}
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

    with {:ok, proposal} <- invoke(state.adapter, :validate_proposal, [raw]),
         :ok <- stage_audit(state, task_id, :proposal_validated, %{proposal: proposal}),
         {:ok, evidence} <- invoke(state.adapter, :collect_evidence, [proposal]),
         :ok <- stage_audit(state, task_id, :evidence_collected, %{evidence: evidence}),
         decision <- invoke(state.adapter, :decide, [proposal, evidence]) do
      state =
        update_entry(state, task_id, fn entry ->
          Map.merge(entry, %{proposal: proposal, evidence: evidence, policy: decision})
        end)

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
        state = update_entry(state, task_id, &Map.put(&1, :action, action))
        {task, state} = execute(task_id, nil, state)
        {{:ok, task}, state}

      {:error, reason} ->
        {task, state} = terminal(state, task_id, :failed, :audit_unavailable, reason)
        {{:ok, task}, state}
    end
  end

  defp apply_decision(task_id, {:approval_required, action, request}, state) do
    with :ok <-
           stage_audit(state, task_id, :policy_decided, %{
             decision: :approval_required,
             action: action
           }),
         :ok <- stage_audit(state, task_id, :approval_requested, %{request: request}) do
      timer = Process.send_after(self(), {:approval_timeout, task_id}, state.approval_timeout_ms)

      state =
        state
        |> update_entry(
          task_id,
          &Map.merge(&1, %{action: action, policy: {:approval_required, action}})
        )
        |> update_entry(task_id, &Map.put(&1, :timer, timer))
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

  # ---------------------------------------------------------------------------
  # Typed Mission Control approval commands
  # ---------------------------------------------------------------------------

  defp handle_typed_approval(payload, context, state) do
    with {:ok, command} <-
           parse_approval_command(payload, context, "approved", "proposal.approve"),
         :ok <- command_time_valid(command, state) do
      {:ok, entry, prepared_state} = prepare_entry(command, state)
      continue_typed_approval(payload, command, entry, prepared_state)
    else
      {:error, reason} ->
        typed_rejection(payload, reason, state)
    end
  end

  defp continue_typed_approval(payload, command, entry, state) do
    with :ok <- ensure_waiting(entry),
         :ok <- verify_entry_bindings(entry, command),
         :ok <-
           audit(state, :approval_command_received, entry.task, %{command_id: command.command_id}),
         {:ok, validated_proposal} <- validate_again(state.adapter, entry),
         {:ok, fresh_evidence} <- recollect(state.adapter, validated_proposal),
         {:ok, evidence_hash} <-
           verify_evidence(entry.evidence, fresh_evidence, command.evidence_hash),
         {:ok, fresh_action} <- rerun_policy(state.adapter, validated_proposal, fresh_evidence),
         :ok <- verify_action(entry.action, fresh_action, command),
         :ok <- audit(state, :approval_revalidated, entry.task, %{evidence_hash: evidence_hash}),
         {:ok, token_payload} <- token_payload(command, evidence_hash, state),
         {:ok, token} <- sign_token(state, token_payload) do
      cancel_timer(entry)

      state =
        state
        |> update_entry(command.task_id, fn current ->
          Map.merge(current, %{
            evidence: fresh_evidence,
            proposal: validated_proposal,
            action: fresh_action,
            policy: {:approval_required, fresh_action},
            approval_command_id: command.command_id,
            timer: nil
          })
        end)
        |> transition(command.task_id, :working, :approval_granted, %{
          command_id: command.command_id
        })

      {task, state} = execute(command.task_id, token, state)
      result = typed_result(task)

      if task.status.state == :completed do
        {:ok, result, state}
      else
        {:error, {:typed_approval_failed, result}, state}
      end
    else
      {:error, reason} ->
        typed_rejection(payload, reason, state)
    end
  end

  defp handle_typed_denial(payload, context, state) do
    with {:ok, command} <- parse_approval_command(payload, context, "denied", "proposal.deny"),
         :ok <- command_time_valid(command, state),
         {:ok, entry, state} <- existing_entry(command.task_id, state),
         :ok <- ensure_waiting(entry),
         :ok <- verify_entry_bindings(entry, command),
         :ok <-
           audit(state, :approval_denied, entry.task, %{
             command_id: command.command_id,
             operator: command.operator
           }) do
      cancel_timer(entry)

      {task, state} =
        terminal(state, command.task_id, :completed, :approval_denied, command.denial_reason)

      {:ok, typed_result(task), state}
    else
      {:error, reason} -> typed_rejection(payload, reason, state)
    end
  end

  defp parse_approval_command(payload, context, expected_decision, expected_kind) do
    keys = payload |> Map.keys() |> Enum.map(&to_string/1) |> MapSet.new()
    allowed = MapSet.new(@approval_command_fields)

    with true <- MapSet.equal?(keys, allowed),
         {:ok, proposal_id} <- required_string(payload, :proposal_id),
         {:ok, task_id} <- required_string(payload, :task_id),
         {:ok, correlation_id} <- required_string(payload, :correlation_id),
         {:ok, node_id} <- required_string(payload, :node_id),
         {:ok, target_id} <- required_string(payload, :target_id),
         {:ok, action_id} <- required_action_id(payload),
         {:ok, parameters} <- required_parameters(payload),
         {:ok, evidence_hash} <- required_hash(payload, :evidence_hash),
         {:ok, operator} <- required_operator(payload),
         {:ok, decision} <- required_string(payload, :decision),
         true <- decision == expected_decision,
         {:ok, denial_reason} <- denial_reason(payload, expected_decision),
         {:ok, kind} <- required_string(context, :kind),
         true <- kind == expected_kind,
         {:ok, command_id} <- command_id(context),
         {:ok, command_issued_at} <- command_issued_at(context),
         {:ok, command_expiry} <- command_expiry(context) do
      {:ok,
       %{
         command_id: command_id,
         proposal_id: proposal_id,
         task_id: task_id,
         correlation_id: correlation_id,
         node_id: node_id,
         target_id: target_id,
         action_id: action_id,
         parameters: parameters,
         evidence_hash: evidence_hash,
         operator: operator,
         decision: decision,
         denial_reason: denial_reason,
         issued_at: command_issued_at,
         command_expiry: command_expiry
       }}
    else
      false -> {:error, :invalid_approval_command_fields}
      {:error, _reason} = error -> error
      _other -> {:error, :invalid_approval_command}
    end
  end

  defp command_time_valid(command, state) do
    now = state.now_fn.()

    cond do
      DateTime.compare(command.issued_at, now) == :gt ->
        {:error, :approval_not_yet_valid}

      DateTime.compare(command.command_expiry, now) != :gt ->
        {:error, :approval_expired}

      true ->
        :ok
    end
  end

  defp prepare_entry(command, state) do
    case Map.fetch(state.tasks, command.task_id) do
      {:ok, entry} ->
        {:ok, entry, state}

      :error ->
        proposal = %{
          "schema_version" => "1",
          "proposal_id" => command.proposal_id,
          "action_id" => command.action_id,
          "target_id" => command.target_id,
          "node_id" => command.node_id,
          "parameters" => command.parameters,
          "evidence_refs" => [],
          "rationale" => "typed operator approval"
        }

        task = new_task(command.task_id, command.correlation_id, proposal)

        state =
          put_entry(state, command.task_id, %{
            task: task,
            proposal: proposal,
            source_proposal: proposal,
            proposal_id: command.proposal_id,
            evidence: nil,
            action: nil,
            policy: nil,
            approval_command_id: nil,
            timer: nil
          })
          |> transition(command.task_id, :input_required, :approval_rehydrated, %{})

        {:ok, Map.fetch!(state.tasks, command.task_id), state}
    end
  end

  defp existing_entry(task_id, state) do
    case Map.fetch(state.tasks, task_id) do
      {:ok, entry} -> {:ok, entry, state}
      :error -> {:error, :not_found}
    end
  end

  defp ensure_waiting(%{task: %{status: %{state: :input_required}}}), do: :ok
  defp ensure_waiting(_entry), do: {:error, :approval_not_pending}

  defp verify_entry_bindings(entry, command) do
    proposal = entry.source_proposal || entry.proposal || %{}
    expected_proposal_id = entry.proposal_id || map_get(proposal, :proposal_id)
    expected_node_id = map_get(proposal, :node_id) || action_value(entry.action, :node_id)

    expected_target =
      action_value(entry.action, :target) || action_value(entry.action, :target_id) ||
        map_get(proposal, :target_id)

    expected_action_id =
      action_value(entry.action, :id) || action_value(entry.action, :action_id) ||
        map_get(proposal, :action_id)

    expected_parameters = map_get(proposal, :parameters) || %{}

    cond do
      not is_binary(expected_proposal_id) or expected_proposal_id != command.proposal_id ->
        {:error, :proposal_mismatch}

      not is_binary(expected_node_id) or expected_node_id != command.node_id ->
        {:error, :target_mismatch}

      not is_binary(expected_target) or expected_target != command.target_id ->
        {:error, :target_mismatch}

      not is_binary(expected_action_id) or expected_action_id != command.action_id ->
        {:error, :action_mismatch}

      hash_value(expected_parameters) != hash_value(command.parameters) ->
        {:error, :parameter_mismatch}

      entry.task.contextId != command.correlation_id ->
        {:error, :correlation_mismatch}

      true ->
        :ok
    end
  end

  defp validate_again(adapter, %{source_proposal: source_proposal}) do
    case invoke(adapter, :validate_proposal, [source_proposal]) do
      {:ok, proposal} when is_map(proposal) -> {:ok, proposal}
      {:ok, _other} -> {:error, :invalid_validated_proposal}
      {:error, reason} -> {:error, {:proposal_changed, reason}}
    end
  end

  defp validate_again(_adapter, %{proposal: proposal}) when is_map(proposal), do: {:ok, proposal}
  defp validate_again(_adapter, _entry), do: {:error, :invalid_proposal}

  defp recollect(adapter, proposal) do
    case invoke(adapter, :collect_evidence, [proposal]) do
      {:ok, evidence} when is_map(evidence) -> {:ok, evidence}
      {:ok, _other} -> {:error, :invalid_recollected_evidence}
      {:error, reason} -> {:error, {:evidence_collection_failed, reason}}
    end
  end

  defp verify_evidence(original, fresh, command_hash) do
    fresh_hash = hash_value(fresh)

    cond do
      is_map(original) and hash_value(original) != fresh_hash -> {:error, :stale_evidence}
      fresh_hash != command_hash -> {:error, :evidence_mismatch}
      true -> {:ok, fresh_hash}
    end
  end

  defp rerun_policy(adapter, proposal, evidence) do
    case invoke(adapter, :decide, [proposal, evidence]) do
      {:approval_required, action, _request} when is_map(action) -> {:ok, action}
      {:deny, _reason} -> {:error, :policy_changed}
      {:allow, _action} -> {:error, :policy_changed}
      {:error, _reason} -> {:error, :policy_changed}
      _other -> {:error, :policy_changed}
    end
  end

  defp verify_action(original_action, fresh_action, command) do
    expected_action_id =
      action_value(fresh_action, :id) || action_value(fresh_action, :action_id)

    expected_target =
      action_value(fresh_action, :target) || action_value(fresh_action, :target_id)

    expected_parameters = action_value(fresh_action, :parameters) || command.parameters

    cond do
      is_map(original_action) and hash_value(original_action) != hash_value(fresh_action) ->
        {:error, :policy_changed}

      hash_value(expected_parameters) != hash_value(command.parameters) ->
        {:error, :parameter_mismatch}

      expected_action_id != command.action_id ->
        {:error, :action_mismatch}

      expected_target != command.target_id ->
        {:error, :target_mismatch}

      true ->
        :ok
    end
  end

  defp token_payload(command, evidence_hash, state) do
    now = state.now_fn.()
    configured_expiry = DateTime.add(now, state.approval_token_ttl_ms, :millisecond)
    expiry = min_datetime(configured_expiry, command.command_expiry)

    if DateTime.compare(expiry, now) != :gt do
      {:error, :approval_expired}
    else
      action_id = command.action_id

      {:ok,
       %{
         "schema_version" => "1",
         "nonce" => Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false),
         "task_id" => command.task_id,
         "correlation_id" => command.correlation_id,
         "node_id" => command.node_id,
         "action_id" => action_id,
         "parameter_hash" => ApprovalToken.hash_params(command.parameters),
         "evidence_hash" => evidence_hash,
         "issued_at" => DateTime.to_iso8601(now),
         "expires_at" => DateTime.to_iso8601(expiry),
         "operator" => command.operator
       }}
    end
  end

  defp sign_token(state, payload) do
    case state.signer do
      module when is_atom(module) -> module.sign(payload, state.signer_opts)
      function when is_function(function, 2) -> function.(payload, state.signer_opts)
      function when is_function(function, 1) -> function.(payload)
      _other -> {:error, :invalid_approval_signer}
    end
  rescue
    _error -> {:error, :approval_signing_failed}
  catch
    _kind, _reason -> {:error, :approval_signing_failed}
  end

  defp typed_rejection(payload, reason, state) do
    task_id = map_get(payload, :task_id)

    case is_binary(task_id) and Map.fetch(state.tasks, task_id) do
      {:ok, %{task: %{status: %{state: :input_required}}}} ->
        {task, state} = terminal(state, task_id, :failed, rejection_event(reason), reason)
        {:error, {:approval_rejected, reason, typed_result(task)}, state}

      _other ->
        {:error, reason, state}
    end
  end

  defp rejection_event(:stale_evidence), do: :stale_evidence
  defp rejection_event(:evidence_mismatch), do: :evidence_mismatch
  defp rejection_event(:policy_changed), do: :policy_changed
  defp rejection_event(:target_mismatch), do: :target_mismatch
  defp rejection_event(:parameter_mismatch), do: :parameter_mismatch
  defp rejection_event(:action_mismatch), do: :action_mismatch
  defp rejection_event(:approval_expired), do: :approval_expired
  defp rejection_event(_reason), do: :approval_rejected

  defp typed_result(task) do
    %{
      "schema_version" => "1",
      "task_id" => task.id,
      "correlation_id" => task.contextId,
      "status" => to_string(task.status.state),
      "history" => Enum.map(task.history, &history_event/1),
      "artifacts" => Enum.map(task.artifacts, &artifact_map/1)
    }
  end

  defp history_event(%Message{parts: [%DataPart{data: %{"event" => event}}]}) do
    %{"event" => event}
  end

  defp history_event(_message), do: %{}

  defp artifact_map(%Artifact{} = artifact) do
    %{
      "artifact_id" => artifact.artifactId,
      "name" => artifact.name,
      "metadata" => artifact.metadata,
      "parts" => Enum.map(artifact.parts, &artifact_part/1)
    }
  end

  defp artifact_part(%DataPart{data: data}), do: %{"type" => "data", "data" => Audit.redact(data)}
  defp artifact_part(other), do: %{"type" => "opaque", "value" => inspect(other)}

  defp required_string(map, key) do
    case map_get(map, key) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _other -> {:error, {:invalid_field, key}}
    end
  end

  defp required_action_id(map) do
    with {:ok, action_id} <- required_string(map, :action_id),
         true <- Regex.match?(~r/\A[A-Za-z0-9._-]{1,128}\z/, action_id) do
      {:ok, action_id}
    else
      _other -> {:error, :invalid_action_id}
    end
  end

  defp required_parameters(map) do
    case map_get(map, :parameters) do
      parameters when is_map(parameters) ->
        if Enum.all?(parameters, fn {key, value} -> is_binary(key) and is_binary(value) end) do
          {:ok, parameters}
        else
          {:error, :invalid_parameters}
        end

      _other ->
        {:error, :invalid_parameters}
    end
  end

  defp required_hash(map, key) do
    with {:ok, value} <- required_string(map, key),
         true <- Regex.match?(~r/\A[0-9a-f]{64}\z/, value) do
      {:ok, value}
    else
      _other -> {:error, {:invalid_field, key}}
    end
  end

  defp required_operator(map) do
    case map_get(map, :operator) do
      value when is_binary(value) and byte_size(value) > 0 ->
        {:ok, value}

      value when is_map(value) ->
        case map_get(value, :sub) do
          sub when is_binary(sub) and byte_size(sub) > 0 -> {:ok, sub}
          _other -> {:error, :invalid_operator}
        end

      _other ->
        {:error, :invalid_operator}
    end
  end

  defp denial_reason(map, "approved") do
    case map_get(map, :denial_reason) do
      nil -> {:ok, nil}
      value when is_binary(value) and byte_size(value) == 0 -> {:ok, nil}
      _value -> {:error, :invalid_denial_reason}
    end
  end

  defp denial_reason(map, "denied") do
    case map_get(map, :denial_reason) do
      value when is_binary(value) and byte_size(value) > 0 ->
        if String.trim(value) == "", do: {:error, :invalid_denial_reason}, else: {:ok, value}

      _other ->
        {:error, :invalid_denial_reason}
    end
  end

  defp command_id(context) do
    case map_get(context, :command_id) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _other -> {:error, :missing_command_id}
    end
  end

  defp command_issued_at(context) do
    case map_get(context, :issued_at) do
      %DateTime{} = value ->
        {:ok, value}

      value when is_binary(value) ->
        case DateTime.from_iso8601(value) do
          {:ok, datetime, _offset} -> {:ok, datetime}
          _other -> {:error, :invalid_command_issued_at}
        end

      _other ->
        {:error, :missing_command_issued_at}
    end
  end

  defp command_expiry(context) do
    case map_get(context, :expires_at) do
      %DateTime{} = value ->
        {:ok, value}

      value when is_binary(value) ->
        case DateTime.from_iso8601(value) do
          {:ok, datetime, _offset} -> {:ok, datetime}
          _other -> {:error, :invalid_command_expiry}
        end

      _other ->
        {:error, :missing_command_expiry}
    end
  end

  defp action_value(action, key) when is_map(action), do: map_get(action, key)
  defp action_value(_action, _key), do: nil

  defp hash_value(value) when is_map(value) do
    value
    |> hashable_value()
    |> ApprovalToken.hash_params()
  end

  defp hash_value(value), do: ApprovalToken.hash_params(%{"value" => hashable_value(value)})

  defp hashable_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp hashable_value(%_{} = struct), do: struct |> Map.from_struct() |> hashable_value()

  defp hashable_value(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), hashable_value(value)} end)
  end

  defp hashable_value(list) when is_list(list), do: Enum.map(list, &hashable_value/1)
  defp hashable_value(value) when is_atom(value), do: to_string(value)
  defp hashable_value(value), do: value

  defp map_get(map, key) when is_map(map) and is_atom(key) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, Atom.to_string(key))
    end
  end

  defp map_get(_map, _key), do: nil

  defp min_datetime(left, right) do
    if DateTime.compare(left, right) == :lt, do: left, else: right
  end

  defp execute(task_id, approval, state) do
    entry = Map.fetch!(state.tasks, task_id)

    case audit(state, :remediation_intent_accepted, entry.task, %{
           action: entry.action,
           evidence: entry.evidence,
           approved: not is_nil(approval)
         }) do
      :ok ->
        case audit(state, :action_started, entry.task, %{action: entry.action}) do
          :ok ->
            state = transition(state, task_id, :working, :execution_started, %{})

            case invoke(state.adapter, :execute, [entry.action, entry.evidence, approval]) do
              {:ok, result} ->
                post_execute(task_id, result, state)

              {:error, reason} ->
                _ = stage_audit(state, task_id, :execution_failed, %{reason: reason})
                _ = audit(state, :action_failed, entry.task, %{reason: reason})
                terminal(state, task_id, :failed, :execution_failed, reason)
            end

          {:error, reason} ->
            terminal(state, task_id, :failed, :audit_unavailable_before_action, reason)
        end

      {:error, reason} ->
        terminal(state, task_id, :failed, :audit_unavailable_before_action, reason)
    end
  end

  defp post_execute(task_id, result, state) do
    entry = Map.fetch!(state.tasks, task_id)

    execution_audit =
      with :ok <- audit(state, :execution_finished, entry.task, %{result: result}),
           :ok <- audit(state, :action_completed, entry.task, %{result: result}) do
        :ok
      end

    state =
      if execution_audit == :ok do
        transition(state, task_id, :working, :execution_completed, %{result: result})
      else
        state
      end

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

    {task, state}
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
