defmodule Exocomp.Coordinator.Health do
  @moduledoc """
  Structured health snapshot for coordinator subsystems.
  """

  alias Exocomp.Coordinator.{Audit, Inventory, Registry}

  @spec check() :: map()
  def check do
    inventory = safe_call(Inventory, &Inventory.status/0)
    audit = safe_call(Audit, &Audit.status/0)
    registry = safe_call(Registry, fn -> %{node_count: length(Registry.all())} end)

    status =
      if healthy?(inventory) and healthy?(registry) and healthy_audit?(audit),
        do: :healthy,
        else: :degraded

    %{status: status, inventory: inventory, registry: registry, audit: audit}
  end

  defp safe_call(process, function) do
    if Process.whereis(process) do
      try do
        function.()
      catch
        :exit, reason -> %{healthy: false, error: inspect(reason)}
      end
    else
      %{healthy: false, error: :not_running}
    end
  end

  defp healthy?(%{healthy: false}), do: false
  defp healthy?(%{error: error}) when not is_nil(error), do: false
  defp healthy?(_status), do: true

  defp healthy_audit?(%{healthy: healthy}), do: healthy
  defp healthy_audit?(_status), do: false
end
