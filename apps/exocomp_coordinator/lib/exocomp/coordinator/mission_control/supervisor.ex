# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.Supervisor do
  @moduledoc """
  Supervision tree for the optional Mission Control client connection and
  durable event outbox.

  This supervisor is started only when Mission Control configuration is present
  and enabled. It manages:

  - MissionControl.Outbox — durable event and command persistence
  - MissionControl.Connection — connection state, heartbeats, and reconnection

  The supervisor strategy is :one_for_one so that a connection failure does not
  restart the outbox, preserving durable state.
  """

  use Supervisor
  require Logger

  alias Exocomp.Coordinator.Config

  @doc """
  Starts the Mission Control supervision subtree with the given configuration.

  Returns `{:ok, pid}` on success or `{:error, reason}` on failure.
  """
  @spec start_link(Config.MissionControl.t(), keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(mission_control_config, opts \\ []) do
    Supervisor.start_link(__MODULE__, mission_control_config, opts)
  end

  @impl true
  def init(mission_control_config) do
    Logger.info(
      "[MissionControlSupervisor] Starting with config: #{inspect(mission_control_config)}"
    )

    children = [
      {Exocomp.Coordinator.MissionControl.Outbox, [config: mission_control_config]},
      {Exocomp.Coordinator.MissionControl.Connection, [config: mission_control_config]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
