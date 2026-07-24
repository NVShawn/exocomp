defmodule Exocomp.A2A.AgentSkill do
  @moduledoc """
  Describes a single skill that an A2A 1.0 agent can perform.

  Corresponds to the `AgentSkill` object in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#agentskill

  Skills are enumerated in the `AgentCard` and allow clients to discover
  what kinds of tasks an agent is able to handle. `id` and `name` are
  required; all other fields are optional.
  """

  @enforce_keys [:id, :name]

  defstruct id: nil,
            name: nil,
            description: nil,
            inputModes: nil,
            outputModes: nil

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          description: String.t() | nil,
          inputModes: [String.t()] | nil,
          outputModes: [String.t()] | nil
        }
end
