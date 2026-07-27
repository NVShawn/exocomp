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
         {:ok, processes} <- process_module.start(config, identity) do
      try do
        execute(config, identity, host, baseline, processes, now_fn.(), opts)
      after
        process_module.stop(processes)
      end
    else
      false -> {:error, :host_profile_incompatible}
      {:error, _reason} = error -> error
    end
  end

  defp execute(config, identity, host, baseline, processes, now, opts) do
    sleep_fn = Keyword.get(opts, :sleep_fn, &Process.sleep/1)

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
             _discarded_workload_samples <- HostSampler.flush(sampler),
             :ok <- sleep_fn.(config.run_seconds * 1_000) do
          host_samples = HostSampler.flush(sampler)
          samples = startup_samples ++ sequential_samples ++ concurrent_samples ++ host_samples
          finish(config, identity, host, baseline, samples, now)
        end
      after
        if Process.alive?(sampler), do: HostSampler.stop(sampler)
      end
    end
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
