# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.QualificationProbeTest do
  use ExUnit.Case, async: false

  alias Exocomp.QualificationProbe

  setup do
    if pid = Process.whereis(QualificationProbe), do: GenServer.stop(pid)
    on_exit(fn -> if pid = Process.whereis(QualificationProbe), do: GenServer.stop(pid) end)
    :ok
  end

  test "samples VM resources, named mailboxes, and bounded history" do
    registered = :"qualification_probe_target_#{System.unique_integer([:positive])}"
    Process.register(self(), registered)
    send(self(), :queued_for_probe)

    assert :ok =
             QualificationProbe.start(
               source: :coordinator,
               interval_ms: 60_000,
               named_processes: [{"registry", registered}],
               history: [{"coordinator.task_history", fn -> 7 end}]
             )

    assert {:ok, json} = QualificationProbe.export_and_stop()
    samples = Jason.decode!(json)

    assert metric(samples, "beam.memory.total.bytes") > 0
    assert metric(samples, "beam.process.count") > 0
    assert metric(samples, "beam.mailbox.registry.depth") >= 1
    assert metric(samples, "coordinator.task_history.count") == 7
    assert Enum.all?(samples, &(&1["source"] == "coordinator"))
    refute Process.whereis(QualificationProbe)

    assert_receive :queued_for_probe
  end

  test "marks missing processes and failing observations unavailable" do
    missing = :"missing_probe_target_#{System.unique_integer([:positive])}"

    assert :ok =
             QualificationProbe.start(
               source: :node,
               named_processes: [{"missing", missing}],
               history: [{"bad", fn -> raise "unavailable" end}]
             )

    assert {:ok, json} = QualificationProbe.export_and_stop()
    samples = Jason.decode!(json)

    assert sample(samples, "beam.mailbox.missing.depth")["value"] == nil
    assert sample(samples, "beam.mailbox.missing.depth")["tags"] == ["unavailable"]
    assert sample(samples, "bad.count")["tags"] == ["unavailable"]
  end

  test "rejects invalid configuration and duplicate samplers" do
    assert {:error, {:invalid_source, :llama}} = QualificationProbe.start(source: :llama)
    assert :ok = QualificationProbe.start(source: :node)
    assert {:error, :already_started} = QualificationProbe.start(source: :node)
  end

  defp metric(samples, name), do: sample(samples, name)["value"]
  defp sample(samples, name), do: Enum.find(samples, &(&1["metric_name"] == name))
end
