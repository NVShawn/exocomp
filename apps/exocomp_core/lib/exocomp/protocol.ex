defmodule Exocomp.Protocol do
  @moduledoc """
  Shared protocol metadata used by Exocomp applications.
  """

  @version "1.0"

  @doc "Returns the supported A2A protocol version."
  @spec version() :: String.t()
  def version, do: @version
end
