defmodule Exocomp.Coordinator.Skills.ClusterHealth do
  @moduledoc """
  Skill handler for `exocomp.cluster.health`.

  Delegates to the configured orchestrator module to fan out health checks to
  cluster nodes and collect correlated partial results.

  Partial results are included for each node: unreachable nodes produce an
  explicit `{"status": "unreachable", "error": "..."}` entry rather than
  failing the whole artifact. This allows callers to see which nodes responded
  and which did not.

  ## Configuration

  - `:cluster_health_orchestrator` (Application config, `:exocomp_coordinator`) —
    module implementing `fan_out_health/1` (default:
    `Exocomp.Coordinator.Orchestrator.Stub`).
  """

  @behaviour Exocomp.Coordinator.Skills.Behaviour

  alias Exocomp.A2A.{Artifact, DataPart}

  @default_orchestrator Exocomp.Coordinator.Orchestrator.Stub

  @impl true
  def execute(params, _context) do
    orchestrator =
      Application.get_env(
        :exocomp_coordinator,
        :cluster_health_orchestrator,
        @default_orchestrator
      )

    node_results = orchestrator.fan_out_health(params)
    build_artifact(node_results)
  end

  defp build_artifact(node_results) do
    data = %{
      "schema_version" => "1",
      "skill" => "exocomp.cluster.health",
      "nodes" => node_results
    }

    artifact = %Artifact{
      artifactId: generate_artifact_id(),
      name: "cluster-health",
      parts: [%DataPart{data: data}]
    }

    {:ok, artifact}
  end

  defp generate_artifact_id do
    "cluster-health-#{System.unique_integer([:positive, :monotonic])}"
  end
end
