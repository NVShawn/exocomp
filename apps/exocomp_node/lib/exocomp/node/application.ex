defmodule Exocomp.Node.Application do
  @moduledoc false

  use Application

  alias Exocomp.Node.ExecutorLock

  @impl true
  def start(_type, _args) do
    children = [
      # Per-target execution serializer — ensures at most one action runs
      # against a given service at any time.
      {ExecutorLock, name: ExecutorLock}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Exocomp.Node.Supervisor)
  end
end
