defmodule Exocomp.Coordinator.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link([], strategy: :one_for_one, name: Exocomp.Coordinator.Supervisor)
  end
end
