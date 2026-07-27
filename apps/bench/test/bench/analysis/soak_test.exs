# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Analysis.SoakTest do
  use ExUnit.Case, async: true

  alias Bench.Analysis.Soak
  alias Bench.Sample

  @timestamps [0, 3_600_000, 7_200_000, 10_800_000]

  test "passes stable resources after bounded cache warm-up" do
    samples = complete_samples(fn name, index -> stable_value(name, index) end)

    assert {:ok, analysis} = Soak.analyze(samples)
    assert value(analysis, "soak.required_metrics_present") == 1
    assert value(analysis, "soak.pass") == 1
  end

  test "fails sustained descriptor growth" do
    samples =
      complete_samples(fn
        "file_descriptors.open", index -> 10 + index
        name, index -> stable_value(name, index)
      end)

    assert {:ok, analysis} = Soak.analyze(samples)
    assert value(analysis, "soak.pass") == 0
    assert value(analysis, "soak.node.file_descriptors_open.stable") == 0
  end

  test "fails when a required class or one architecture-side mailbox is absent" do
    samples =
      complete_samples(fn name, index -> stable_value(name, index) end)
      |> Enum.reject(&(&1.source == :node and &1.metric_name == "beam.process.count"))

    assert {:ok, analysis} = Soak.analyze(samples)
    assert value(analysis, "soak.required_metrics_present") == 0
    assert value(analysis, "soak.pass") == 0
  end

  test "ignores observations before the explicit soak boundary" do
    samples =
      complete_samples(fn name, index -> stable_value(name, index) end)
      |> Kernel.++([
        sample(:node, "file_descriptors.open", -1, 999),
        sample(:coordinator, "file_descriptors.open", -1, 999)
      ])

    assert {:ok, analysis} = Soak.analyze(samples, start_timestamp: 0)
    assert value(analysis, "soak.pass") == 1
  end

  defp complete_samples(value_fn) do
    exact = [
      {:node, "memory.rss.bytes"},
      {:coordinator, "memory.rss.bytes"},
      {:llama, "memory.rss.bytes"},
      {:node, "file_descriptors.open"},
      {:coordinator, "file_descriptors.open"},
      {:llama, "file_descriptors.open"},
      {:node, "beam.process.count"},
      {:coordinator, "beam.process.count"},
      {:node, "node.task_history.count"},
      {:coordinator, "coordinator.task_history.count"},
      {:node, "beam.mailbox.task_registry.depth"},
      {:coordinator, "beam.mailbox.goal_store.depth"}
    ]

    for {source, name} <- exact,
        {timestamp, index} <- Enum.with_index(@timestamps) do
      sample(source, name, timestamp, value_fn.(name, index))
    end
  end

  defp stable_value(name, index) do
    if String.contains?(name, "memory."), do: 100_000_000 + rem(index, 2) * 1_024, else: 10
  end

  defp sample(source, name, timestamp, value) do
    %Sample{
      timestamp: timestamp,
      source: source,
      metric_name: name,
      value: value,
      unit: "count",
      tags: []
    }
  end

  defp value(samples, name) do
    samples |> Enum.find(&(&1.metric_name == name)) |> Map.fetch!(:value)
  end
end
