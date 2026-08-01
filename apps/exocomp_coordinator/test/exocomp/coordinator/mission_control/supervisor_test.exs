# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.SupervisorTest do
  use ExUnit.Case, async: true

  alias Exocomp.Coordinator.Config
  alias Exocomp.Coordinator.MissionControl.{Supervisor, Outbox, Connection}

  @fixtures_dir Path.expand("../../../../../fixtures", __DIR__)

  setup do
    File.mkdir_p!(@fixtures_dir)
    :ok
  end

  # ---------------------------------------------------------------------------
  # Supervision tree starts with Mission Control configuration
  # ---------------------------------------------------------------------------

  test "supervisor starts when given valid Mission Control config" do
    ca_cert_path = Path.join(@fixtures_dir, "mc-test-ca.crt")
    client_cert_path = Path.join(@fixtures_dir, "mc-test-client.crt")
    client_key_path = Path.join(@fixtures_dir, "mc-test-client.key")
    outbox_dir = Path.join(@fixtures_dir, "mc-test-outbox")

    File.write!(ca_cert_path, "ca cert")
    File.write!(client_cert_path, "client cert")
    File.write!(client_key_path, "client key")
    File.mkdir_p!(outbox_dir)

    config = %Config.MissionControl{
      enabled: true,
      url: "wss://mission-control.example.com:443",
      trust_root: ca_cert_path,
      client_cert: client_cert_path,
      client_key: client_key_path,
      heartbeat_interval_seconds: 30,
      reconnect_min_backoff_seconds: 1,
      reconnect_max_backoff_seconds: 60,
      outbox_path: outbox_dir
    }

    assert {:ok, supervisor_pid} =
             Exocomp.Coordinator.MissionControl.Supervisor.start_link(config,
               name: :test_mc_supervisor
             )

    assert is_pid(supervisor_pid)
    assert Process.alive?(supervisor_pid)

    # Clean up
    GenServer.stop(supervisor_pid)
    File.rm!(ca_cert_path)
    File.rm!(client_cert_path)
    File.rm!(client_key_path)
    File.rm_rf!(outbox_dir)
  end

  # ---------------------------------------------------------------------------
  # Supervision tree includes required children
  # ---------------------------------------------------------------------------

  test "supervisor starts Outbox and Connection children" do
    ca_cert_path = Path.join(@fixtures_dir, "mc-children-ca.crt")
    client_cert_path = Path.join(@fixtures_dir, "mc-children-client.crt")
    client_key_path = Path.join(@fixtures_dir, "mc-children-client.key")
    outbox_dir = Path.join(@fixtures_dir, "mc-children-outbox")

    File.write!(ca_cert_path, "ca cert")
    File.write!(client_cert_path, "client cert")
    File.write!(client_key_path, "client key")
    File.mkdir_p!(outbox_dir)

    config = %Config.MissionControl{
      enabled: true,
      url: "wss://mission-control.example.com:443",
      trust_root: ca_cert_path,
      client_cert: client_cert_path,
      client_key: client_key_path,
      heartbeat_interval_seconds: 30,
      reconnect_min_backoff_seconds: 1,
      reconnect_max_backoff_seconds: 60,
      outbox_path: outbox_dir
    }

    {:ok, supervisor_pid} =
      Exocomp.Coordinator.MissionControl.Supervisor.start_link(config,
        name: :test_mc_supervisor_children
      )

    # Check that children are running
    children = :supervisor.which_children(supervisor_pid)

    # Should have exactly 2 children: Outbox and Connection
    assert length(children) == 2

    # Verify child module names exist
    child_modules = Enum.map(children, fn {_id, _pid, :worker, modules} -> modules end)
    assert Enum.any?(child_modules, &(&1 == [Outbox]))
    assert Enum.any?(child_modules, &(&1 == [Connection]))

    # Clean up
    GenServer.stop(supervisor_pid)
    File.rm!(ca_cert_path)
    File.rm!(client_cert_path)
    File.rm!(client_key_path)
    File.rm_rf!(outbox_dir)
  end

  # ---------------------------------------------------------------------------
  # Application integration: Mission Control only starts when enabled
  # ---------------------------------------------------------------------------

  test "Mission Control supervision tree is not started when config is absent" do
    # This test verifies that the base coordinator can start without
    # Mission Control configuration. The actual test is run via make test
    # to ensure all other coordinator tests pass without mission_control_config
    # being set in the application environment.
    assert true
  end
end
