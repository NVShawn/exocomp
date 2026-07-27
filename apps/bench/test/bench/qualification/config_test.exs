# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Qualification.ConfigTest do
  use ExUnit.Case, async: true

  alias Bench.Qualification.Config

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "qualification-config-#{System.unique_integer([:positive])}"
      )

    node = Path.join(root, "node")
    coordinator = Path.join(root, "coordinator")
    libraries = Path.join(root, "libraries")
    Enum.each([node, coordinator, libraries], &File.mkdir_p!/1)
    llama = Path.join(root, "llama-server")
    model = Path.join(root, "model.gguf")
    File.write!(llama, "llama")
    File.write!(model, "model")
    on_exit(fn -> File.rm_rf!(root) end)

    env = %{
      "BENCH_MODE" => "short",
      "LLAMA_SERVER" => llama,
      "LLAMA_LIB_DIR" => libraries,
      "NODE_RELEASE" => node,
      "COORD_RELEASE" => coordinator,
      "MODEL_PATH" => model,
      "MODEL_SHA256" => String.duplicate("a", 64)
    }

    %{root: root, env: env}
  end

  test "parses short shipped-artifact configuration with bounded defaults", %{env: env} do
    assert {:ok, config} = Config.from_env(env)
    assert config.mode == :short
    assert config.run_seconds == 5
    assert config.warm_up_seconds == 2
    assert config.inference_timeout_ms == 120_000
    assert config.restart_timeout_ms == 120_000
    assert config.concurrency_levels == [1, 2]
    assert config.soak_load_interval_seconds == 5
    assert config.poll_cycles == 2
    assert config.poll_concurrency == 3
    assert Config.to_map(config)["mode"] == "short"
  end

  test "full mode enforces the two-hour soak qualification minimum", %{env: env} do
    full = Map.put(env, "BENCH_MODE", "full")
    assert {:ok, config} = Config.from_env(full)
    assert config.run_seconds == 7_200
    assert config.concurrency_levels == [1, 2, 4]

    too_short = Map.put(full, "BENCH_RUN_SECONDS", "7199")

    assert {:error, {:full_run_too_short, 7_199, 7_200}} =
             Config.from_env(too_short)
  end

  test "captures explicit evidence and sampling configuration", %{root: root, env: env} do
    evidence = Path.join(root, "evidence")

    configured =
      Map.merge(env, %{
        "BENCH_EVIDENCE_DIR" => evidence,
        "BENCH_LLAMA_PORT" => "18081",
        "BENCH_SAMPLE_INTERVAL_MS" => "250",
        "BENCH_INFERENCE_TIMEOUT_MS" => "600000",
        "BENCH_RESTART_TIMEOUT_MS" => "240000",
        "BENCH_PROPOSAL_COUNT" => "7",
        "BENCH_SOAK_LOAD_INTERVAL_SECONDS" => "30",
        "BENCH_POLL_CYCLES" => "8",
        "BENCH_POLL_CONCURRENCY" => "4"
      })

    assert {:ok, config} = Config.from_env(configured)
    assert config.evidence_dir == evidence
    assert config.llama_port == 18_081
    assert config.sample_interval_ms == 250
    assert config.inference_timeout_ms == 600_000
    assert config.restart_timeout_ms == 240_000
    assert config.proposal_count == 7
    assert config.soak_load_interval_seconds == 30
    assert config.poll_cycles == 8
    assert config.poll_concurrency == 4
  end

  test "rejects an invalid inference timeout", %{env: env} do
    assert {:error, {:invalid_positive_integer, "BENCH_INFERENCE_TIMEOUT_MS", "0"}} =
             env
             |> Map.put("BENCH_INFERENCE_TIMEOUT_MS", "0")
             |> Config.from_env()
  end

  test "reports all missing required environment variables", %{env: env} do
    invalid = env |> Map.delete("LLAMA_SERVER") |> Map.delete("MODEL_PATH")

    assert {:error, {:missing_environment, missing}} = Config.from_env(invalid)
    assert missing == ["LLAMA_SERVER", "MODEL_PATH"]
  end

  test "rejects relative artifact paths and nonexistent directories", %{env: env} do
    assert {:error, {:path_not_absolute, "llama-server"}} =
             env
             |> Map.put("LLAMA_SERVER", "llama-server")
             |> Config.from_env()

    assert {:error, {:directory_not_found, "/not/present"}} =
             env
             |> Map.put("LLAMA_LIB_DIR", "/not/present")
             |> Config.from_env()
  end
end
