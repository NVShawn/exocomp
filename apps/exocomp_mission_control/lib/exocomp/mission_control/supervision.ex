# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Supervision do
  @moduledoc "Checks only local Mission Control supervision state."

  @doc "Returns `:ok` when configured critical processes are alive."
  @spec check([GenServer.name()]) :: :ok | {:error, :critical_worker_down}
  def check(processes \\ configured_processes()) do
    if Enum.all?(processes, &alive?/1) do
      :ok
    else
      {:error, :critical_worker_down}
    end
  end

  @doc "Returns the configured local process set used by readiness."
  @spec configured_processes() :: [GenServer.name()]
  def configured_processes do
    Application.get_env(:exocomp_mission_control, :critical_processes, [])
  end

  defp alive?(name) when is_pid(name), do: Process.alive?(name)
  defp alive?(name) when is_atom(name), do: is_pid(Process.whereis(name))
  defp alive?({:via, registry, key}), do: is_pid(GenServer.whereis({:via, registry, key}))
  defp alive?(_name), do: false
end
