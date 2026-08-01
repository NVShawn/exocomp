# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Handlers.AgentCardHandler do
  @moduledoc """
  Serves the coordinator cluster Agent Card.

  Exposes diagnostic cluster skills and the authenticated cluster recovery
  skill. Arbitrary remediation execution skills are intentionally absent.
  """

  import Plug.Conn

  alias Exocomp.A2A.AgentCapabilities
  alias Exocomp.A2A.AgentCard
  alias Exocomp.A2A.AgentSkill
  alias Exocomp.Coordinator.ProfileCoverage

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
    },
    %AgentSkill{
      id: "exocomp.cluster.recover",
      name: "Cluster Recover",
      description:
        "Execute one audited, idempotent automatic restart of an allow-listed failed service on a target cluster node."
    }
  ]

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, opts) do
    coordinator_id = Keyword.get(opts, :coordinator_id, "localhost")

    card = %AgentCard{
      name: "Exocomp Coordinator Agent",
      description:
        "Exocomp coordinator. Aggregates cluster node diagnostics and orchestrates authenticated failed-service recovery.",
      url: "https://#{coordinator_id}/",
      version: "0.1.0",
      capabilities: %AgentCapabilities{},
      skills: @skills,
      clusterProfiles:
        ProfileCoverage.advertised_profiles(Keyword.get(opts, :profile_coverage, ProfileCoverage))
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
      skills: Enum.map(card.skills, &skill_to_json/1),
      clusterProfiles: Enum.map(card.clusterProfiles, &profile_to_json/1)
    }
  end

  defp skill_to_json(%AgentSkill{} = skill) do
    %{id: skill.id, name: skill.name, description: skill.description}
  end

  defp profile_to_json(%{id: id, versions: versions}),
    do: %{"id" => id, "versions" => versions}
end
