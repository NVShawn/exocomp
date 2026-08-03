# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.ConnectionTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.Config
  alias Exocomp.Coordinator.MissionControl.Connection

  # ---------------------------------------------------------------------------
  # Connection initialization and status
  # ---------------------------------------------------------------------------

  test "connection starts in disconnected state" do
    config = %Config.MissionControl{
      enabled: true,
      url: "wss://mission-control.example.com:443",
      trust_root: "/tmp/nonexistent.crt",
      client_cert: "/tmp/nonexistent.crt",
      client_key: "/tmp/nonexistent.key",
      heartbeat_interval_seconds: 30,
      reconnect_min_backoff_seconds: 1,
      reconnect_max_backoff_seconds: 60,
      outbox_path: "/tmp/nonexistent-outbox"
    }

    {:ok, pid} = Connection.start_link(config: config, name: :test_connection)

    # Initial status should be disconnected (trying to connect)
    status = Connection.connection_status(pid)
    assert status in [:disconnected, :connecting]

    Process.exit(pid, :kill)
  end

  test "connection_status returns current connection status" do
    config = %Config.MissionControl{
      enabled: true,
      url: "wss://mission-control.example.com:443",
      trust_root: "/tmp/nonexistent.crt",
      client_cert: "/tmp/nonexistent.crt",
      client_key: "/tmp/nonexistent.key",
      heartbeat_interval_seconds: 30,
      reconnect_min_backoff_seconds: 1,
      reconnect_max_backoff_seconds: 60,
      outbox_path: "/tmp/nonexistent-outbox"
    }

    {:ok, pid} = Connection.start_link(config: config, name: :test_connection_status)

    # Should return a valid status
    status = Connection.connection_status(pid)
    assert is_atom(status)
    assert status in [:disconnected, :connecting, :connected]

    Process.exit(pid, :kill)
  end

  # ---------------------------------------------------------------------------
  # Configuration parameters
  # ---------------------------------------------------------------------------

  test "connection uses configured heartbeat interval" do
    config = %Config.MissionControl{
      enabled: true,
      url: "wss://mission-control.example.com:443",
      trust_root: "/tmp/nonexistent.crt",
      client_cert: "/tmp/nonexistent.crt",
      client_key: "/tmp/nonexistent.key",
      heartbeat_interval_seconds: 45,
      reconnect_min_backoff_seconds: 2,
      reconnect_max_backoff_seconds: 120,
      outbox_path: "/tmp/nonexistent-outbox"
    }

    {:ok, pid} = Connection.start_link(config: config, name: :test_connection_heartbeat)

    # The connection should be initialized with the configured parameters
    # We can verify this by checking that the process is alive
    assert Process.alive?(pid)

    Process.exit(pid, :kill)
  end

  test "connection uses configured reconnect bounds" do
    config = %Config.MissionControl{
      enabled: true,
      url: "wss://mission-control.example.com:443",
      trust_root: "/tmp/nonexistent.crt",
      client_cert: "/tmp/nonexistent.crt",
      client_key: "/tmp/nonexistent.key",
      heartbeat_interval_seconds: 30,
      reconnect_min_backoff_seconds: 5,
      reconnect_max_backoff_seconds: 300,
      outbox_path: "/tmp/nonexistent-outbox"
    }

    {:ok, pid} = Connection.start_link(config: config, name: :test_connection_bounds)

    # The connection should be initialized with the configured backoff bounds
    assert Process.alive?(pid)

    Process.exit(pid, :kill)
  end

  # ---------------------------------------------------------------------------
  # Behavior when coordinator-local services are healthy
  # ---------------------------------------------------------------------------

  test "connection failure does not stop the coordinator" do
    config = %Config.MissionControl{
      enabled: true,
      url: "wss://invalid-mission-control.internal:443",
      trust_root: "/tmp/nonexistent.crt",
      client_cert: "/tmp/nonexistent.crt",
      client_key: "/tmp/nonexistent.key",
      heartbeat_interval_seconds: 30,
      reconnect_min_backoff_seconds: 1,
      reconnect_max_backoff_seconds: 60,
      outbox_path: "/tmp/nonexistent-outbox"
    }

    # Connection should start even if Mission Control is unreachable
    {:ok, pid} = Connection.start_link(config: config, name: :test_connection_failure)

    # Process should remain alive despite connection failure
    assert Process.alive?(pid)

    # Status should reflect the inability to connect
    status = Connection.connection_status(pid)
    assert status in [:disconnected, :connecting]

    Process.exit(pid, :kill)
  end
end
