# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Telemetry do
  @moduledoc """
  Telemetry setup for Mission Control metrics.
  """

  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_poller
      {:telemetry_poller, period: 10_000, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc false
  def metrics do
    [
      counter("phoenix.router.dispatch.stop.duration",
        description: "The time spent in router dispatch",
        unit: {:microsecond, :millisecond}
      ),
      counter("phoenix.endpoint.stop.duration",
        description: "The time spent in the endpoint",
        unit: {:microsecond, :millisecond}
      ),
      counter("phoenix.live_view.mount.stop.duration",
        description: "The time spent in LiveView mount",
        unit: {:microsecond, :millisecond}
      )
    ]
  end
end
