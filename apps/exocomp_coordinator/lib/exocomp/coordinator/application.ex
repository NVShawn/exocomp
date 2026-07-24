defmodule Exocomp.Coordinator.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    enrollment_token_opts =
      []
      |> maybe_put(
        :store_path,
        Application.get_env(:exocomp_coordinator, :enrollment_token_store_path)
      )
      |> maybe_put(
        :max_lifetime,
        Application.get_env(:exocomp_coordinator, :enrollment_token_lifetime)
      )

    children = [
      {Exocomp.Coordinator.Audit, Application.get_env(:exocomp_coordinator, :audit, [])},
      Exocomp.Coordinator.Registry,
      {Exocomp.Coordinator.Inventory,
       inventory_path: Application.get_env(:exocomp_coordinator, :inventory_path)},
      {Exocomp.Coordinator.EnrollmentToken, enrollment_token_opts}
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Exocomp.Coordinator.Supervisor
    )
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
