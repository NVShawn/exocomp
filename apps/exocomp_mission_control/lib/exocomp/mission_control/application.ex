# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      Exocomp.MissionControl.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Exocomp.MissionControl.PubSub},
      # Start the Endpoint (http/https)
      Exocomp.MissionControl.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Exocomp.MissionControl.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Exocomp.MissionControl.Endpoint.config_change(changed, removed)
    :ok
  end
end
