# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Skills.ServiceRecover do
  @moduledoc """
  Skill handler for `exocomp.service.recover`.

  Accepts a failed-service evidence payload, wires audit/refresh/verify
  callbacks from application configuration, and delegates to
  `Exocomp.Node.Recovery.FailedService.recover/2`.  Returns an A2A artifact
  containing the recovery outcome, final machine state, and the inner
  recovery-task artifact.

  The one-attempt, restricted-executor, stability-verification, and replay
  ledger invariants are enforced by `FailedService` and are not relaxed by
  this skill handler.

  ## Required params

      %{
        "service"  => "exocomp-fixture.service",
        "node_id"  => "node-1",
        "evidence" => %{
          "evidence_id"       => "...",
          "collected_at"      => "2026-07-25T14:00:00Z",
          "node_id"           => "node-1",
          "service"           => "exocomp-fixture.service",
          "collector_version" => "1.0",
          "data"              => %{"active_state" => "failed", ...}
        }
      }

  ## Optional params

  - `"allow_list"` — list of allowed service names; falls back to the
    `:allowed_services` application config for `:exocomp_node`.
  - `"task_id"` — idempotency key for the recovery episode (generated if absent).

  ## Injectable configuration (Application config, `:exocomp_node`)

  - `:service_recover_audit_fun`   — `fn AuditEvent.t() -> :ok | {:error, term()} end`
  - `:service_recover_refresh_fun` — `fn node_id, service -> {:ok, Evidence.t()} | {:error, term()} end`
  - `:service_recover_verify_fun`  — `fn node_id, service -> {:ok, Evidence.t()} | {:error, term()} end`
  - `:service_recover_executor`    — module or 3-arity function (default: `Exocomp.Node.Executor`)
  - `:service_recover_ledger`      — `ReplayLedger` server name (default: `Exocomp.Node.Safety.ReplayLedger`)
  """

  @behaviour Exocomp.Node.Skills.Behaviour

  alias Exocomp.A2A.{Artifact, DataPart}
  alias Exocomp.Node.Recovery.FailedService
  alias Exocomp.Recovery.Evidence

  @impl true
  def execute(
        %{"service" => service, "node_id" => node_id, "evidence" => evidence_map} = params,
        _context
      )
      when is_binary(service) and is_binary(node_id) and is_map(evidence_map) do
    with {:ok, evidence} <- decode_evidence(evidence_map) do
      task_id = Map.get(params, "task_id") || new_id()

      allow_list =
        Map.get(params, "allow_list") ||
          Application.get_env(:exocomp_node, :allowed_services, [])

      opts = build_opts(task_id, node_id, allow_list)

      case FailedService.recover(evidence, opts) do
        {:ok, flow} ->
          build_artifact(flow)

        {:error, reason} ->
          {:error, {:recovery_failed, reason}}

        {:error, reason, _flow} ->
          {:error, {:recovery_failed, reason}}
      end
    end
  end

  def execute(_params, _context), do: {:error, :invalid_params}

  # ---------------------------------------------------------------------------
  # Evidence decoding
  # ---------------------------------------------------------------------------

  defp decode_evidence(map) when is_map(map) do
    with {:ok, evidence_id} <- required_string(map, "evidence_id"),
         {:ok, collected_at_str} <- required_string(map, "collected_at"),
         {:ok, collected_at} <- parse_datetime(collected_at_str),
         {:ok, ev_node_id} <- required_string(map, "node_id"),
         {:ok, service} <- required_string(map, "service"),
         {:ok, data} <- required_map(map, "data") do
      {:ok,
       Evidence.new(ev_node_id, service, data,
         evidence_id: evidence_id,
         collected_at: collected_at,
         collector_version: Map.get(map, "collector_version", "1.0")
       )}
    end
  end

  defp decode_evidence(_), do: {:error, :invalid_evidence}

  defp required_string(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      nil -> {:error, {:missing_evidence_field, key}}
      _ -> {:error, {:invalid_evidence_field, key}}
    end
  end

  defp required_map(map, key) do
    case Map.get(map, key) do
      value when is_map(value) -> {:ok, value}
      nil -> {:error, {:missing_evidence_field, key}}
      _ -> {:error, {:invalid_evidence_field, key}}
    end
  end

  defp parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> {:ok, dt}
      {:error, reason} -> {:error, {:invalid_evidence_datetime, reason}}
    end
  end

  # ---------------------------------------------------------------------------
  # Options assembly
  # ---------------------------------------------------------------------------

  defp build_opts(task_id, node_id, allow_list) do
    audit_fun =
      Application.get_env(:exocomp_node, :service_recover_audit_fun, &noop_audit/1)

    refresh_fun =
      Application.get_env(:exocomp_node, :service_recover_refresh_fun, &missing_evidence/2)

    verify_fun =
      Application.get_env(:exocomp_node, :service_recover_verify_fun, &missing_evidence/2)

    executor =
      Application.get_env(:exocomp_node, :service_recover_executor, Exocomp.Node.Executor)

    ledger =
      Application.get_env(
        :exocomp_node,
        :service_recover_ledger,
        Exocomp.Node.Safety.ReplayLedger
      )

    [
      task_id: task_id,
      node_id: node_id,
      allow_list: allow_list,
      audit_fun: audit_fun,
      refresh_fun: refresh_fun,
      verify_fun: verify_fun,
      executor: executor,
      ledger: ledger
    ]
  end

  defp noop_audit(_event), do: :ok

  defp missing_evidence(_node_id, _service),
    do: {:error, :evidence_collector_not_configured}

  # ---------------------------------------------------------------------------
  # Artifact construction
  # ---------------------------------------------------------------------------

  defp build_artifact(flow) do
    data = %{
      "schema_version" => "1",
      "skill" => "exocomp.service.recover",
      "outcome" => Atom.to_string(flow.machine.state),
      "service" => flow.machine.service,
      "execution_attempted" => flow.machine.execution_attempted,
      "inner_artifacts" => Enum.map(flow.task.artifacts, &encode_task_artifact/1),
      "history_length" => length(flow.task.history)
    }

    artifact = %Artifact{
      artifactId: new_id(),
      name: "service-recover",
      parts: [%DataPart{data: data}]
    }

    {:ok, artifact}
  end

  defp encode_task_artifact(task_artifact) do
    %{
      "artifactId" => task_artifact.artifactId,
      "name" => task_artifact.name,
      "parts" => Enum.map(task_artifact.parts, &encode_part/1)
    }
  end

  defp encode_part(%DataPart{data: data}), do: %{"type" => "data", "data" => data}
  defp encode_part(other), do: inspect(other)

  defp new_id, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
end
