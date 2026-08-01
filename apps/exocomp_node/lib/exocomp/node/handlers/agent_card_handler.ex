# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Handlers.AgentCardHandler do
  @moduledoc """
  Serves the node Agent Card advertising diagnostic and recovery skills.
  """

  import Plug.Conn

  alias Exocomp.A2A.AgentCapabilities
  alias Exocomp.A2A.AgentCard
  alias Exocomp.A2A.AgentSkill
  alias Exocomp.ClusterProfile.Registry, as: ClusterProfileRegistry

  @skills [
    %AgentSkill{
      id: "exocomp.system.diagnose",
      name: "System Diagnose",
      description: "Collect CPU, memory, disk, and uptime observations."
    },
    %AgentSkill{
      id: "exocomp.service.diagnose",
      name: "Service Diagnose",
      description: "Inspect systemd service state for named services."
    },
    %AgentSkill{
      id: "exocomp.profile.inspect",
      name: "Profile Inspect",
      description: "Discover local Ceph daemon units and their systemd state."
    },
    %AgentSkill{
      id: "exocomp.remediation.propose",
      name: "Remediation Propose",
      description: "Propose a known remediation intent given current diagnostic context."
    },
    %AgentSkill{
      id: "exocomp.service.recover",
      name: "Service Recover",
      description:
        "Execute one audited, idempotent automatic restart of an allow-listed failed service and verify stability."
    }
  ]

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, opts) do
    node_id = Keyword.get(opts, :node_id, "localhost")

    card = %AgentCard{
      name: "Exocomp Node Agent",
      description:
        "Exocomp node agent. Supports diagnostics and automatic failed-service recovery.",
      url: "https://#{node_id}/",
      version: "0.1.0",
      capabilities: %AgentCapabilities{},
      skills: @skills,
      clusterProfiles: ClusterProfileRegistry.advertised_profiles()
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
