# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Qualification do
  @moduledoc """
  Executes the shipped-artifact M5 workload and writes raw gate evidence.
  """

  alias Bench.{
    ArtifactIdentity,
    Baseline,
    HostProfile,
    HostSampler,
    Qualification.Config,
    Qualification.Processes,
    Report.Summary,
    Run,
    Workload.LlamaInference
  }

  alias Bench.Analysis.Soak, as: SoakAnalysis
  alias Bench.Workload.Soak, as: SoakWorkload

  @doc """
  Runs one configured qualification.

  The `:process_module`, `:sleep_fn`, and `:now_fn` options are dependency
  seams for deterministic harness tests.
  """
  @spec run(Config.t(), keyword()) ::
          {:ok, Summary.t(), Path.t()}
          | {:gate_failed, Summary.t(), Path.t()}
          | {:error, term()}
  def run(%Config{} = config, opts \\ []) do
    process_module = Keyword.get(opts, :process_module, Processes)
    now_fn = Keyword.get(opts, :now_fn, &DateTime.utc_now/0)

    with {:ok, identity} <-
           ArtifactIdentity.capture(
             config.node_release,
             config.coordinator_release,
             config.llama_server,
             config.model_path,
             config.model_sha256
           ),
         host = HostProfile.detect(),
         :ok <- host_matches_artifact(host, identity),
         {:ok, baseline} <- Baseline.select(identity.artifact_version, identity.architecture),
         {:ok, reference_host} <- HostProfile.load(baseline.host_profile),
         true <- HostProfile.compatible?(host, reference_host),
         {:ok, processes} <- process_module.start(config, identity),
         {:ok, process_holder} <- Agent.start(fn -> processes end) do
      try do
        execute(
          config,
          identity,
          host,
          baseline,
          process_holder,
          process_module,
          now_fn.(),
          opts
        )
      after
        process_module.stop(Agent.get(process_holder, & &1))
        Agent.stop(process_holder)
      end
    else
      false -> {:error, :host_profile_incompatible}
      {:error, _reason} = error -> error
    end
  end

  defp execute(
         config,
         identity,
         host,
         baseline,
         process_holder,
         process_module,
         now,
         opts
       ) do
    sleep_fn = Keyword.get(opts, :sleep_fn, &Process.sleep/1)
    processes = Agent.get(process_holder, & &1)

    with {:ok, sampler} <-
           HostSampler.start_link(
             node: processes.node_pid,
             coordinator: processes.coordinator_pid,
             llama: processes.llama_pid,
             interval: config.sample_interval_ms
           ) do
      try do
        with {:ok, startup_samples} <-
               LlamaInference.measure_startup(
                 processes.llama_url,
                 readiness_timeout_ms: 120_000
               ),
             :ok <- validate_startup(startup_samples),
             {:ok, _warm_up_samples} <-
               LlamaInference.measure_sequential(
                 processes.llama_url,
                 proposal_count: 1,
                 timeout_ms: config.inference_timeout_ms
               ),
             :ok <- sleep_fn.(config.warm_up_seconds * 1_000),
             _discarded_warm_up <- HostSampler.flush(sampler),
             {:ok, sequential_samples} <-
               LlamaInference.measure_sequential(
                 processes.llama_url,
                 proposal_count: config.proposal_count,
                 timeout_ms: config.inference_timeout_ms
               ),
             :ok <- validate_sequential(sequential_samples, config.proposal_count),
             {:ok, concurrent_samples} <-
               LlamaInference.measure_concurrent(
                 processes.llama_url,
                 concurrency_levels: config.concurrency_levels,
                 timeout_ms: config.inference_timeout_ms
               ),
             :ok <- validate_concurrent(concurrent_samples),
             {:ok, restart_samples} <-
               measure_restart(
                 config,
                 identity,
                 process_holder,
                 process_module,
                 sampler
               ),
             {:ok, polling_samples} <-
               process_module.coordinator_polling(
                 config,
                 Agent.get(process_holder, & &1)
               ),
             {:ok, recovery_samples, recovery_load_samples} <-
               measure_recovery_under_load(
                 config,
                 Agent.get(process_holder, & &1),
                 process_module
               ),
             workload_host_samples = HostSampler.flush(sampler),
             :ok <-
               process_module.start_runtime_samplers(
                 config,
                 Agent.get(process_holder, & &1)
               ),
             soak_started_at = System.system_time(:millisecond),
             {:ok, soak_load_samples} <-
               run_soak(config, Agent.get(process_holder, & &1), sleep_fn),
             host_samples = HostSampler.flush(sampler),
             {:ok, runtime_samples} <-
               process_module.runtime_samples(config, Agent.get(process_holder, & &1)),
             {:ok, soak_analysis_samples} <-
               analyze_soak(
                 config,
                 host_samples ++ runtime_samples,
                 soak_started_at
               ) do
          samples =
            startup_samples ++
              sequential_samples ++
              concurrent_samples ++
              restart_samples ++
              polling_samples ++
              recovery_samples ++
              recovery_load_samples ++
              soak_load_samples ++
              workload_host_samples ++
              host_samples ++ runtime_samples ++ soak_analysis_samples

          finish(config, identity, host, baseline, samples, now)
        end
      after
        if Process.alive?(sampler), do: HostSampler.stop(sampler)
      end
    end
  end

  defp measure_restart(config, identity, process_holder, process_module, sampler) do
    processes = Agent.get(process_holder, & &1)

    crash_fn = fn ->
      current = Agent.get(process_holder, & &1)

      with {:ok, restarted} <- process_module.restart_llama(config, identity, current),
           :ok <- HostSampler.set_target(sampler, :llama, restarted.llama_pid) do
        Agent.update(process_holder, fn _old -> restarted end)
        :ok
      end
    end

    diagnostic_fn = fn ->
      process_holder
      |> Agent.get(& &1)
      |> process_module.diagnostics_available()
    end

    LlamaInference.measure_restart(processes.llama_url, crash_fn,
      timeout_ms: config.inference_timeout_ms,
      restart_timeout_ms: config.restart_timeout_ms,
      diagnostic_fn: diagnostic_fn
    )
  end

  defp measure_recovery_under_load(config, processes, process_module) do
    load =
      Task.async(fn ->
        LlamaInference.measure_concurrent(processes.llama_url,
          concurrency_levels: [List.last(config.concurrency_levels)],
          timeout_ms: config.inference_timeout_ms
        )
      end)

    try do
      with {:ok, recovery_samples} <- process_module.recovery(config, processes),
           {:ok, load_samples} <-
             Task.await(
               load,
               config.inference_timeout_ms * List.last(config.concurrency_levels) + 5_000
             ) do
        {:ok, recovery_samples, load_samples}
      end
    after
      if Process.alive?(load.pid), do: Task.shutdown(load, :brutal_kill)
    end
  end

  defp run_soak(config, processes, sleep_fn) do
    workload_fn = fn ->
      LlamaInference.measure_sequential(processes.llama_url,
        proposal_count: 1,
        timeout_ms: config.inference_timeout_ms
      )
    end

    SoakWorkload.run(
      config.run_seconds * 1_000,
      config.soak_load_interval_seconds * 1_000,
      workload_fn,
      sleep_fn: sleep_fn
    )
  end

  defp analyze_soak(%Config{mode: :short}, _samples, _started_at), do: {:ok, []}

  defp analyze_soak(%Config{mode: :full}, samples, started_at) do
    SoakAnalysis.analyze(samples, start_timestamp: started_at)
  end

  defp finish(config, identity, host, baseline, samples, now) do
    run_id = run_id(identity.artifact_version, identity.architecture, now)
    evidence_dir = config.evidence_dir || Path.join(["_bench", "evidence", run_id])

    summary =
      Summary.build(samples, baseline, identity, host,
        run_id: run_id,
        workload: "m5-shipped-artifact-#{config.mode}",
        config: Config.to_map(config)
      )

    with :ok <- write_evidence(evidence_dir, samples, summary, identity, host, baseline) do
      if Summary.pass?(summary) do
        {:ok, summary, evidence_dir}
      else
        {:gate_failed, summary, evidence_dir}
      end
    end
  end

  defp write_evidence(evidence_dir, samples, summary, identity, host, baseline) do
    if File.exists?(evidence_dir) do
      {:error, {:evidence_directory_exists, evidence_dir}}
    else
      staging_dir =
        Path.join(
          Path.dirname(evidence_dir),
          ".#{Path.basename(evidence_dir)}.tmp-#{System.unique_integer([:positive, :monotonic])}"
        )

      samples =
        Enum.sort_by(samples, fn sample ->
          {sample.timestamp, Atom.to_string(sample.source), sample.metric_name}
        end)

      run =
        Run.new(
          build_metadata: ArtifactIdentity.to_map(identity),
          host_profile: Map.from_struct(host),
          model_version: identity.model_sha256,
          workload_name: summary.workload,
          config_ref: baseline.path,
          samples: samples
        )

      samples_path = Path.join(staging_dir, "samples.jsonl")
      summary_path = Path.join(staging_dir, "summary.json")

      with :ok <- File.mkdir_p(Path.dirname(evidence_dir)),
           :ok <- File.mkdir(staging_dir),
           :ok <- Run.write_jsonl(run, samples_path),
           {:ok, summary_json} <- Summary.to_json(summary),
           :ok <- File.write(summary_path, summary_json <> "\n"),
           :ok <- File.rename(staging_dir, evidence_dir) do
        :ok
      else
        {:error, reason} ->
          File.rm_rf(staging_dir)
          {:error, {:evidence_write_failed, evidence_dir, reason}}
      end
    end
  end

  defp host_matches_artifact(host, identity) do
    if host.architecture == identity.architecture do
      :ok
    else
      {:error, {:artifact_host_architecture_mismatch, identity.architecture, host.architecture}}
    end
  end

  defp validate_startup(samples) do
    if sample_value(samples, "llama.startup_timeout") == 1 do
      {:error, {:workload_failed, "llama.startup_timeout"}}
    else
      :ok
    end
  end

  defp validate_sequential(samples, expected) do
    successes = sample_value(samples, "llama.sequential.success_count")
    errors = sample_value(samples, "llama.sequential.error_count")

    if successes == expected and errors == 0 do
      :ok
    else
      {:error,
       {:workload_failed, "llama.sequential",
        %{expected: expected, successes: successes, errors: errors}}}
    end
  end

  defp validate_concurrent(samples) do
    errors =
      samples
      |> Enum.filter(&String.ends_with?(&1.metric_name, ".error_count"))
      |> Enum.map(& &1.value)

    if errors != [] and Enum.all?(errors, &(&1 == 0)) do
      :ok
    else
      {:error, {:workload_failed, "llama.concurrent", errors}}
    end
  end

  defp sample_value(samples, name) do
    case Enum.find(samples, &(&1.metric_name == name)) do
      nil -> nil
      sample -> sample.value
    end
  end

  defp run_id(version, architecture, %DateTime{} = now) do
    timestamp =
      now
      |> DateTime.truncate(:second)
      |> Calendar.strftime("%Y%m%dT%H%M%S")

    "#{String.trim_leading(version, "v")}-#{architecture}-#{timestamp}"
  end
end
