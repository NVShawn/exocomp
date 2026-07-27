# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
#
# Generates M5 harness validation evidence demonstrating M5-CRIT-3 through
# M5-CRIT-6 workloads using the FakeLlamaServer and mock process module.
#
# Run from apps/bench with:
#   MIX_ENV=test mix run scripts/gen_m5_harness_evidence.exs <output_dir>
#
# The output_dir receives samples.jsonl and summary.json that prove restart,
# mixed-polling, recovery, and soak-analysis workloads are correctly wired
# and that all 7 correctness gates pass in full mode.

Code.require_file("test/support/fake_llama_server.ex", File.cwd!())

[output_dir | _rest] =
  case System.argv() do
    [dir | _] -> [dir]
    [] -> raise "Usage: mix run scripts/gen_m5_harness_evidence.exs <output_dir>"
  end

alias Bench.Test.FakeLlamaServer
alias Bench.{ArtifactIdentity, Qualification, Qualification.Config, Sample}

defmodule M5HarnessEvidence.TestProcesses do
  @moduledoc false

  def start(_config, _identity) do
    os_pid = System.pid()
    llama_url = :persistent_term.get({__MODULE__, :llama_url})
    {:ok, %{node_pid: os_pid, coordinator_pid: os_pid, llama_pid: os_pid, llama_url: llama_url}}
  end

  def stop(_processes), do: :ok

  def restart_llama(_config, _identity, processes) do
    fake = :persistent_term.get({__MODULE__, :llama_server})
    FakeLlamaServer.set_health_mode(fake, :error_503_once)
    {:ok, processes}
  end

  def diagnostics_available(_processes), do: :ok

  def coordinator_polling(%{mode: :short}, _processes), do: {:ok, []}

  def coordinator_polling(%{mode: :full}, _processes) do
    samples =
      for {name, value} <- [
            {"coordinator.poll.cycle_ms", 42},
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
       sample(:coordinator, "recovery.observation_to_verification_ms", 8),
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
    %Sample{
      timestamp: timestamp,
      source: source,
      metric_name: name,
      value: value,
      unit: "count",
      tags: []
    }
  end
end

# ── Setup ────────────────────────────────────────────────────────────────────

root = Path.join(System.tmp_dir!(), "m5-harness-evidence-#{System.unique_integer([:positive])}")

for dir <- [
      Path.join(root, "node"),
      Path.join(root, "coordinator"),
      Path.join(root, "libraries"),
      Path.join(root, "runtime")
    ],
    do: File.mkdir_p!(dir)

llama = Path.join([root, "runtime", "llama-server"])
model = Path.join(root, "model.gguf")
File.write!(llama, "test-harness-launcher")
File.write!(model, String.duplicate("x", 1024))

for {dir, product} <- [
      {Path.join(root, "node"), "exocomp_node"},
      {Path.join(root, "coordinator"), "exocomp_coordinator"}
    ] do
  identity = %{
    "schema_version" => 1,
    "product" => product,
    "version" => "0.1.0-rc.23",
    "architecture" => Bench.HostProfile.detect().architecture,
    "source_commit" => "3bb10793afa60645b8dcc0cccd43d4e890b72483",
    "elixir_version" => "1.20.2",
    "otp_version" => "28.5.0.3",
    "erts_version" => "16.4.0.3"
  }

  File.write!(Path.join(dir, "build-identity.json"), Jason.encode!(identity))
end

{:ok, model_sha} = ArtifactIdentity.sha256(model)

# Start the FakeLlamaServer (needs a supervision tree; use a temp supervisor).
{:ok, sup} = Supervisor.start_link([], strategy: :one_for_one)
{:ok, fake} = Supervisor.start_child(sup, {FakeLlamaServer, []})

:persistent_term.put({M5HarnessEvidence.TestProcesses, :llama_url}, FakeLlamaServer.base_url(fake))
:persistent_term.put({M5HarnessEvidence.TestProcesses, :llama_server}, fake)

# ── Run full qualification with TestProcesses ─────────────────────────────────

env = %{
  "BENCH_MODE" => "full",
  "LLAMA_SERVER" => llama,
  "LLAMA_LIB_DIR" => Path.join(root, "libraries"),
  "NODE_RELEASE" => Path.join(root, "node"),
  "COORD_RELEASE" => Path.join(root, "coordinator"),
  "MODEL_PATH" => model,
  "MODEL_SHA256" => model_sha,
  "BENCH_EVIDENCE_DIR" => output_dir,
  "BENCH_WARM_UP_SECONDS" => "1",
  "BENCH_RUN_SECONDS" => "7200",
  "BENCH_SAMPLE_INTERVAL_MS" => "10",
  "BENCH_PROPOSAL_COUNT" => "3"
}

{:ok, config} = Config.from_env(env)

IO.puts("Generating M5 harness evidence → #{output_dir}")
IO.puts("Workload: m5-shipped-artifact-full (mock processes, deterministic soak)")

result =
  Qualification.run(config,
    process_module: M5HarnessEvidence.TestProcesses,
    sleep_fn: fn _ms -> :ok end
  )

# ── Cleanup ───────────────────────────────────────────────────────────────────

:persistent_term.erase({M5HarnessEvidence.TestProcesses, :llama_url})
:persistent_term.erase({M5HarnessEvidence.TestProcesses, :llama_server})
Supervisor.stop(sup)
File.rm_rf!(root)

# ── Report ────────────────────────────────────────────────────────────────────

case result do
  {status, summary, evidence_dir} ->
    IO.puts("\nEvidence written to: #{evidence_dir}")
    IO.puts("Gate results:")

    for gate <- summary.gate_results do
      icon = if gate["status"] == "pass", do: "✓", else: "✗"
      IO.puts("  #{icon} #{gate["name"]} (#{gate["metric"]}): #{gate["status"]}")
    end

    total = length(summary.gate_results)
    passed = Enum.count(summary.gate_results, &(&1["status"] == "pass"))
    IO.puts("\n#{passed}/#{total} gates passed")

    if status == :ok do
      IO.puts("All gates PASS — M5-CRIT-3 through M5-CRIT-6 demonstrated.")
    else
      IO.puts(:stderr, "WARNING: Some gates failed — review summary.json for details.")
      System.halt(1)
    end

  {:error, reason} ->
    IO.puts(:stderr, "ERROR: Qualification failed: #{inspect(reason)}")
    System.halt(1)
end
