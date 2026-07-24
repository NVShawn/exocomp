defmodule Exocomp.Coordinator.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Exocomp.Coordinator.Audit, Application.get_env(:exocomp_coordinator, :audit, [])},
      {Exocomp.Coordinator.Registry, Application.get_env(:exocomp_coordinator, :registry, [])},
      {Exocomp.Coordinator.Inventory,
       inventory_path: Application.get_env(:exocomp_coordinator, :inventory_path)},
      {Exocomp.Coordinator.Resolver, Application.get_env(:exocomp_coordinator, :resolver, [])},
      {Task.Supervisor, name: Exocomp.Coordinator.PollTaskSupervisor},
      {Exocomp.Coordinator.HealthPoller,
       Application.get_env(:exocomp_coordinator, :health_poller, [])},
      {Exocomp.Coordinator.GoalStore, Application.get_env(:exocomp_coordinator, :goal_store, [])},
      {Task.Supervisor, name: Exocomp.Coordinator.DiagTaskSupervisor},
      {Exocomp.Coordinator.Orchestrator,
       Application.get_env(:exocomp_coordinator, :orchestrator, [])}
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Exocomp.Coordinator.Supervisor
    )
  end
end
