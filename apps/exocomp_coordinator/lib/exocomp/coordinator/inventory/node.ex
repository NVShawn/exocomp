defmodule Exocomp.Coordinator.Inventory.Node do
  @moduledoc """
  A validated coordinator inventory entry.
  """

  @enforce_keys [:id, :hostname, :port, :certificate_identity, :capabilities]
  defstruct [:id, :hostname, :port, :certificate_identity, :capabilities, labels: %{}]

  @type t :: %__MODULE__{
          id: String.t(),
          hostname: String.t(),
          port: 1..65_535,
          certificate_identity: String.t(),
          capabilities: [String.t()],
          labels: %{optional(String.t()) => String.t()}
        }
end
