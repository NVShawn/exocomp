# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule ExocompMissionControlWeb.Telemetry do
  @moduledoc """
  Telemetry metrics for Mission Control.
  """

  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will automatically execute the given periodic measurements
      {:telemetry_poller, Telemetry.Poller.periodic_measurements([periodic_measurements()])}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # VM Metrics
      Telemetry.Metrics.gauge("vm.memory.total", unit: {:byte, :kilobyte}),
      Telemetry.Metrics.gauge("vm.total_run_queue_lengths.total"),
      Telemetry.Metrics.gauge("vm.total_run_queue_lengths.cpu"),
      Telemetry.Metrics.gauge("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      {ExocompMissionControlWeb.Telemetry, :memory, []}
    ]
  end

  def memory do
    :telemetry.execute([:vm, :memory], %{
      total: :erlang.memory(:total),
      processes: :erlang.memory(:processes),
      atom: :erlang.memory(:atom),
      binary: :erlang.memory(:binary),
      code: :erlang.memory(:code)
    })
  end
end
