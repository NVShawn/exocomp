# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Skills.ClusterRecover do
  @moduledoc """
  Skill handler for `exocomp.cluster.recover`.

  Routes an authenticated failed-service recovery task to the designated
  cluster node via the node A2A surface (`exocomp.service.recover`),
  polls until a terminal state is reached, and returns a cluster-level
  artifact with the node outcome.

  The one-attempt, restricted-executor, and stability-verification invariants
  are enforced by the node's `Exocomp.Node.Skills.ServiceRecover` and
  `Exocomp.Node.Recovery.FailedService` — the coordinator is a thin
  authenticated routing layer.

  ## Required params

      %{
        "node_id"  => "node-1",
        "service"  => "exocomp-fixture.service",
        "evidence" => %{
          "evidence_id"       => "...",
          "collected_at"      => "2026-07-25T14:00:00Z",
          "node_id"           => "node-1",
          "service"           => "exocomp-fixture.service",
          "collector_version" => "1.0",
          "data"              => %{"active_state" => "failed", ...}
        }
      }

  ## Injectable configuration (Application config, `:exocomp_coordinator`)

  - `:cluster_recover_node_client` — module implementing `send/4` and
    `get_task/3` (default: `Exocomp.Coordinator.A2A.DiagnosticClient`).
  - `:cluster_recover_client_opts` — keyword list passed as the `opts`
    argument to every `node_client` call (default: `[]`). In production,
    this should include the `:registry` and `:transport` settings.
  - `:cluster_recover_poll_interval_ms` — milliseconds between status
    polls (default: `500`).
  - `:cluster_recover_timeout_ms` — maximum wait for a terminal result
    (default: `120_000`).
  """

  @behaviour Exocomp.Coordinator.Skills.Behaviour

  alias Exocomp.A2A.{Artifact, DataPart, TaskState}
  alias Exocomp.Coordinator.A2A.DiagnosticClient

  @default_node_client DiagnosticClient
  @default_poll_interval_ms 500
  @default_timeout_ms 120_000

  @impl true
  def execute(
        %{"node_id" => node_id, "service" => service, "evidence" => evidence} = params,
        context
      )
      when is_binary(node_id) and is_binary(service) and is_map(evidence) do
    node_client =
      Application.get_env(
        :exocomp_coordinator,
        :cluster_recover_node_client,
        @default_node_client
      )

    client_opts =
      Application.get_env(:exocomp_coordinator, :cluster_recover_client_opts, [])

    poll_interval_ms =
      Application.get_env(
        :exocomp_coordinator,
        :cluster_recover_poll_interval_ms,
        @default_poll_interval_ms
      )

    timeout_ms =
      Application.get_env(:exocomp_coordinator, :cluster_recover_timeout_ms, @default_timeout_ms)

    # Only diagnostic evidence and the exact target cross the node boundary.
    # Authorization inputs such as the node's service allow-list are always
    # resolved from trusted node configuration.
    node_params = Map.take(params, ["service", "node_id", "evidence"])
    client_opts = put_context_id(client_opts, context)

    with {:ok, task} <-
           node_client.send(node_id, "exocomp.service.recover", node_params, client_opts),
         {:ok, terminal_task} <-
           wait_for_terminal(
             node_id,
             task,
             node_client,
             client_opts,
             poll_interval_ms,
             timeout_ms
           ) do
      build_artifact(node_id, terminal_task)
    else
      {:error, error} ->
        {:error, {:node_recovery_failed, node_id, error}}
    end
  end

  def execute(_params, _context), do: {:error, :invalid_params}

  defp put_context_id(client_opts, context) do
    case context_value(context, :correlation_id) || context_value(context, :task_id) do
      value when is_binary(value) and value != "" -> Keyword.put(client_opts, :context_id, value)
      _other -> client_opts
    end
  end

  defp context_value(context, key) when is_map(context) do
    Map.get(context, key) || Map.get(context, Atom.to_string(key))
  end

  defp context_value(_context, _key), do: nil

  # ---------------------------------------------------------------------------
  # Polling
  # ---------------------------------------------------------------------------

  defp wait_for_terminal(node_id, task, node_client, client_opts, poll_interval_ms, timeout_ms) do
    if TaskState.terminal?(task.status.state) do
      {:ok, task}
    else
      deadline = System.monotonic_time(:millisecond) + timeout_ms
      poll_loop(node_id, task.id, node_client, client_opts, poll_interval_ms, deadline)
    end
  end

  defp poll_loop(node_id, task_id, node_client, client_opts, poll_interval_ms, deadline) do
    if System.monotonic_time(:millisecond) >= deadline do
      {:error, :recovery_timeout}
    else
      Process.sleep(poll_interval_ms)

      case node_client.get_task(node_id, task_id, client_opts) do
        {:ok, updated_task} ->
          if TaskState.terminal?(updated_task.status.state) do
            {:ok, updated_task}
          else
            poll_loop(node_id, task_id, node_client, client_opts, poll_interval_ms, deadline)
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Artifact construction
  # ---------------------------------------------------------------------------

  defp build_artifact(node_id, task) do
    node_result = %{
      "task_id" => task.id,
      "status" => Atom.to_string(task.status.state),
      "artifact_count" => length(task.artifacts),
      "artifacts" => Enum.map(task.artifacts, &encode_artifact/1),
      "history_length" => length(task.history)
    }

    data = %{
      "schema_version" => "1",
      "skill" => "exocomp.cluster.recover",
      "node_id" => node_id,
      "node_result" => node_result
    }

    artifact = %Artifact{
      artifactId: new_id(),
      name: "cluster-recover",
      parts: [%DataPart{data: data}]
    }

    {:ok, artifact}
  end

  defp encode_artifact(artifact) do
    %{
      "artifactId" => artifact.artifactId,
      "name" => artifact.name,
      "parts" => Enum.map(artifact.parts, &encode_part/1)
    }
  end

  defp encode_part(%DataPart{data: data}), do: %{"type" => "data", "data" => data}
  defp encode_part(other), do: inspect(other)

  defp new_id, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
end
