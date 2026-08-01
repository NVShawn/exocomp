# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Qualification.MissionControl.ConfigTest do
  use ExUnit.Case

  alias Bench.Qualification.MissionControl.Config

  describe "from_env/1" do
    test "parses valid short configuration" do
      env = %{
        "MC_SERVICE_URL" => "http://localhost:4000",
        "BENCH_MODE" => "short"
      }

      {:ok, config} = Config.from_env(env)

      assert config.mode == :short
      assert config.mc_service_url == "http://localhost:4000"
      assert config.cluster_count == 100
      assert config.nodes_per_cluster == 100
      assert config.event_burst_per_second == 100
      assert config.run_seconds == 30
    end

    test "parses valid full configuration" do
      env = %{
        "MC_SERVICE_URL" => "https://mission-control.example.com",
        "BENCH_MODE" => "full",
        "BENCH_RUN_SECONDS" => "14400"
      }

      {:ok, config} = Config.from_env(env)

      assert config.mode == :full
      assert config.mc_service_url == "https://mission-control.example.com"
      assert config.run_seconds == 14_400
    end

    test "rejects missing MC_SERVICE_URL" do
      env = %{"BENCH_MODE" => "short"}

      {:error, {:missing_environment, names}} = Config.from_env(env)

      assert "MC_SERVICE_URL" in names
    end

    test "rejects invalid MC_SERVICE_URL" do
      env = %{
        "MC_SERVICE_URL" => "not-a-url",
        "BENCH_MODE" => "short"
      }

      {:error, {:invalid_mc_service_url, _url}} = Config.from_env(env)
    end

    test "enforces full-mode minimum duration" do
      env = %{
        "MC_SERVICE_URL" => "http://localhost:4000",
        "BENCH_MODE" => "full",
        "BENCH_RUN_SECONDS" => "60"
      }

      {:error, {:full_run_too_short, 60, _minimum}} = Config.from_env(env)
    end

    test "accepts valid positive integer overrides" do
      env = %{
        "MC_SERVICE_URL" => "http://localhost:4000",
        "BENCH_CLUSTER_COUNT" => "50",
        "BENCH_EVENT_BURST_PER_SECOND" => "200",
        "BENCH_SAMPLE_INTERVAL_MS" => "2000"
      }

      {:ok, config} = Config.from_env(env)

      assert config.cluster_count == 50
      assert config.event_burst_per_second == 200
      assert config.sample_interval_ms == 2_000
    end

    test "rejects invalid positive integers" do
      env = %{
        "MC_SERVICE_URL" => "http://localhost:4000",
        "BENCH_CLUSTER_COUNT" => "not-a-number"
      }

      {:error, {:invalid_positive_integer, "BENCH_CLUSTER_COUNT", _}} = Config.from_env(env)
    end

    test "rejects zero or negative integers" do
      env = %{
        "MC_SERVICE_URL" => "http://localhost:4000",
        "BENCH_EVENT_BURST_PER_SECOND" => "0"
      }

      {:error, {:invalid_positive_integer, "BENCH_EVENT_BURST_PER_SECOND", _}} = Config.from_env(env)
    end
  end

  describe "to_map/1" do
    test "converts config to JSON-ready map" do
      env = %{
        "MC_SERVICE_URL" => "http://localhost:4000",
        "BENCH_MODE" => "short"
      }

      {:ok, config} = Config.from_env(env)
      map = Config.to_map(config)

      assert map["mode"] == "short"
      assert map["mc_service_url"] == "http://localhost:4000"
      assert map["cluster_count"] == 100
      assert is_integer(map["run_seconds"])
    end
  end
end
