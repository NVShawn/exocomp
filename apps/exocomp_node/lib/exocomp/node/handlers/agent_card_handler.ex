defmodule Exocomp.Node.Handlers.AgentCardHandler do
  @moduledoc """
  Serves the diagnostic-only node Agent Card.
  """

  import Plug.Conn

  alias Exocomp.A2A.AgentCapabilities
  alias Exocomp.A2A.AgentCard
  alias Exocomp.A2A.AgentSkill

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
      id: "exocomp.remediation.propose",
      name: "Remediation Propose",
      description: "Propose a known remediation intent given current diagnostic context."
    }
  ]

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, opts) do
    node_id = Keyword.get(opts, :node_id, "localhost")

    card = %AgentCard{
      name: "Exocomp Node Agent",
      description: "Diagnostic-only Exocomp node agent. Cannot modify host state.",
      url: "https://#{node_id}/",
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
