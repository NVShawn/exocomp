defmodule Exocomp.A2A.AgentCard do
  @moduledoc """
  Machine-readable description of an A2A 1.0 agent.

  Corresponds to the `AgentCard` object in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#agentcard

  The `AgentCard` is served at the well-known URL `/.well-known/agent.json`
  and describes the agent's identity, capabilities, and skills to clients.

  Required fields: `name`, `description`, `url`, `version`.
  Optional fields default to `nil` or an empty list.
  """

  @enforce_keys [:name, :description, :url, :version]

  defstruct name: nil,
            description: nil,
            url: nil,
            version: nil,
            capabilities: nil,
            skills: [],
            defaultInputModes: nil,
            defaultOutputModes: nil

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          url: String.t(),
          version: String.t(),
          capabilities: Exocomp.A2A.AgentCapabilities.t() | nil,
          skills: [Exocomp.A2A.AgentSkill.t()],
          defaultInputModes: [String.t()] | nil,
          defaultOutputModes: [String.t()] | nil
        }
end
