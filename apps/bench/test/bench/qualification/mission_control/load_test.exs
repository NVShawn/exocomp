# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Qualification.MissionControl.LoadTest do
  use ExUnit.Case

  alias Bench.Qualification.MissionControl.{Config, Load}

  describe "generate_event/3" do
    test "generates valid MC protocol envelope" do
      event = Load.generate_event("cluster-1", 42, "alert.opened")

      assert event["schema_version"] == 1
      assert event["cluster_seq"] == 42
      assert event["kind"] == "alert.opened"
      assert String.starts_with?(event["event_id"], "018")
      assert String.starts_with?(event["correlation_id"], "corr_")
      assert is_map(event["payload"])
    end

    test "generates unique event IDs" do
      id1 = Load.generate_event_id()
      id2 = Load.generate_event_id()

      assert String.starts_with?(id1, "018")
      assert String.starts_with?(id2, "018")
      assert id1 != id2
    end

    test "generates unique correlation IDs" do
      cid1 = Load.generate_correlation_id()
      cid2 = Load.generate_correlation_id()

      assert cid1 != cid2
    end
  end

  describe "run/4" do
    test "collects samples from load workload" do
      config = %Config{
        mode: :short,
        mc_service_url: "http://localhost:4000",
        evidence_dir: nil,
        warm_up_seconds: 1,
        run_seconds: 1,
        sample_interval_ms: 1000,
        event_send_timeout_ms: 10_000,
        cluster_count: 2,
        nodes_per_cluster: 10,
        event_burst_per_second: 5,
        soak_load_interval_seconds: 5,
        poll_cycles: 1
      }

      send_fn = fn _event ->
        {:ok, "acknowledged"}
      end

      {:ok, samples} = Load.run(100, config, send_fn, sleep_fn: fn _ms -> :ok end)

      assert is_list(samples)
      assert Enum.all?(samples, &is_struct(&1, Bench.Sample))

      # Should have metrics for successful sends
      success_metrics = Enum.filter(samples, &String.contains?(&1.metric_name, "success"))
      assert length(success_metrics) > 0
    end

    test "handles send errors gracefully" do
      config = %Config{
        mode: :short,
        mc_service_url: "http://localhost:4000",
        evidence_dir: nil,
        warm_up_seconds: 1,
        run_seconds: 1,
        sample_interval_ms: 1000,
        event_send_timeout_ms: 10_000,
        cluster_count: 1,
        nodes_per_cluster: 10,
        event_burst_per_second: 2,
        soak_load_interval_seconds: 5,
        poll_cycles: 1
      }

      send_fn = fn _event ->
        {:error, :connection_refused}
      end

      {:ok, samples} = Load.run(50, config, send_fn, sleep_fn: fn _ms -> :ok end)

      # Should have error metrics
      error_metrics = Enum.filter(samples, &String.contains?(&1.metric_name, "error"))
      assert length(error_metrics) > 0
    end

    test "respects timeout constraint" do
      config = %Config{
        mode: :short,
        mc_service_url: "http://localhost:4000",
        evidence_dir: nil,
        warm_up_seconds: 1,
        run_seconds: 1,
        sample_interval_ms: 1000,
        event_send_timeout_ms: 10_000,
        cluster_count: 1,
        nodes_per_cluster: 10,
        event_burst_per_second: 1,
        soak_load_interval_seconds: 5,
        poll_cycles: 1
      }

      send_fn = fn _event -> {:ok, "ack"} end

      start_time = System.monotonic_time(:millisecond)
      {:ok, _samples} = Load.run(50, config, send_fn, sleep_fn: fn _ms -> :ok end)
      elapsed = System.monotonic_time(:millisecond) - start_time

      # Should complete in approximately the requested duration (with some tolerance)
      assert elapsed <= 150  # 50ms + tolerance
    end
  end
end
