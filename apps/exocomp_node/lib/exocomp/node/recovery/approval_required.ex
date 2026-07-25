# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Recovery.ApprovalRequired do
  @moduledoc """
  Approval-required recovery for an active or degraded systemd service.

  The flow is deliberately data-only: callers persist the returned A2A task
  and recovery state alongside their own task storage. Every accepted recovery
  transition is offered to the configured audit callback before the updated
  flow is returned.

  Approval is delegated to `Exocomp.Node.Safety.ApprovalGate`, so signature,
  task/action/evidence bindings, current preconditions, and replay protection
  are checked by the same fail-closed gate used by other node actions.
  """

  alias Exocomp.A2A.{Artifact, DataPart, Message, Task, TaskStatus}
  alias Exocomp.Core.ApprovalToken
  alias Exocomp.Node.Executor
  alias Exocomp.Node.Safety.ApprovalGate
  alias Exocomp.Recovery.{AuditEvent, Evidence, StateMachine}

  @action_id :restart_service

  @type classification :: :active | :degraded

  @type t :: %__MODULE__{
          task: Task.t(),
          machine: StateMachine.t(),
          evidence: Evidence.t(),
          classification: classification(),
          impact: map(),
          allow_list: [String.t()],
          audit_fun: (AuditEvent.t() -> :ok | {:error, term()}),
          refresh_fun: (String.t(), String.t() -> {:ok, Evidence.t()} | {:error, term()}),
          verify_fun: (String.t(), String.t() -> {:ok, Evidence.t()} | {:error, term()}),
          gate_opts: keyword(),
          executor: module() | function(),
          now_fun: (-> DateTime.t())
        }

  defstruct [
    :task,
    :machine,
    :evidence,
    :classification,
    :impact,
    :allow_list,
    :audit_fun,
    :refresh_fun,
    :verify_fun,
    :gate_opts,
    :executor,
    :now_fun
  ]

  @doc """
  Starts an active/degraded recovery and returns an A2A `input_required` task.

  Required options are `:task_id`, `:allow_list`, and a durable `:audit_fun`.
  Production callers should also provide deterministic read-only
  `:refresh_fun`/`:verify_fun`.
  """
  @spec request(Evidence.t(), keyword()) :: {:ok, t()} | {:error, term()}
  def request(%Evidence{} = evidence, opts) do
    task_id = Keyword.fetch!(opts, :task_id)
    node_id = Keyword.get(opts, :node_id, evidence.node_id)
    service = Keyword.get(opts, :service, evidence.service)
    now_fun = Keyword.get(opts, :now_fun, &DateTime.utc_now/0)
    audit_fun = Keyword.fetch!(opts, :audit_fun)
    now = now_fun.()

    with :ok <- validate_target(evidence, node_id, service),
         {:ok, classification} <- approval_classification(evidence),
         {:ok, machine, audits} <-
           build_machine(task_id, node_id, service, evidence, opts, now),
         :ok <- persist_all(audits, audit_fun) do
      impact = impact(node_id, service, classification)
      task = approval_task(task_id, machine.correlation_id, evidence, impact, now)

      {:ok,
       %__MODULE__{
         task: task,
         machine: machine,
         evidence: evidence,
         classification: classification,
         impact: impact,
         allow_list: Keyword.fetch!(opts, :allow_list),
         audit_fun: audit_fun,
         refresh_fun: Keyword.get(opts, :refresh_fun, &missing_evidence/2),
         verify_fun: Keyword.get(opts, :verify_fun, &missing_evidence/2),
         gate_opts: Keyword.get(opts, :gate_opts, []),
         executor: Keyword.get(opts, :executor, Executor),
         now_fun: now_fun
       }}
    end
  end

  @doc """
  Applies an operator approval.

  `approver` must exactly match the signed token's operator. Invalid tokens and
  wrong approvers leave the task in `input_required`; expiry and any relevant
  evidence change terminally escalate without invoking the executor.
  """
  @spec approve(t(), map(), String.t()) ::
          {:ok, t()} | {:error, term(), t()}
  def approve(%__MODULE__{} = flow, token, approver)
      when is_map(token) and is_binary(approver) do
    with :ok <- ensure_waiting(flow),
         :ok <- match_approver(token, approver),
         {:ok, fresh} <- refresh(flow),
         :ok <- same_preconditions(flow, fresh) do
      execute_approved(flow, token)
    else
      {:error, :approval_not_pending} ->
        {:error, :approval_not_pending, flow}

      {:error, :wrong_approver} ->
        reject_pending(flow, :wrong_approver)

      {:error, {:state_changed, reason}} ->
        escalate(flow, {:precondition_changed, reason})

      {:error, reason} ->
        reject_pending(flow, reason)
    end
  end

  def approve(%__MODULE__{} = flow, _token, approver) when not is_binary(approver),
    do: reject_pending(flow, :wrong_approver)

  def approve(%__MODULE__{} = flow, _token, _approver),
    do: reject_pending(flow, {:invalid_approval, :malformed_token})

  @doc "Records an operator denial and terminally escalates without action."
  @spec deny(t(), String.t()) :: {:ok, t()} | {:error, term(), t()}
  def deny(%__MODULE__{} = flow, reason) when is_binary(reason) do
    escalate(flow, {:denied, reason})
  end

  @doc "Records approval timeout and terminally escalates without action."
  @spec timeout(t()) :: {:ok, t()} | {:error, term(), t()}
  def timeout(%__MODULE__{} = flow), do: escalate(flow, :approval_timeout)

  @doc "Cancels a non-terminal recovery without action."
  @spec cancel(t(), String.t()) :: {:ok, t()} | {:error, term(), t()}
  def cancel(%__MODULE__{} = flow, reason) when is_binary(reason) do
    case transition(flow, {:cancel, reason}) do
      {:ok, flow} -> {:ok, terminal_task(flow, :canceled, :canceled, reason)}
      {:error, error} -> {:error, error, flow}
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

    events = [
      {:unhealthy_observation, evidence},
      {:evidence_complete, evidence},
      :validate,
      {:active_or_degraded, evidence}
    ]

    Enum.reduce_while(events, {:ok, machine, []}, fn event, {:ok, current, audits} ->
      case StateMachine.apply_event(current, event, now: now) do
        {:ok, updated, audit} -> {:cont, {:ok, updated, audits ++ [audit]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp execute_approved(flow, token) do
    now = flow.now_fun.()
    approval = approval_meta(token)

    executor = fn action_id, target, allow_list ->
      case StateMachine.apply_event(flow.machine, {:valid_approval, approval}, now: now) do
        {:ok, executing, audit} ->
          case flow.audit_fun.(audit) do
            :ok ->
              action_result = invoke_executor(flow.executor, action_id, target, allow_list)
              {:ok, %{action_result: action_result, recovery_machine: executing}}

            {:error, reason} ->
              {:error, {:audit_unavailable, reason}}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end

    context = %{
      node_id: flow.machine.node_id,
      task_id: flow.task.id,
      correlation_id: flow.machine.correlation_id,
      action_id: @action_id,
      target: flow.machine.service,
      parameters: parameters(flow.machine.service),
      allow_list: flow.allow_list
    }

    gate_opts = Keyword.put(flow.gate_opts, :executor, executor)

    case ApprovalGate.execute(token, context, gate_opts) do
      {:ok, %{action_result: {:ok, result}, recovery_machine: executing}} ->
        finish_execution(%{flow | machine: executing}, result)

      {:ok, %{action_result: {:error, reason}, recovery_machine: executing}} ->
        execution_failed(%{flow | machine: executing}, reason)

      {:error, {:token_invalid, :expired}} ->
        escalate(flow, :approval_expired)

      {:error, {:precondition_changed, reason}} ->
        escalate(flow, {:precondition_changed_at_execution, reason})

      {:error, {:already_executed, _result}} ->
        reject_pending(flow, :duplicate_approval)

      {:error, :replay_state_unavailable} ->
        reject_pending(flow, :approval_replay_state_unavailable)

      {:error, {:token_invalid, reason}} ->
        reject_pending(flow, {:invalid_approval, reason})

      {:error, {:execution_failed, {:audit_unavailable, reason}}} ->
        {:error, {:execution_failed, {:audit_unavailable, reason}}, flow}

      {:error, {:execution_failed, {:illegal_transition, _, _} = reason}} ->
        {:error, {:execution_failed, reason}, flow}

      {:error, {:execution_failed, reason}} ->
        execution_failed(flow, reason)
    end
  end

  defp finish_execution(flow, result) do
    with {:ok, flow} <- transition(flow, {:execution_complete, result}),
         {:ok, verification} <-
           flow.verify_fun.(flow.machine.node_id, flow.machine.service),
         :ok <- validate_target(verification, flow.machine.node_id, flow.machine.service) do
      case healthy?(verification) do
        true ->
          case transition(flow, {:stable_health, verification}) do
            {:ok, flow} ->
              {:ok, terminal_task(flow, :completed, :recovery_completed, result)}

            {:error, reason} ->
              {:error, reason, flow}
          end

        false ->
          verification_failed(flow, {:unstable_health, verification.data})
      end
    else
      {:error, reason} -> verification_failed(flow, reason)
    end
  end

  defp execution_failed(flow, reason) do
    case StateMachine.apply_event(
           flow.machine,
           {:execution_complete, %{error: reason}},
           now: flow.now_fun.()
         ) do
      {:ok, machine, audit} ->
        case flow.audit_fun.(audit) do
          :ok ->
            verification_failed(%{flow | machine: machine}, {:execution_failed, reason})

          {:error, audit_error} ->
            {:error, {:audit_unavailable, audit_error}, flow}
        end

      {:error, error} ->
        {:error, error, flow}
    end
  end

  defp verification_failed(flow, reason) do
    with {:ok, cooling, audit1} <-
           StateMachine.apply_event(
             flow.machine,
             {:failure_or_instability, inspect(reason)},
             now: flow.now_fun.()
           ),
         :ok <- flow.audit_fun.(audit1),
         {:ok, escalated, audit2} <-
           StateMachine.apply_event(cooling, :cooldown_expired, now: flow.now_fun.()),
         :ok <- flow.audit_fun.(audit2) do
      flow = %{flow | machine: escalated}
      {:ok, terminal_task(flow, :failed, :recovery_escalated, reason)}
    else
      {:error, error} -> {:error, error, flow}
    end
  end

  defp escalate(flow, reason) do
    with :ok <- ensure_waiting(flow),
         {:ok, flow} <-
           transition(flow, {:deny_or_expire_or_changed, inspect(reason)}) do
      {:ok, terminal_task(flow, :failed, :approval_escalated, reason)}
    else
      {:error, error} -> {:error, error, flow}
    end
  end

  defp transition(flow, event) do
    case StateMachine.apply_event(flow.machine, event, now: flow.now_fun.()) do
      {:ok, machine, audit} ->
        case flow.audit_fun.(audit) do
          :ok -> {:ok, %{flow | machine: machine}}
          {:error, reason} -> {:error, {:audit_unavailable, reason}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp reject_pending(flow, reason) do
    message = status_message(flow.task, :approval_rejected, %{reason: reason}, flow.now_fun.())

    task = %{
      flow.task
      | status: %TaskStatus{
          state: :input_required,
          message: message,
          timestamp: message.timestamp
        },
        history: flow.task.history ++ [message],
        updated_at: message.timestamp
    }

    {:error, reason, %{flow | task: task}}
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
        {:error, {:state_changed, {:evidence_refresh_failed, reason}}}

      other ->
        {:error, {:state_changed, {:invalid_refreshed_evidence, other}}}
    end
  end

  defp same_preconditions(flow, fresh) do
    current = relevant_evidence(fresh)
    approved = relevant_evidence(flow.evidence)

    cond do
      current != approved ->
        {:error, {:state_changed, state_change(flow.classification, fresh)}}

      flow.classification == :degraded and healthy?(fresh) ->
        {:error, {:state_changed, :service_became_healthy}}

      failed?(fresh) ->
        {:error, {:state_changed, :service_became_failed}}

      true ->
        :ok
    end
  end

  defp state_change(_original, fresh) when is_struct(fresh, Evidence) do
    cond do
      failed?(fresh) -> :service_became_failed
      healthy?(fresh) -> :service_became_healthy
      true -> :evidence_changed
    end
  end

  defp ensure_waiting(%{machine: %{state: :awaiting_approval}}), do: :ok
  defp ensure_waiting(_flow), do: {:error, :approval_not_pending}

  defp match_approver(token, approver) do
    payload = map_get(token, :payload) || %{}
    if map_get(payload, :operator) == approver, do: :ok, else: {:error, :wrong_approver}
  end

  defp approval_meta(token) do
    payload = map_get(token, :payload) || %{}

    %{
      nonce: map_get(payload, :nonce),
      operator: map_get(payload, :operator),
      expires_at: parse_datetime(map_get(payload, :expires_at))
    }
  end

  defp parse_datetime(%DateTime{} = datetime), do: datetime

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end

  defp parse_datetime(_value), do: nil

  defp approval_classification(evidence) do
    cond do
      failed?(evidence) -> {:error, :failed_service_does_not_use_approval_flow}
      degraded?(evidence) -> {:ok, :degraded}
      active?(evidence) -> {:ok, :active}
      true -> {:error, :service_not_active_or_degraded}
    end
  end

  defp active?(%Evidence{data: data}), do: value(data, :active_state) == "active"

  defp degraded?(%Evidence{data: data}) do
    value(data, :classification) == "degraded" or
      value(data, :health) in ["degraded", "unhealthy"]
  end

  defp healthy?(%Evidence{data: data}) do
    active?(%Evidence{data: data}) and value(data, :health) in [nil, "healthy", "ok"]
  end

  defp failed?(%Evidence{data: data}),
    do: value(data, :active_state) in ["failed", "inactive"]

  defp value(map, key) do
    map_get(map, key)
    |> case do
      atom when is_atom(atom) -> Atom.to_string(atom)
      other -> other
    end
  end

  defp validate_target(%Evidence{node_id: node_id, service: service}, node_id, service),
    do: :ok

  defp validate_target(_evidence, _node_id, _service), do: {:error, :evidence_target_mismatch}

  defp canonical_evidence(%Evidence{data: data}) do
    %{
      "active_state" => value(data, :active_state),
      "sub_state" => value(data, :sub_state),
      "unit_name" => value(data, :unit_name)
    }
  end

  defp relevant_evidence(%Evidence{data: data} = evidence) do
    canonical_evidence(evidence)
    |> Map.merge(%{
      "classification" => value(data, :classification),
      "health" => value(data, :health)
    })
  end

  defp parameters(service), do: %{"service" => service}

  defp impact(node_id, service, classification) do
    %{
      "action" => "restart_service",
      "classification" => Atom.to_string(classification),
      "disruption" => "Restarting will interrupt the live service workload.",
      "node_id" => node_id,
      "service" => service
    }
  end

  defp approval_task(task_id, correlation_id, evidence, impact, now) do
    timestamp = DateTime.to_iso8601(now)

    request = %{
      "approval" => %{
        "action_id" => Atom.to_string(@action_id),
        "correlation_id" => correlation_id,
        "evidence_hash" => ApprovalToken.hash_evidence(canonical_evidence(evidence)),
        "task_id" => task_id
      },
      "evidence" => evidence_json(evidence),
      "impact" => impact
    }

    message = message(task_id, correlation_id, :approval_required, request, timestamp)

    %Task{
      id: task_id,
      contextId: correlation_id,
      status: %TaskStatus{state: :input_required, message: message, timestamp: timestamp},
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
            "outcome" => Atom.to_string(outcome),
            "recovery_state" => Atom.to_string(flow.machine.state)
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

  defp status_message(task, event, data, now) do
    message(task.id, task.contextId, event, data, DateTime.to_iso8601(now))
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

  defp evidence_json(evidence) do
    %{
      "collected_at" => DateTime.to_iso8601(evidence.collected_at),
      "collector_version" => evidence.collector_version,
      "data" => json_safe(evidence.data),
      "evidence_id" => evidence.evidence_id,
      "node_id" => evidence.node_id,
      "service" => evidence.service
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

  defp map_get(map, key) when is_map(map) do
    Map.get(map, key, Map.get(map, Atom.to_string(key)))
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
