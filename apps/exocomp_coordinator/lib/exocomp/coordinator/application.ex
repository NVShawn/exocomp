defmodule Exocomp.Coordinator.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Exocomp.Coordinator.TaskRegistry
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Exocomp.Coordinator.Supervisor)
  end
end
