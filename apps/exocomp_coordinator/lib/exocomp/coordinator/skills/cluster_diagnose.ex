defmodule Exocomp.Coordinator.Skills.ClusterDiagnose do
  @moduledoc """
  Skill handler for `exocomp.cluster.diagnose`.

  Delegates to the configured orchestrator module to fan out diagnostic tasks
  to cluster nodes and collect correlated partial results. Each node result is
  included individually with its node ID and status, so callers receive
  a comprehensive view even when some nodes are unreachable.

  ## Configuration

  - `:cluster_diagnose_orchestrator` (Application config, `:exocomp_coordinator`) —
    module implementing `fan_out_diagnose/1` (default:
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
        :cluster_diagnose_orchestrator,
        @default_orchestrator
      )

    node_results = orchestrator.fan_out_diagnose(params)
    build_artifact(node_results)
  end

  defp build_artifact(node_results) do
    data = %{
      "schema_version" => "1",
      "skill" => "exocomp.cluster.diagnose",
      "nodes" => node_results
    }

    artifact = %Artifact{
      artifactId: generate_artifact_id(),
      name: "cluster-diagnose",
      parts: [%DataPart{data: data}]
    }

    {:ok, artifact}
  end

  defp generate_artifact_id do
    "cluster-diagnose-#{System.unique_integer([:positive, :monotonic])}"
  end
end
