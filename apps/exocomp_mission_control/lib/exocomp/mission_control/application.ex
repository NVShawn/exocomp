# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Application do
  @moduledoc "OTP application for the Mission Control control plane."

  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link(children(),
      strategy: :one_for_one,
      name: Exocomp.MissionControl.Supervisor
    )
  end

  @impl true
  def config_change(changed, _new, removed) do
    Exocomp.MissionControl.Endpoint.config_change(changed, removed)
    :ok
  end

  @doc false
  def children do
    [
      Exocomp.MissionControl.Telemetry,
      {Phoenix.PubSub, name: Exocomp.MissionControl.PubSub},
      Exocomp.MissionControl.OIDCConfigCache,
      Exocomp.MissionControl.Endpoint
    ]
  end
end
