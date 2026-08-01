# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Qualification.MissionControl.Config do
  @moduledoc """
  Configuration for Mission Control scale and soak qualification.

  The MC qualification targets 100 persistent clusters, 10,000 current node
  records, and a burst of 100 events per second. It measures committed-event-
  to-LiveView p95 latency and event loss, and runs a four-hour soak to verify
  stable bounds on connection count, BEAM processes/mailboxes, memory, file
  descriptors, database pool/queue, outbox depth, and webhook/retention workers.
  """

  @required_env ~w(MC_SERVICE_URL)
  @full_minimum_seconds 14_400  # 4 hours

  @enforce_keys [
    :mode,
    :mc_service_url,
    :evidence_dir,
    :warm_up_seconds,
    :run_seconds,
    :sample_interval_ms,
    :event_send_timeout_ms,
    :cluster_count,
    :nodes_per_cluster,
    :event_burst_per_second,
    :soak_load_interval_seconds,
    :poll_cycles
  ]
  defstruct @enforce_keys

  @type mode :: :short | :full
  @type t :: %__MODULE__{}

  @doc """
  Parses Mission Control qualification configuration from environment.

  `BENCH_MODE` is `short` or `full`. Full runs enforce the M7 four-hour
  minimum soak even when overridden.
  """
  @spec from_env(map()) :: {:ok, t()} | {:error, term()}
  def from_env(env \\ System.get_env()) when is_map(env) do
    with :ok <- required_env(env),
         {:ok, mode} <- parse_mode(Map.get(env, "BENCH_MODE", "short")),
         {:ok, mc_service_url} <- mc_service_url(env["MC_SERVICE_URL"]),
         {:ok, warm_up_seconds} <-
           positive_integer(env, "BENCH_WARM_UP_SECONDS", default_warm_up(mode)),
         {:ok, run_seconds} <-
           positive_integer(env, "BENCH_RUN_SECONDS", default_run_seconds(mode)),
         :ok <- minimum_run_duration(mode, run_seconds),
         {:ok, sample_interval_ms} <-
           positive_integer(env, "BENCH_SAMPLE_INTERVAL_MS", 1_000),
         {:ok, event_send_timeout_ms} <-
           positive_integer(env, "BENCH_EVENT_SEND_TIMEOUT_MS", 10_000),
         {:ok, cluster_count} <-
           positive_integer(env, "BENCH_CLUSTER_COUNT", 100),
         {:ok, nodes_per_cluster} <-
           positive_integer(env, "BENCH_NODES_PER_CLUSTER", 100),
         {:ok, event_burst_per_second} <-
           positive_integer(env, "BENCH_EVENT_BURST_PER_SECOND", 100),
         {:ok, soak_load_interval_seconds} <-
           positive_integer(
             env,
             "BENCH_SOAK_LOAD_INTERVAL_SECONDS",
             default_soak_load_interval(mode)
           ),
         {:ok, poll_cycles} <-
           positive_integer(env, "BENCH_POLL_CYCLES", default_poll_cycles(mode)),
         {:ok, evidence_dir} <- evidence_dir(env) do
      {:ok,
       %__MODULE__{
         mode: mode,
         mc_service_url: mc_service_url,
         evidence_dir: evidence_dir,
         warm_up_seconds: warm_up_seconds,
         run_seconds: run_seconds,
         sample_interval_ms: sample_interval_ms,
         event_send_timeout_ms: event_send_timeout_ms,
         cluster_count: cluster_count,
         nodes_per_cluster: nodes_per_cluster,
         event_burst_per_second: event_burst_per_second,
         soak_load_interval_seconds: soak_load_interval_seconds,
         poll_cycles: poll_cycles
       }}
    end
  end

  @doc "Returns a JSON-ready configuration map."
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = config) do
    config
    |> Map.from_struct()
    |> Map.new(fn
      {:mode, value} -> {"mode", Atom.to_string(value)}
      {key, value} -> {Atom.to_string(key), value}
    end)
  end

  defp required_env(env) do
    missing =
      Enum.filter(@required_env, fn name ->
        value = Map.get(env, name)
        not (is_binary(value) and value != "")
      end)

    case missing do
      [] -> :ok
      names -> {:error, {:missing_environment, names}}
    end
  end

  defp parse_mode("short"), do: {:ok, :short}
  defp parse_mode("full"), do: {:ok, :full}
  defp parse_mode(value), do: {:error, {:invalid_mode, value}}

  defp mc_service_url(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: scheme} when scheme in ["http", "https"] -> {:ok, url}
      _ -> {:error, {:invalid_mc_service_url, url}}
    end
  end

  defp mc_service_url(_), do: {:error, {:invalid_mc_service_url, nil}}

  defp positive_integer(env, name, default) do
    case Map.get(env, name) do
      nil ->
        {:ok, default}

      value when is_integer(value) and value > 0 ->
        {:ok, value}

      value when is_binary(value) ->
        case Integer.parse(value) do
          {parsed, ""} when parsed > 0 -> {:ok, parsed}
          _ -> {:error, {:invalid_positive_integer, name, value}}
        end

      value ->
        {:error, {:invalid_positive_integer, name, value}}
    end
  end

  defp evidence_dir(env) do
    case Map.get(env, "BENCH_EVIDENCE_DIR") do
      nil -> {:ok, nil}
      "" -> {:error, {:invalid_evidence_dir, ""}}
      path when is_binary(path) -> {:ok, Path.expand(path)}
      value -> {:error, {:invalid_evidence_dir, value}}
    end
  end

  defp minimum_run_duration(:short, _seconds), do: :ok
  defp minimum_run_duration(:full, seconds) when seconds >= @full_minimum_seconds, do: :ok

  defp minimum_run_duration(:full, seconds),
    do: {:error, {:full_run_too_short, seconds, @full_minimum_seconds}}

  defp default_warm_up(:short), do: 5
  defp default_warm_up(:full), do: 60

  defp default_run_seconds(:short), do: 30
  defp default_run_seconds(:full), do: @full_minimum_seconds

  defp default_soak_load_interval(:short), do: 5
  defp default_soak_load_interval(:full), do: 60

  defp default_poll_cycles(:short), do: 2
  defp default_poll_cycles(:full), do: 20
end
