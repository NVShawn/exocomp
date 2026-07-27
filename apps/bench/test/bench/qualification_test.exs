# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.QualificationTest do
  use ExUnit.Case, async: false

  alias Bench.Qualification
  alias Bench.Qualification.{CLI, Config, Processes}
  alias Bench.Test.FakeLlamaServer

  defmodule TestProcesses do
    @moduledoc false

    def start(_config, _identity) do
      os_pid = System.pid()

      {:ok,
       %{
         node_pid: os_pid,
         coordinator_pid: os_pid,
         llama_pid: os_pid,
         llama_url: :persistent_term.get({__MODULE__, :llama_url})
       }}
    end

    def stop(_processes), do: :ok

    def restart_llama(_config, _identity, processes) do
      fake = :persistent_term.get({__MODULE__, :llama_server})
      Bench.Test.FakeLlamaServer.set_health_mode(fake, :closed)

      spawn(fn ->
        Process.sleep(100)
        Bench.Test.FakeLlamaServer.set_health_mode(fake, :ok)
      end)

      {:ok, processes}
    end

    def diagnostics_available(_processes), do: :ok
    def coordinator_polling(%{mode: :short}, _processes), do: {:ok, []}

    def coordinator_polling(%{mode: :full}, _processes) do
      samples =
        for {name, value} <- [
              {"coordinator.poll.cycle_ms", 10},
              {"coordinator.poll.healthy.count", 1},
              {"coordinator.poll.slow.count", 1},
              {"coordinator.poll.unreachable.count", 1},
              {"coordinator.poll.mailbox.depth", 0}
            ],
            do: sample(:coordinator, name, value)

      {:ok, samples}
    end

    def recovery(%{mode: :short}, _processes), do: {:ok, []}

    def recovery(%{mode: :full}, _processes) do
      {:ok,
       [
         sample(:coordinator, "recovery.observation_to_verification_ms", 10),
         sample(:coordinator, "recovery.safety_pass", 1)
       ]}
    end

    def start_runtime_samplers(_config, _processes), do: :ok
    def runtime_samples(%{mode: :short}, _processes), do: {:ok, []}

    def runtime_samples(%{mode: :full}, _processes) do
      now = System.system_time(:millisecond)

      metrics = [
        {:node, "memory.rss.bytes", 100_000_000},
        {:coordinator, "memory.rss.bytes", 100_000_000},
        {:llama, "memory.rss.bytes", 100_000_000},
        {:node, "file_descriptors.open", 10},
        {:coordinator, "file_descriptors.open", 10},
        {:llama, "file_descriptors.open", 10},
        {:node, "beam.process.count", 100},
        {:coordinator, "beam.process.count", 100},
        {:node, "node.task_history.count", 0},
        {:coordinator, "coordinator.task_history.count", 0},
        {:node, "beam.mailbox.task_registry.depth", 0},
        {:coordinator, "beam.mailbox.goal_store.depth", 0}
      ]

      samples =
        for offset <- 0..3,
            {source, name, value} <- metrics,
            do: sample(source, name, value, now + offset)

      {:ok, samples}
    end

    defp sample(source, name, value, timestamp \\ System.system_time(:millisecond)) do
      %Bench.Sample{
        timestamp: timestamp,
        source: source,
        metric_name: name,
        value: value,
        unit: "count",
        tags: []
      }
    end
  end

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "qualification-run-#{System.unique_integer([:positive])}"
      )

    node = Path.join(root, "node")
    coordinator = Path.join(root, "coordinator")
    libraries = Path.join(root, "libraries")
    runtime = Path.join(root, "runtime")
    Enum.each([node, coordinator, libraries, runtime], &File.mkdir_p!/1)

    llama = Path.join(runtime, "llama-server")
    model = Path.join(root, "model.gguf")
    File.write!(llama, "test launcher")
    File.write!(model, "test model")
    write_identity(node, "exocomp_node")
    write_identity(coordinator, "exocomp_coordinator")
    {:ok, model_sha} = Bench.ArtifactIdentity.sha256(model)

    fake = start_supervised!({FakeLlamaServer, []})
    :persistent_term.put({TestProcesses, :llama_url}, FakeLlamaServer.base_url(fake))
    :persistent_term.put({TestProcesses, :llama_server}, fake)

    on_exit(fn ->
      :persistent_term.erase({TestProcesses, :llama_url})
      :persistent_term.erase({TestProcesses, :llama_server})
      File.rm_rf!(root)
    end)

    env = %{
      "BENCH_MODE" => "short",
      "LLAMA_SERVER" => llama,
      "LLAMA_LIB_DIR" => libraries,
      "NODE_RELEASE" => node,
      "COORD_RELEASE" => coordinator,
      "MODEL_PATH" => model,
      "MODEL_SHA256" => model_sha,
      "BENCH_EVIDENCE_DIR" => Path.join(root, "evidence"),
      "BENCH_WARM_UP_SECONDS" => "1",
      "BENCH_RUN_SECONDS" => "1",
      "BENCH_SAMPLE_INTERVAL_MS" => "10",
      "BENCH_PROPOSAL_COUNT" => "2"
    }

    %{root: root, env: env, fake: fake}
  end

  test "writes raw samples and a complete summary for a deterministic short run", %{env: env} do
    assert {:ok, config} = Config.from_env(env)
    now = ~U[2026-07-26 12:34:56Z]

    result =
      Qualification.run(config,
        process_module: TestProcesses,
        sleep_fn: fn _milliseconds -> :ok end,
        now_fn: fn -> now end
      )

    assert {status, summary, evidence_dir} = result
    assert status in [:ok, :gate_failed]
    assert summary.run_id == "0.1.0-#{current_architecture()}-20260726T123456"
    assert summary.artifact_identity["model_sha256"] == env["MODEL_SHA256"]
    assert summary.host_profile[:architecture] == current_architecture()
    assert File.regular?(Path.join(evidence_dir, "samples.jsonl"))
    assert File.regular?(Path.join(evidence_dir, "summary.json"))
    assert Path.wildcard(Path.join(Path.dirname(evidence_dir), ".evidence.tmp-*")) == []

    decoded = evidence_dir |> Path.join("summary.json") |> File.read!() |> Jason.decode!()
    assert decoded["run_id"] == summary.run_id
    assert decoded["baseline_path"] =~ "/v0.1.0/#{current_architecture()}.toml"
    assert decoded["metrics"]["llama.restart.diagnostics_available"] == 1
    assert decoded["metrics"]["llama.restart.total_ms"] >= 0
    assert decoded["metrics"]["soak.load.iterations"] == 1
  end

  test "refuses to overwrite an existing evidence directory", %{env: env} do
    File.mkdir_p!(env["BENCH_EVIDENCE_DIR"])
    assert {:ok, config} = Config.from_env(env)

    assert {:error, {:evidence_directory_exists, path}} =
             Qualification.run(config,
               process_module: TestProcesses,
               sleep_fn: fn _ -> :ok end,
               now_fn: fn -> ~U[2026-07-26 12:34:56Z] end
             )

    assert path == env["BENCH_EVIDENCE_DIR"]
  end

  test "full orchestration emits passing restart, polling, recovery, and soak gates", %{
    env: env,
    root: root
  } do
    env =
      Map.merge(env, %{
        "BENCH_MODE" => "full",
        "BENCH_RUN_SECONDS" => "7200",
        "BENCH_EVIDENCE_DIR" => Path.join(root, "full-evidence")
      })

    assert {:ok, config} = Config.from_env(env)

    assert {status, summary, _evidence_dir} =
             Qualification.run(config,
               process_module: TestProcesses,
               sleep_fn: fn _milliseconds -> :ok end
             )

    assert status in [:ok, :gate_failed]

    correctness =
      Enum.filter(summary.gate_results, fn result ->
        result["direction"] in ["equals", "at_least", "at_most"]
      end)

    assert length(correctness) == 7
    assert Enum.all?(correctness, &(&1["status"] == "pass"))
    assert summary.metrics["soak.required_metrics_present"] == 1
    assert summary.metrics["soak.pass"] == 1
  end

  # Keep a watchdog below the 120-second production default so a regression
  # that ignores the configured 20 ms deadline still fails promptly. Allow
  # enough time for one-time OTP code loading under full-system CPU emulation;
  # that startup cost is not the behavior this test measures.
  @tag timeout: 30_000
  test "uses the configured inference timeout for shipped workload requests", %{
    env: env,
    fake: fake
  } do
    FakeLlamaServer.set_completions_mode(fake, :timeout)

    env =
      Map.put(env, "BENCH_INFERENCE_TIMEOUT_MS", "20")

    assert {:ok, config} = Config.from_env(env)

    assert {:error, {:workload_failed, "llama.sequential", details}} =
             Qualification.run(config,
               process_module: TestProcesses,
               sleep_fn: fn _ -> :ok end
             )

    assert details.expected == 2
    assert details.successes == 0
    assert details.errors == 2
  end

  test "process cleanup is idempotent for an empty owned set" do
    processes = %Processes{
      node_pid: 1,
      coordinator_pid: 1,
      llama_pid: 1,
      llama_url: "http://127.0.0.1:1",
      ports: [],
      services_started: [],
      temporary_paths: []
    }

    assert :ok = Processes.stop(processes)
    assert :ok = Processes.stop(processes)
    assert :ok = Processes.diagnostics_available(%{processes | node_pid: System.pid()})

    assert {:error, :llama_process_not_owned} =
             Processes.restart_llama(nil, nil, processes)
  end

  test "short process startup rejects a release without its shipped executable", %{env: env} do
    assert {:ok, config} = Config.from_env(env)

    identity = %Bench.ArtifactIdentity{
      artifact_version: "0.1.0",
      architecture: current_architecture(),
      source_commit: String.duplicate("a", 40),
      elixir_version: "1.20.2",
      otp_version: "28.5.0.3",
      erts_version: "16.2",
      node: %{},
      coordinator: %{},
      llama_server_path: env["LLAMA_SERVER"],
      llama_server_sha256: String.duplicate("b", 64),
      llama_launcher_sha256: String.duplicate("b", 64),
      model_path: env["MODEL_PATH"],
      model_sha256: env["MODEL_SHA256"]
    }

    assert {:error, {:release_executable_not_found, path}} = Processes.start(config, identity)
    assert String.ends_with?(path, "/bin/exocomp_coordinator")
  end

  test "short startup rolls back an executable that is not from the supplied release", %{
    env: env
  } do
    executable = Path.join([env["COORD_RELEASE"], "bin", "exocomp_coordinator"])
    File.mkdir_p!(Path.dirname(executable))

    File.write!(
      executable,
      """
      #!/bin/sh
      start_time="$(cut -d ' ' -f 22 "/proc/$$/stat")"
      printf '%s %s' "$$" "$start_time" > "${BENCH_READY_FILE}.pid"
      : > "$BENCH_READY_FILE"
      exec sleep 60
      """
    )

    File.chmod!(executable, 0o755)
    before = MapSet.new(Path.wildcard(Path.join(System.tmp_dir!(), "exocomp-m5-*.ready.pid")))
    assert {:ok, config} = Config.from_env(env)

    identity = %Bench.ArtifactIdentity{
      artifact_version: "0.1.0",
      architecture: current_architecture(),
      source_commit: String.duplicate("a", 40),
      elixir_version: "1.20.2",
      otp_version: "28.5.0.3",
      erts_version: "16.2",
      node: %{},
      coordinator: %{},
      llama_server_path: env["LLAMA_SERVER"],
      llama_server_sha256: String.duplicate("b", 64),
      llama_launcher_sha256: String.duplicate("b", 64),
      model_path: env["MODEL_PATH"],
      model_sha256: env["MODEL_SHA256"]
    }

    assert {:error, {:artifact_process_mismatch, :coordinator, _, _}} =
             Processes.start(config, identity)

    [pid_file] =
      Path.wildcard(Path.join(System.tmp_dir!(), "exocomp-m5-*.ready.pid"))
      |> MapSet.new()
      |> MapSet.difference(before)
      |> MapSet.to_list()

    [pid, start_time] = pid_file |> File.read!() |> String.split()
    refute same_process_running?(pid, start_time)
    File.rm!(pid_file)
  end

  test "CLI formats exact baseline, identity, checksum, and environment failures" do
    assert CLI.format_error({:baseline_not_found, "0.1.0", "arm64", "/baseline"}) ==
             "M5 gate: no baseline found for artifact v0.1.0 on arm64"

    assert CLI.format_error({:build_identity_not_found, "/node"}) ==
             "M5 gate: build-identity.json not found in /node"

    assert CLI.format_error({:model_sha256_mismatch, "expected", "actual"}) =~
             "MODEL_SHA256 mismatch"

    assert CLI.format_error({:missing_environment, ["MODEL_PATH"]}) =~ "MODEL_PATH"
  end

  defp write_identity(directory, product) do
    identity = %{
      "schema_version" => 1,
      "product" => product,
      "version" => "0.1.0",
      "architecture" => current_architecture(),
      "source_commit" => String.duplicate("a", 40),
      "elixir_version" => "1.20.2",
      "otp_version" => "28.5.0.3",
      "erts_version" => "16.2"
    }

    File.write!(Path.join(directory, "build-identity.json"), Jason.encode!(identity))
  end

  defp same_process_running?(pid, expected_start_time) do
    with {:ok, stat} <- File.read("/proc/#{pid}/stat"),
         [_, fields] <- Regex.run(~r/^\d+ \(.*\) (.+)$/, String.trim(stat)),
         fields <- String.split(fields) do
      state = Enum.at(fields, 0)
      start_time = Enum.at(fields, 19)
      start_time == expected_start_time and state != "Z"
    else
      _ -> false
    end
  end

  defp current_architecture, do: Bench.HostProfile.detect().architecture
end
