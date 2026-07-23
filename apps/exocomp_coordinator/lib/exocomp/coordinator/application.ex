defmodule Exocomp.Coordinator.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Exocomp.Coordinator.Audit, Application.get_env(:exocomp_coordinator, :audit, [])},
      Exocomp.Coordinator.Registry,
      {Exocomp.Coordinator.Inventory,
       inventory_path: Application.get_env(:exocomp_coordinator, :inventory_path)}
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Exocomp.Coordinator.Supervisor
    )
  end
end
