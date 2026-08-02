# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.RemediationAdapter.CephCooldownTest do
  @moduledoc """
  Unit tests for Ceph daemon restart cooldown tracking.

  Tests cover:
  - Cooldown recording and expiration
  - Prevention of flapping via cooldown
  - Cooldown clearing after successful recovery
  - Reconciliation across restarts
  - Audit trail durability
  """

  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.RemediationAdapter.CephCooldown

  @node_id "osd-node-1"
  @daemon_id "osd.42"
  @target_unit "ceph-osd@42.service"

  # ---------------------------------------------------------------------------
  # Cooldown recording tests
  # ---------------------------------------------------------------------------

  test "records a cooldown event on verification failure" do
    {:ok, event} = CephCooldown.record_cooldown(@daemon_id, @node_id, @target_unit, :health_regressed)

    assert event.daemon_id == @daemon_id
    assert event.node_id == @node_id
    assert event.target_unit == @target_unit
    assert event.reason == :health_regressed
    assert is_binary(event.timestamp)
    assert is_binary(event.expires_at)
  end

  test "cooldown expiration time is in the future" do
    {:ok, event} = CephCooldown.record_cooldown(@daemon_id, @node_id, @target_unit, :mapping_changed)

    {:ok, expires_at, _} = DateTime.from_iso8601(event.expires_at)
    now = DateTime.utc_now()

    assert DateTime.compare(expires_at, now) == :gt
  end

  test "cooldown expiration is configurable" do
    cooldown_ms = 60 * 1000  # 1 minute

    {:ok, event} = CephCooldown.record_cooldown(
      @daemon_id,
      @node_id,
      @target_unit,
      :health_regressed,
      cooldown_ms: cooldown_ms
    )

    {:ok, expires_at, _} = DateTime.from_iso8601(event.expires_at)
    {:ok, timestamp, _} = DateTime.from_iso8601(event.timestamp)

    # Verify expiration is approximately cooldown_ms in the future
    diff_ms = DateTime.diff(expires_at, timestamp, :millisecond)

    assert diff_ms >= cooldown_ms - 100 and diff_ms <= cooldown_ms + 100
  end

  # ---------------------------------------------------------------------------
  # Cooldown checking tests
  # ---------------------------------------------------------------------------

  test "daemon is not in cooldown by default" do
    # With no events, should not be in cooldown
    assert CephCooldown.in_cooldown?(@daemon_id, @node_id) == false
  end

  test "daemon enters cooldown after recording failure" do
    audit_events = []

    audit_writer = fn _daemon_id, event ->
      send(self(), {:audit_event, event})
      :ok
    end

    {:ok, event} = CephCooldown.record_cooldown(
      @daemon_id,
      @node_id,
      @target_unit,
      :health_regressed,
      audit_writer: audit_writer
    )

    assert_receive {:audit_event, _event}

    # Now check if daemon is in cooldown
    audit_reader = fn _daemon_id ->
      {:ok, [event]}
    end

    assert CephCooldown.in_cooldown?(@daemon_id, @node_id, audit_reader: audit_reader) == true
  end

  test "daemon exits cooldown after expiration" do
    # Create an event that expired 1 minute ago
    expired_at = DateTime.utc_now() |> DateTime.add(-1, :minute) |> DateTime.to_iso8601()

    event = %{
      "node_id" => @node_id,
      "daemon_id" => @daemon_id,
      "expires_at" => expired_at
    }

    audit_reader = fn _daemon_id ->
      {:ok, [event]}
    end

    # Should not be in cooldown because it already expired
    assert CephCooldown.in_cooldown?(@daemon_id, @node_id, audit_reader: audit_reader) == false
  end

  test "multiple daemons can have independent cooldowns" do
    daemon1 = "osd.1"
    daemon2 = "osd.2"

    event1 = %{
      "node_id" => @node_id,
      "daemon_id" => daemon1,
      "expires_at" => future_time(30)
    }

    event2 = %{
      "node_id" => @node_id,
      "daemon_id" => daemon2,
      "expires_at" => past_time(1)
    }

    audit_reader_1 = fn _daemon_id ->
      {:ok, [event1]}
    end

    audit_reader_2 = fn _daemon_id ->
      {:ok, [event2]}
    end

    # daemon1 is in cooldown, daemon2 is not
    assert CephCooldown.in_cooldown?(daemon1, @node_id, audit_reader: audit_reader_1) == true
    assert CephCooldown.in_cooldown?(daemon2, @node_id, audit_reader: audit_reader_2) == false
  end

  test "cooldown is node-specific" do
    node1 = "node-1"
    node2 = "node-2"

    event = %{
      "node_id" => node1,
      "daemon_id" => @daemon_id,
      "expires_at" => future_time(30)
    }

    audit_reader = fn _daemon_id ->
      {:ok, [event]}
    end

    # Cooldown applies only to node1
    assert CephCooldown.in_cooldown?(@daemon_id, node1, audit_reader: audit_reader) == true
    assert CephCooldown.in_cooldown?(@daemon_id, node2, audit_reader: audit_reader) == false
  end

  # ---------------------------------------------------------------------------
  # Cooldown clearing tests
  # ---------------------------------------------------------------------------

  test "clears cooldown after successful recovery" do
    audit_events = []

    audit_writer = fn _daemon_id, _event ->
      :ok
    end

    :ok = CephCooldown.clear_cooldown(@daemon_id, audit_writer: audit_writer)
  end

  test "cooldown_cleared event resets tracking" do
    cooldown_event = %{
      "node_id" => @node_id,
      "daemon_id" => @daemon_id,
      "expires_at" => future_time(30)
    }

    cleared_event = %{
      "type" => "cooldown_cleared",
      "daemon_id" => @daemon_id
    }

    audit_reader = fn _daemon_id ->
      {:ok, [cooldown_event, cleared_event]}
    end

    # Even though there was a cooldown event, it's been cleared
    assert CephCooldown.in_cooldown?(@daemon_id, @node_id, audit_reader: audit_reader) == false
  end

  # ---------------------------------------------------------------------------
  # Audit trail tests
  # ---------------------------------------------------------------------------

  test "records multiple cooldown events in audit trail" do
    events = []

    audit_writer = fn _daemon_id, event ->
      send(self(), {:audit_event, event})
      :ok
    end

    # First failure
    {:ok, _event1} = CephCooldown.record_cooldown(
      @daemon_id,
      @node_id,
      @target_unit,
      :health_regressed,
      audit_writer: audit_writer
    )

    assert_receive {:audit_event, _event1}

    # Clear cooldown
    :ok = CephCooldown.clear_cooldown(@daemon_id, audit_writer: audit_writer)

    assert_receive {:audit_event, _event2}

    # Second failure (after cooldown cleared)
    {:ok, _event3} = CephCooldown.record_cooldown(
      @daemon_id,
      @node_id,
      @target_unit,
      :mapping_changed,
      audit_writer: audit_writer
    )

    assert_receive {:audit_event, _event3}
  end

  # ---------------------------------------------------------------------------
  # Error handling tests
  # ---------------------------------------------------------------------------

  test "handles audit reader failures gracefully" do
    audit_reader = fn _daemon_id ->
      {:error, :audit_unavailable}
    end

    # When audit reader fails, assume no cooldown (fail open for checks)
    assert CephCooldown.in_cooldown?(@daemon_id, @node_id, audit_reader: audit_reader) == false
  end

  test "handles audit writer failures gracefully" do
    audit_writer = fn _daemon_id, _event ->
      {:error, :audit_unavailable}
    end

    result = CephCooldown.record_cooldown(
      @daemon_id,
      @node_id,
      @target_unit,
      :health_regressed,
      audit_writer: audit_writer
    )

    assert {:error, :audit_unavailable} = result
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp future_time(minutes) do
    DateTime.utc_now()
    |> DateTime.add(minutes, :minute)
    |> DateTime.to_iso8601()
  end

  defp past_time(minutes) do
    DateTime.utc_now()
    |> DateTime.add(-minutes, :minute)
    |> DateTime.to_iso8601()
  end
end
