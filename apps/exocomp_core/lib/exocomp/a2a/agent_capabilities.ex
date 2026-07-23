defmodule Exocomp.A2A.AgentCapabilities do
  @moduledoc """
  Describes the optional capabilities that an A2A 1.0 agent supports.

  Corresponds to the `AgentCapabilities` object in the A2A 1.0 specification:
  https://google.github.io/A2A/specification/#agentcapabilities

  All fields default to `false` (capability not supported). Agents that
  support a capability set the corresponding field to `true` in their
  `AgentCard`.
  """

  @enforce_keys []

  defstruct streaming: false,
            pushNotifications: false,
            stateTransitionHistory: false

  @type t :: %__MODULE__{
          streaming: boolean(),
          pushNotifications: boolean(),
          stateTransitionHistory: boolean()
        }
end
