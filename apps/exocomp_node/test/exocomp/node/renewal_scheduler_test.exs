# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.RenewalSchedulerTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.RenewalScheduler

  @cert Path.expand("../../fixtures/certs/node.crt", __DIR__)

  test "reads expiration from the active leaf certificate" do
    assert {:ok, expiry} = RenewalScheduler.certificate_expiry(@cert)
    assert %DateTime{} = expiry
    assert expiry.year >= 2025
  end

  test "renews at the threshold and reschedules from the replacement certificate" do
    owner = self()
    now = DateTime.utc_now()
    {:ok, expiries} = Agent.start_link(fn -> DateTime.add(now, 10, :second) end)

    renew = fn ->
      send(owner, :renewed)
      Agent.update(expiries, fn _ -> DateTime.add(now, 3_600, :second) end)
      :ok
    end

    expiry = fn _path -> {:ok, Agent.get(expiries, & &1)} end

    start_supervised!(
      {RenewalScheduler,
       cert_path: "unused",
       renew_fun: renew,
       now_fun: fn -> now end,
       expiry_fun: expiry,
       renew_before_seconds: 10,
       name: :threshold_scheduler}
    )

    assert_receive :renewed, 500
    assert %{status: :scheduled, last_error: nil} = RenewalScheduler.status(:threshold_scheduler)
  end

  test "retains failure state and schedules bounded retry" do
    now = DateTime.utc_now()

    pid =
      start_supervised!(
        {RenewalScheduler,
         cert_path: "unused",
         renew_fun: fn -> {:error, :coordinator_unavailable} end,
         now_fun: fn -> now end,
         expiry_fun: fn _ -> {:ok, DateTime.add(now, 3_600, :second)} end,
         renew_before_seconds: 60,
         jitter_fun: fn _ -> 1 end}
      )

    send(pid, :renew)
    Process.sleep(20)

    assert %{status: :retrying, last_error: :coordinator_unavailable} =
             RenewalScheduler.status(pid)
  end
end
