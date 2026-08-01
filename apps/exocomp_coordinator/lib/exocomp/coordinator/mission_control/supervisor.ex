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
  Returns a child spec for use in a supervision tree.

  Accepts either a config struct or a {config, opts} tuple. The resulting
  child spec ensures the supervisor is registered under
  Exocomp.Coordinator.MissionControlSupervisor and has type :supervisor.
  """
  def child_spec(init_arg) do
    {config, opts} =
      case init_arg do
        {c, o} when is_list(o) -> {c, o}
        c -> {c, []}
      end

    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [config, opts]},
      type: :supervisor,
      restart: :permanent,
      shutdown: :infinity
    }
  end

  @doc """
  Starts the Mission Control supervision subtree with the given configuration.

  Returns `{:ok, pid}` on success or `{:error, reason}` on failure.
  """
  @spec start_link(Config.MissionControl.t(), keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(mission_control_config, opts \\ []) do
    # Merge registration name into opts
    supervisor_opts = [name: Exocomp.Coordinator.MissionControlSupervisor] ++ opts
    Supervisor.start_link(__MODULE__, mission_control_config, supervisor_opts)
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
