# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Application do
  @moduledoc """
  Mission Control application supervision tree.

  Mission Control is a self-hosted web application for managing Exocomp
  clusters through a real-time LiveView interface. Operators authenticate
  with OIDC, view fleet and incident state, converse with cluster-local
  models, and approve or deny typed remedies.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: Exocomp.MissionControl.PubSub},
      Exocomp.MissionControl.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Exocomp.MissionControl.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Exocomp.MissionControl.Endpoint.config_change(changed, removed)
    :ok
  end
end
