# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.SessionLivenessTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.MissionControl.SessionLiveness

  test "marks a session disconnected exactly 90 seconds after its last valid heartbeat" do
    {liveness, clock} = start_liveness()

    assert :ok = SessionLiveness.authenticated("session-a", liveness)
    assert_receive {:committed, "session-a", :connected}
    assert_receive {:published, "session-a", :connected}
    assert_receive {:timer_scheduled, {:liveness_check, first_generation}, 90_000}

    set_clock(clock, 30_000)
    assert :ok = SessionLiveness.heartbeat("session-a", liveness)
    assert_receive {:timer_scheduled, {:liveness_check, second_generation}, 90_000}
    assert second_generation > first_generation

    set_clock(clock, 90_000)
    send(liveness, {:liveness_check, first_generation})
    refute_receive {:committed, "session-a", :disconnected}, 20

    set_clock(clock, 119_999)
    send(liveness, {:liveness_check, second_generation})
    assert_receive {:timer_scheduled, {:liveness_check, third_generation}, 1}

    set_clock(clock, 120_000)
    send(liveness, {:liveness_check, third_generation})
    assert_receive {:committed, "session-a", :disconnected}
    assert_receive {:published, "session-a", :disconnected}
    assert %{status: :disconnected} = SessionLiveness.status(liveness)
  end

  test "publishes a connection transition only after it is committed" do
    owner = self()

    {liveness, clock} =
      start_liveness(
        commit_state_fn: fn _session_id, state ->
          send(owner, {:committed, state})
          if state == :disconnected, do: {:error, :database_unavailable}, else: :ok
        end,
        publish_state_fn: fn _session_id, state -> send(owner, {:published, state}) end
      )

    assert :ok = SessionLiveness.authenticated("session-a", liveness)
    assert_receive {:committed, :connected}
    assert_receive {:published, :connected}

    %{timer_generation: generation} = SessionLiveness.status(liveness)
    set_clock(clock, 90_000)
    send(liveness, {:liveness_check, generation})

    assert_receive {:committed, :disconnected}
    refute_receive {:published, :disconnected}, 20
    assert_receive {:timer_scheduled, {:liveness_check, _retry_generation}, 1_000}

    assert %{status: :connected, last_error: {:commit_failed, :database_unavailable}} =
             SessionLiveness.status(liveness)

    assert Process.alive?(liveness)
  end

  test "rejects stale sessions and only lets a valid active heartbeat reconnect a timed out session" do
    {liveness, clock} = start_liveness()

    assert :ok = SessionLiveness.authenticated("session-a", liveness)
    %{timer_generation: generation} = SessionLiveness.status(liveness)

    assert {:error, :not_active} = SessionLiveness.heartbeat("session-b", liveness)

    set_clock(clock, 90_000)
    send(liveness, {:liveness_check, generation})
    assert_receive {:committed, "session-a", :disconnected}
    assert_receive {:published, "session-a", :disconnected}

    set_clock(clock, 90_001)
    assert :ok = SessionLiveness.heartbeat("session-a", liveness)
    assert_receive {:committed, "session-a", :connected}
    assert_receive {:published, "session-a", :connected}
    assert %{status: :connected} = SessionLiveness.status(liveness)
  end

  defp start_liveness(opts \\ []) do
    owner = self()
    {:ok, clock} = Agent.start_link(fn -> 0 end)
    name = unique_name(:mission_control_liveness)

    defaults = [
      name: name,
      now_fn: fn -> Agent.get(clock, & &1) end,
      schedule_fn: fn message, delay ->
        send(owner, {:timer_scheduled, message, delay})
        make_ref()
      end,
      cancel_timer_fn: fn timer_ref ->
        send(owner, {:timer_cancelled, timer_ref})
        :ok
      end,
      commit_state_fn: fn session_id, state ->
        send(owner, {:committed, session_id, state})
        :ok
      end,
      publish_state_fn: fn session_id, state ->
        send(owner, {:published, session_id, state})
        :ok
      end
    ]

    liveness = start_supervised!({SessionLiveness, Keyword.merge(defaults, opts)}, id: name)
    {liveness, clock}
  end

  defp set_clock(clock, timestamp), do: Agent.update(clock, fn _ -> timestamp end)
  defp unique_name(prefix), do: String.to_atom("#{prefix}_#{System.unique_integer([:positive])}")
end
