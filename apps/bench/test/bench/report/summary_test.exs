# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Report.SummaryTest do
  use ExUnit.Case, async: true

  alias Bench.{ArtifactIdentity, Baseline, HostProfile, Sample}
  alias Bench.Report.Summary

  describe "to_json/1" do
    test "encodes a summary struct to JSON" do
      summary = %Summary{
        run_id: "run-001",
        host_profile: "amd64-ci",
        workload: :idle,
        metrics: %{}
      }

      assert {:ok, json} = Bench.Report.Summary.to_json(summary)
      assert is_binary(json)
      assert {:ok, decoded} = Jason.decode(json)
      assert decoded["run_id"] == "run-001"
    end
  end

  describe "gate evaluation" do
    test "passes values strictly below each budget" do
      metrics = %{
        "beam.cpu.node_plus_coordinator.mean_percent" => 4.9,
        "beam.memory.node_plus_coordinator.peak_percent" => 1.2
      }

      results = Summary.evaluate(metrics, gates())
      assert Enum.all?(results, &(&1["status"] == "pass"))
    end

    test "names the exact metric, observed value, and strict budget on regression" do
      metrics = %{
        "beam.cpu.node_plus_coordinator.mean_percent" => 7.3,
        "beam.memory.node_plus_coordinator.peak_percent" => 5.0
      }

      results = Summary.evaluate(metrics, gates())
      assert Enum.all?(results, &(&1["status"] == "fail"))

      cpu = Enum.find(results, &(&1["name"] == "beam_cpu_percent"))
      assert cpu["metric"] == "beam.cpu.node_plus_coordinator.mean_percent"
      assert cpu["observed"] == 7.3
      assert cpu["budget"] == 5.0
    end

    test "a missing metric is a hard failure" do
      [result] = Summary.evaluate(%{}, [hd(gates())])
      assert result["status"] == "fail"
      assert result["observed"] == nil
      assert result["reason"] == "metric was not emitted"
    end
  end

  describe "sample aggregation" do
    test "combines node and coordinator while reporting llama separately" do
      baseline = baseline()

      samples = [
        sample(1, :node, "cpu.percent", 1.0),
        sample(1, :coordinator, "cpu.percent", 2.0),
        sample(1, :llama, "cpu.percent", 70.0),
        sample(1, :node, "memory.rss.bytes", 100),
        sample(1, :coordinator, "memory.rss.bytes", 200),
        sample(1, :llama, "memory.rss.bytes", 2_000),
        sample(2, :node, "cpu.percent", 3.0),
        sample(2, :coordinator, "cpu.percent", 1.0),
        sample(2, :llama, "cpu.percent", 90.0),
        sample(2, :node, "memory.rss.bytes", 150),
        sample(2, :coordinator, "memory.rss.bytes", 250),
        sample(2, :llama, "memory.rss.bytes", 3_000)
      ]

      summary =
        Summary.build(samples, baseline, artifact(), host(10_000), run_id: "reproducible-run")

      assert summary.metrics["beam.cpu.node_plus_coordinator.mean_percent"] == 3.5
      assert summary.metrics["beam.memory.node_plus_coordinator.peak_percent"] == 4.0
      assert summary.metrics["llama.cpu.mean_percent"] == 80.0
      assert summary.metrics["bundle.cpu.mean_percent"] == 83.5
      assert summary.metrics["llama.memory.rss.peak_bytes"] == 3_000
      assert summary.metrics["bundle.memory.rss.peak_bytes"] == 3_400
      assert Summary.pass?(summary)
    end

    test "retains qualification metrics and reports polling latency percentiles" do
      resource_samples = [
        sample(1, :node, "cpu.percent", 1.0),
        sample(1, :coordinator, "cpu.percent", 1.0),
        sample(1, :node, "memory.rss.bytes", 100),
        sample(1, :coordinator, "memory.rss.bytes", 100)
      ]

      workload_samples =
        for {value, timestamp} <- Enum.with_index([10, 20, 30, 40], 2) do
          sample(timestamp, :coordinator, "coordinator.poll.cycle_ms", value)
        end ++
          [
            sample(6, :coordinator, "recovery.safety_pass", 1),
            sample(7, :beam, "soak.pass", 1)
          ]

      summary =
        Summary.build(resource_samples ++ workload_samples, baseline(), artifact(), host(10_000))

      assert summary.metrics["coordinator.poll.cycle_ms.count"] == 4
      assert summary.metrics["coordinator.poll.cycle_ms.p50"] == 20
      assert summary.metrics["coordinator.poll.cycle_ms.p95"] == 40
      assert summary.metrics["recovery.safety_pass"] == 1
      assert summary.metrics["soak.pass"] == 1
    end

    test "full qualification correctness gates fail by exact missing workload metric" do
      samples = [
        sample(1, :node, "cpu.percent", 1.0),
        sample(1, :coordinator, "cpu.percent", 1.0),
        sample(1, :node, "memory.rss.bytes", 100),
        sample(1, :coordinator, "memory.rss.bytes", 100),
        sample(2, :llama, "llama.restart.diagnostics_available", 1),
        sample(3, :coordinator, "coordinator.poll.healthy.count", 1),
        sample(3, :coordinator, "coordinator.poll.slow.count", 1),
        sample(3, :coordinator, "coordinator.poll.unreachable.count", 1),
        sample(3, :coordinator, "coordinator.poll.mailbox.depth", 0),
        sample(4, :coordinator, "coordinator.poll.mailbox.depth", 0),
        sample(5, :coordinator, "recovery.safety_pass", 1)
      ]

      summary =
        Summary.build(samples, baseline(), artifact(), host(10_000), config: %{"mode" => "full"})

      refute Summary.pass?(summary)
      failure = Enum.find(summary.gate_results, &(&1["name"] == "soak_stability"))
      assert failure["metric"] == "soak.pass"
      assert failure["reason"] == "metric was not emitted"
      assert Summary.failure_text(summary) =~ "budget:   = 1 qualification"
    end

    test "a missing component sample cannot be hidden by the other component" do
      samples = [
        sample(1, :node, "cpu.percent", 1.0),
        sample(1, :coordinator, "cpu.percent", nil, [:missing]),
        sample(1, :node, "memory.rss.bytes", 100),
        sample(1, :coordinator, "memory.rss.bytes", nil, [:missing])
      ]

      summary = Summary.build(samples, baseline(), artifact(), host(10_000))

      refute Summary.pass?(summary)
      assert summary.metrics["beam.cpu.node_plus_coordinator.mean_percent"] == nil
      assert summary.metrics["beam.memory.node_plus_coordinator.peak_percent"] == nil
      assert Summary.failure_text(summary) =~ "observed: (not recorded)"
      assert Summary.failure_text(summary) =~ "metric was not emitted"
    end

    test "failure output includes the exact metric, observation, budget, artifact, and baseline" do
      samples = [
        sample(1, :node, "cpu.percent", 3.0),
        sample(1, :coordinator, "cpu.percent", 3.1),
        sample(1, :node, "memory.rss.bytes", 100),
        sample(1, :coordinator, "memory.rss.bytes", 100)
      ]

      summary =
        Summary.build(samples, baseline(), artifact(), host(10_000), run_id: "failed-run")

      output = Summary.failure_text(summary)
      assert output =~ "M5 gate FAIL: beam_cpu_percent"
      assert output =~ "metric:   beam.cpu.node_plus_coordinator.mean_percent"
      assert output =~ "observed: 6.100 percent"
      assert output =~ "budget:   < 5.000 percent"
      assert output =~ "artifact: exocomp_node v0.1.0"
      assert output =~ "baseline: apps/bench/priv/bench/baselines/v0.1.0/amd64.toml"
    end

    test "summary JSON is reproducible for identical inputs" do
      samples = [
        sample(1, :node, "cpu.percent", 1.0),
        sample(1, :coordinator, "cpu.percent", 1.0),
        sample(1, :node, "memory.rss.bytes", 100),
        sample(1, :coordinator, "memory.rss.bytes", 100)
      ]

      first =
        Summary.build(samples, baseline(), artifact(), host(10_000),
          run_id: "fixed-run",
          config: %{"run_seconds" => 1}
        )

      second =
        Summary.build(samples, baseline(), artifact(), host(10_000),
          run_id: "fixed-run",
          config: %{"run_seconds" => 1}
        )

      assert Summary.to_json(first) == Summary.to_json(second)
    end
  end

  defp gates do
    baseline().gates
  end

  defp baseline do
    %Baseline{
      schema_version: 1,
      artifact_version: "0.1.0",
      architecture: "amd64",
      host_profile: "amd64-ci",
      gates: [
        %{
          name: "beam_cpu_percent",
          metric: "beam.cpu.node_plus_coordinator.mean_percent",
          budget: 5.0,
          unit: "percent",
          direction: "lower_is_better"
        },
        %{
          name: "beam_ram_percent",
          metric: "beam.memory.node_plus_coordinator.peak_percent",
          budget: 5.0,
          unit: "percent",
          direction: "lower_is_better"
        }
      ],
      reference: %{},
      path: "apps/bench/priv/bench/baselines/v0.1.0/amd64.toml"
    }
  end

  defp artifact do
    %ArtifactIdentity{
      artifact_version: "0.1.0",
      architecture: "amd64",
      source_commit: String.duplicate("a", 40),
      elixir_version: "1.20.2",
      otp_version: "28.5.0.3",
      erts_version: "16.2",
      node: %{},
      coordinator: %{},
      llama_server_path: "/artifact/llama-server.bin",
      llama_server_sha256: String.duplicate("b", 64),
      llama_launcher_sha256: String.duplicate("c", 64),
      model_path: "/artifact/model.gguf",
      model_sha256: String.duplicate("d", 64)
    }
  end

  defp host(ram_bytes) do
    %HostProfile{
      architecture: "amd64",
      cpu_model: "Qualification CPU",
      cpu_count: 2,
      ram_bytes: ram_bytes,
      kernel_version: "6.1",
      linux_distribution: "Qualification Linux",
      libc_version: "2.36",
      governor: "performance",
      container_or_vm: "vm"
    }
  end

  defp sample(timestamp, source, name, value, tags \\ []) do
    %Sample{
      timestamp: timestamp,
      source: source,
      metric_name: name,
      value: value,
      unit: if(String.contains?(name, "memory"), do: "bytes", else: "percent"),
      tags: tags
    }
  end
end
