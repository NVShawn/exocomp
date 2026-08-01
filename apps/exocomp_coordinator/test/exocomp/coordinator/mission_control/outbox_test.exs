# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.OutboxTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.Config
  alias Exocomp.Coordinator.MissionControl.Outbox

  @fixtures_dir Path.expand("../../../../../fixtures", __DIR__)

  setup do
    File.mkdir_p!(@fixtures_dir)

    outbox_dir = Path.join(@fixtures_dir, "outbox-#{System.os_time(:millisecond)}")
    File.mkdir_p!(outbox_dir)

    config = %Config.MissionControl{
      enabled: true,
      url: "wss://mission-control.example.com:443",
      trust_root: "/tmp/nonexistent.crt",
      client_cert: "/tmp/nonexistent.crt",
      client_key: "/tmp/nonexistent.key",
      heartbeat_interval_seconds: 30,
      reconnect_min_backoff_seconds: 1,
      reconnect_max_backoff_seconds: 60,
      outbox_path: outbox_dir
    }

    {:ok, pid} = Outbox.start_link(config: config, name: :test_outbox)

    on_exit(fn ->
      if Process.alive?(pid) do
        Process.exit(pid, :kill)
      end

      File.rm_rf!(outbox_dir)
    end)

    {:ok, outbox_pid: pid, outbox_dir: outbox_dir}
  end

  # ---------------------------------------------------------------------------
  # Event persistence
  # ---------------------------------------------------------------------------

  test "append_event persists an event and returns an event_id", %{outbox_pid: pid} do
    event = %{"kind" => "alert.opened", "cluster_seq" => 1}

    assert {:ok, event_id} = Outbox.append_event(event, pid)
    assert is_binary(event_id)
    assert String.length(event_id) > 0
  end

  test "list_pending_events returns appended events", %{outbox_pid: pid} do
    event1 = %{"kind" => "alert.opened", "cluster_seq" => 1}
    event2 = %{"kind" => "alert.updated", "cluster_seq" => 2}

    {:ok, _id1} = Outbox.append_event(event1, pid)
    {:ok, _id2} = Outbox.append_event(event2, pid)

    events = Outbox.list_pending_events(pid)

    assert length(events) == 2
    assert Enum.any?(events, &(&1["kind"] == "alert.opened"))
    assert Enum.any?(events, &(&1["kind"] == "alert.updated"))
  end

  test "acknowledge_event removes an event from pending list", %{outbox_pid: pid} do
    event = %{"kind" => "alert.opened", "cluster_seq" => 1}

    {:ok, event_id} = Outbox.append_event(event, pid)

    # Event should be in the pending list
    events_before = Outbox.list_pending_events(pid)
    assert length(events_before) == 1

    # Acknowledge the event
    assert :ok = Outbox.acknowledge_event(event_id, pid)

    # Event should no longer be in the pending list
    events_after = Outbox.list_pending_events(pid)
    assert length(events_after) == 0
  end

  test "acknowledge_event handles non-existent event gracefully", %{outbox_pid: pid} do
    # Should not raise an error
    assert :ok = Outbox.acknowledge_event("nonexistent-id", pid)
  end

  # ---------------------------------------------------------------------------
  # Command persistence
  # ---------------------------------------------------------------------------

  test "append_command persists a command and returns a command_id", %{outbox_pid: pid} do
    command = %{"kind" => "execute.action", "target_id" => "node-1"}

    assert {:ok, command_id} = Outbox.append_command(command, pid)
    assert is_binary(command_id)
    assert String.length(command_id) > 0
  end

  # ---------------------------------------------------------------------------
  # Outbox directory structure
  # ---------------------------------------------------------------------------

  test "outbox creates events and commands subdirectories", %{outbox_dir: dir} do
    events_dir = Path.join(dir, "events")
    commands_dir = Path.join(dir, "commands")

    assert File.dir?(events_dir)
    assert File.dir?(commands_dir)
  end

  # ---------------------------------------------------------------------------
  # Persistence across restarts
  # ---------------------------------------------------------------------------

  test "events persisted to disk survive server restart", %{outbox_dir: dir} do
    # Start first outbox server
    config = %Config.MissionControl{
      enabled: true,
      url: "wss://mission-control.example.com:443",
      trust_root: "/tmp/nonexistent.crt",
      client_cert: "/tmp/nonexistent.crt",
      client_key: "/tmp/nonexistent.key",
      heartbeat_interval_seconds: 30,
      reconnect_min_backoff_seconds: 1,
      reconnect_max_backoff_seconds: 60,
      outbox_path: dir
    }

    {:ok, pid1} = Outbox.start_link(config: config, name: :test_outbox_restart_1)

    event = %{"kind" => "alert.opened", "cluster_seq" => 1}
    {:ok, event_id} = Outbox.append_event(event, pid1)

    events_before = Outbox.list_pending_events(pid1)
    assert length(events_before) == 1

    # Verify the event file was written to disk
    events_file = Path.join([dir, "events", "#{event_id}.json"])
    assert File.exists?(events_file)
    {:ok, content} = File.read(events_file)
    assert String.contains?(content, "alert.opened")

    # Stop the outbox server
    GenServer.stop(pid1)
    # Give time for the process to exit
    Process.sleep(50)

    # Start a new outbox server pointing to the same directory
    {:ok, pid2} = Outbox.start_link(config: config, name: :test_outbox_restart_2)

    # Events should be reloaded from disk
    events_after = Outbox.list_pending_events(pid2)
    assert length(events_after) == 1
    assert events_after == events_before

    # Stop the second server
    GenServer.stop(pid2)
  end
end
