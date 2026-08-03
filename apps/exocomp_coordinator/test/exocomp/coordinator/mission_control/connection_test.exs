# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.ConnectionTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.MissionControl.Connection

  test "sends one heartbeat per cadence and ignores a cancelled heartbeat timer" do
    owner = self()

    connection =
      start_connection(
        send_fn: fn session, event ->
          send(owner, {:heartbeat_sent, session, event})
          :ok
        end
      )

    assert :ok = Connection.authenticated(:first_session, connection)
    assert_receive {:timer_scheduled, {:heartbeat, first_generation}, 30_000}
    assert_receive {:timer_scheduled, {:stable, _stable_generation}, 90_000}

    assert :ok = Connection.authenticated(:second_session, connection)
    assert_receive {:timer_scheduled, {:heartbeat, second_generation}, 30_000}
    assert second_generation > first_generation

    send(connection, {:heartbeat, first_generation})
    refute_receive {:heartbeat_sent, _, _}, 20

    send(connection, {:heartbeat, second_generation})

    assert_receive {:heartbeat_sent, :second_session,
                    %{kind: "cluster.heartbeat", schema_version: 1}}

    assert_receive {:timer_scheduled, {:heartbeat, next_generation}, 30_000}
    assert next_generation > second_generation
  end

  test "uses bounded full-jitter exponential reconnect delays" do
    owner = self()

    connection =
      start_connection(
        random_fn: fn lower, upper ->
          send(owner, {:random_bounds, lower, upper})
          upper
        end,
        connect_fn: fn ->
          send(owner, :connect_attempt)
          {:error, :offline}
        end
      )

    assert :ok = Connection.authenticated(:session, connection)
    assert :ok = Connection.disconnected(:transport_closed, connection)

    expected_bounds = [1_000, 2_000, 4_000, 8_000, 16_000, 32_000, 60_000, 60_000]

    expected_bounds
    |> Enum.with_index()
    |> Enum.each(fn {expected_bound, index} ->
      assert_receive {:random_bounds, 0, ^expected_bound}
      assert_receive {:timer_scheduled, {:reconnect, generation}, ^expected_bound}

      if index < length(expected_bounds) - 1 do
        send(connection, {:reconnect, generation})
        assert_receive :connect_attempt
      end
    end)

    assert %{backoff_attempts: 8, reconnect_delay_ms: 60_000, status: :disconnected} =
             Connection.status(connection)
  end

  test "resets backoff only after the authenticated connection is stable" do
    owner = self()

    connection =
      start_connection(
        random_fn: fn lower, upper ->
          send(owner, {:random_bounds, lower, upper})
          upper
        end
      )

    assert :ok = Connection.authenticated(:first_session, connection)
    assert :ok = Connection.disconnected(:early_loss, connection)
    assert_receive {:random_bounds, 0, 1_000}
    assert %{backoff_attempts: 1, stable: false} = Connection.status(connection)

    assert :ok = Connection.authenticated(:second_session, connection)
    assert %{backoff_attempts: 1, stable: false} = Connection.status(connection)

    %{stable_generation: stable_generation} = Connection.status(connection)
    send(connection, {:stable, stable_generation})

    assert %{backoff_attempts: 0, stable: true} = Connection.status(connection)
    assert :ok = Connection.disconnected(:stable_loss, connection)
    assert_receive {:random_bounds, 0, 1_000}
  end

  test "ignores a stale stability timer after the session disconnects" do
    owner = self()

    connection =
      start_connection(
        random_fn: fn lower, upper ->
          send(owner, {:random_bounds, lower, upper})
          upper
        end
      )

    assert :ok = Connection.authenticated(:session, connection)
    %{stable_generation: stable_generation} = Connection.status(connection)
    assert :ok = Connection.disconnected(:transport_closed, connection)
    assert_receive {:random_bounds, 0, 1_000}

    send(connection, {:stable, stable_generation})

    assert %{backoff_attempts: 1, stable: false, status: :disconnected} =
             Connection.status(connection)
  end

  test "stops an in-flight connect worker when a session is authenticated" do
    owner = self()

    connection =
      start_connection(
        connect_fn: fn ->
          send(owner, {:connect_started, self()})

          receive do
            :never -> {:ok, :stale_session}
          end
        end
      )

    assert :ok = Connection.connect_now(connection)
    assert_receive {:connect_started, worker}
    worker_ref = Process.monitor(worker)

    assert :ok = Connection.authenticated(:active_session, connection)
    assert_receive {:DOWN, ^worker_ref, :process, ^worker, :killed}
    assert %{authenticated: true, status: :connected} = Connection.status(connection)
  end

  test "connector and heartbeat failures cannot crash or block the manager" do
    owner = self()

    connection =
      start_connection(
        connect_fn: fn ->
          send(owner, {:connect_started, self()})

          receive do
            :release_connect -> {:error, :offline}
          end
        end,
        send_fn: fn _session, _event -> raise "socket is closed" end
      )

    assert :ok = Connection.connect_now(connection)
    assert_receive {:connect_started, worker}
    assert %{status: :connecting} = Connection.status(connection)
    assert Process.alive?(connection)

    send(worker, :release_connect)
    assert_receive {:timer_scheduled, {:reconnect, _generation}, _delay}

    assert :ok = Connection.authenticated(:session, connection)
    %{heartbeat_generation: heartbeat_generation} = Connection.status(connection)
    send(connection, {:heartbeat, heartbeat_generation})

    assert_receive {:timer_scheduled, {:reconnect, _generation}, _delay}
    assert %{status: :disconnected, authenticated: false} = Connection.status(connection)
    assert Process.alive?(connection)
  end

  test "treats a connect worker killed externally without a result as a failed attempt" do
    owner = self()

    connection =
      start_connection(
        connect_fn: fn ->
          send(owner, {:connect_started, self()})

          # Block forever so the test can kill us with an uncatchable :kill signal
          receive do
            :never -> {:ok, :session}
          end
        end,
        random_fn: fn lower, upper ->
          send(owner, {:random_bounds, lower, upper})
          upper
        end
      )

    assert :ok = Connection.connect_now(connection)
    assert_receive {:connect_started, worker}

    # :kill cannot be caught by safely/rescue/catch, so worker exits without sending a result
    Process.exit(worker, :kill)

    assert_receive {:random_bounds, 0, 1_000}
    assert_receive {:timer_scheduled, {:reconnect, _generation}, 1_000}

    assert %{
             status: :disconnected,
             backoff_attempts: 1,
             last_error: {:connect_worker_down, :killed}
           } = Connection.status(connection)

    assert Process.alive?(connection)
  end

  defp start_connection(opts) do
    owner = self()
    name = unique_name(:mission_control_connection)

    schedule_fn = fn message, delay ->
      send(owner, {:timer_scheduled, message, delay})
      make_ref()
    end

    cancel_timer_fn = fn timer_ref ->
      send(owner, {:timer_cancelled, timer_ref})
      :ok
    end

    start_supervised!(
      {Connection,
       [
         name: name,
         start_immediately: false,
         schedule_fn: schedule_fn,
         cancel_timer_fn: cancel_timer_fn
       ] ++ opts},
      id: name
    )
  end

  defp unique_name(prefix), do: String.to_atom("#{prefix}_#{System.unique_integer([:positive])}")
end
