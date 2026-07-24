defmodule Exocomp.Coordinator.Handlers.AgentCardHandler do
  @moduledoc """
  Serves the coordinator cluster Agent Card.

  Exposes only diagnostic cluster skills. Remediation execution skills are
  intentionally absent per milestone-2-coordinator.md Non-Goals.
  """

  import Plug.Conn

  alias Exocomp.A2A.AgentCapabilities
  alias Exocomp.A2A.AgentCard
  alias Exocomp.A2A.AgentSkill

  @skills [
    %AgentSkill{
      id: "exocomp.cluster.health",
      name: "Cluster Health",
      description: "Return aggregated health status for all or selected cluster nodes."
    },
    %AgentSkill{
      id: "exocomp.cluster.diagnose",
      name: "Cluster Diagnose",
      description:
        "Collect correlated diagnostic observations from all or selected cluster nodes."
    }
  ]

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, opts) do
    coordinator_id = Keyword.get(opts, :coordinator_id, "localhost")

    card = %AgentCard{
      name: "Exocomp Coordinator Agent",
      description:
        "Diagnostic-only Exocomp coordinator. Aggregates cluster node results. Cannot execute remediation.",
      url: "https://#{coordinator_id}/",
      version: "0.1.0",
      capabilities: %AgentCapabilities{},
      skills: @skills
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(to_json(card)))
  end

  defp to_json(%AgentCard{} = card) do
    %{
      name: card.name,
      description: card.description,
      url: card.url,
      version: card.version,
      capabilities: Map.from_struct(card.capabilities),
      skills: Enum.map(card.skills, &skill_to_json/1)
    }
  end

  defp skill_to_json(%AgentSkill{} = skill) do
    %{id: skill.id, name: skill.name, description: skill.description}
  end
end
