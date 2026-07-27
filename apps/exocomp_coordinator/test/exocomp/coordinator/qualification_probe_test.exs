# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.QualificationProbeTest do
  use ExUnit.Case, async: false

  alias Exocomp.Coordinator.QualificationProbe

  test "polling exercises a healthy, slow, and unreachable mixture without mailbox growth" do
    assert {:ok, samples} =
             QualificationProbe.polling(cycles: 4, slow_ms: 5, timeout_ms: 100)

    assert values(samples, "coordinator.poll.healthy.count") == [1, 1, 1, 1]
    assert values(samples, "coordinator.poll.slow.count") == [1, 1, 1, 1]
    assert values(samples, "coordinator.poll.unreachable.count") == [1, 1, 1, 1]
    assert Enum.all?(values(samples, "coordinator.poll.in_flight.count"), &(&1 == 0))

    mailbox = values(samples, "coordinator.poll.mailbox.depth")
    assert List.last(mailbox) <= List.first(mailbox)
    assert Enum.all?(values(samples, "coordinator.poll.cycle_ms"), &(&1 >= 5))
  end

  test "recovery reports observation-to-verification and preserves fail-closed safety" do
    assert {:ok, samples} = QualificationProbe.recovery()
    assert value(samples, "recovery.observation_to_verification_ms") >= 10
    assert value(samples, "recovery.execution.count") == 1
    assert value(samples, "recovery.verification.count") == 1
    assert value(samples, "recovery.audit_fail_closed") == 1
    assert value(samples, "recovery.safety_pass") == 1
  end

  defp values(samples, name) do
    for %{"metric_name" => ^name, "value" => value} <- samples, do: value
  end

  defp value(samples, name), do: samples |> values(name) |> List.last()
end
