# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Application do
  @moduledoc false

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
      {Phoenix.PubSub, name: Exocomp.MissionControl.PubSub},
      Exocomp.MissionControl.Endpoint,
      Exocomp.MissionControl.Repo
    ]
  end
end
