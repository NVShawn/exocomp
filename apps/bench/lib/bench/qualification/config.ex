# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Qualification.Config do
  @moduledoc """
  Strict environment-backed configuration for shipped-artifact qualification.
  """

  @required_env ~w(
    LLAMA_SERVER LLAMA_LIB_DIR NODE_RELEASE COORD_RELEASE MODEL_PATH MODEL_SHA256
  )
  @full_minimum_seconds 1_800

  @enforce_keys [
    :mode,
    :llama_server,
    :llama_lib_dir,
    :node_release,
    :coordinator_release,
    :model_path,
    :model_sha256,
    :evidence_dir,
    :llama_port,
    :warm_up_seconds,
    :run_seconds,
    :sample_interval_ms,
    :inference_timeout_ms,
    :proposal_count,
    :concurrency_levels
  ]
  defstruct @enforce_keys

  @type mode :: :short | :full
  @type t :: %__MODULE__{}

  @doc """
  Parses qualification configuration from an environment-shaped map.

  `BENCH_MODE` is `short` or `full`. Full runs enforce the M5 minimum
  30-minute steady-idle measurement even when a duration override is present.
  """
  @spec from_env(map()) :: {:ok, t()} | {:error, term()}
  def from_env(env \\ System.get_env()) when is_map(env) do
    with :ok <- required_env(env),
         {:ok, mode} <- parse_mode(Map.get(env, "BENCH_MODE", "short")),
         :ok <- absolute_path(:llama_server, env["LLAMA_SERVER"]),
         :ok <- absolute_path(:model_path, env["MODEL_PATH"]),
         :ok <- directory(:llama_lib_dir, env["LLAMA_LIB_DIR"]),
         :ok <- directory(:node_release, env["NODE_RELEASE"]),
         :ok <- directory(:coordinator_release, env["COORD_RELEASE"]),
         {:ok, llama_port} <- positive_integer(env, "BENCH_LLAMA_PORT", 18_080),
         {:ok, warm_up_seconds} <-
           positive_integer(env, "BENCH_WARM_UP_SECONDS", default_warm_up(mode)),
         {:ok, run_seconds} <-
           positive_integer(env, "BENCH_RUN_SECONDS", default_run_seconds(mode)),
         :ok <- minimum_run_duration(mode, run_seconds),
         {:ok, sample_interval_ms} <-
           positive_integer(env, "BENCH_SAMPLE_INTERVAL_MS", 1_000),
         {:ok, inference_timeout_ms} <-
           positive_integer(env, "BENCH_INFERENCE_TIMEOUT_MS", 120_000),
         {:ok, proposal_count} <-
           positive_integer(env, "BENCH_PROPOSAL_COUNT", default_proposals(mode)),
         {:ok, evidence_dir} <- evidence_dir(env) do
      {:ok,
       %__MODULE__{
         mode: mode,
         llama_server: env["LLAMA_SERVER"],
         llama_lib_dir: env["LLAMA_LIB_DIR"],
         node_release: env["NODE_RELEASE"],
         coordinator_release: env["COORD_RELEASE"],
         model_path: env["MODEL_PATH"],
         model_sha256: String.downcase(env["MODEL_SHA256"]),
         evidence_dir: evidence_dir,
         llama_port: llama_port,
         warm_up_seconds: warm_up_seconds,
         run_seconds: run_seconds,
         sample_interval_ms: sample_interval_ms,
         inference_timeout_ms: inference_timeout_ms,
         proposal_count: proposal_count,
         concurrency_levels: default_concurrency(mode)
       }}
    end
  end

  @doc "Returns a JSON-ready configuration map without redundant path aliases."
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

  defp absolute_path(_field, path) when is_binary(path) do
    if Path.type(path) == :absolute do
      :ok
    else
      {:error, {:path_not_absolute, path}}
    end
  end

  defp absolute_path(_field, path), do: {:error, {:path_not_absolute, path}}

  defp directory(_field, path) when is_binary(path) do
    if File.dir?(path), do: :ok, else: {:error, {:directory_not_found, path}}
  end

  defp directory(_field, path), do: {:error, {:directory_not_found, path}}

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

  defp default_warm_up(:short), do: 2
  defp default_warm_up(:full), do: 30
  defp default_run_seconds(:short), do: 5
  defp default_run_seconds(:full), do: @full_minimum_seconds
  defp default_proposals(:short), do: 3
  defp default_proposals(:full), do: 20
  defp default_concurrency(:short), do: [1, 2]
  defp default_concurrency(:full), do: [1, 2, 4]
end
