# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Report.Summary do
  @moduledoc """
  Summary report builder and regression gate evaluator.

  Control-plane gates combine only node and coordinator process samples.
  llama.cpp observations are retained under separate metrics and never enter
  the BEAM CPU or RAM budget.
  """

  alias Bench.{ArtifactIdentity, Baseline, HostProfile, Sample}

  defstruct [
    :run_id,
    :host_profile,
    :workload,
    :metrics,
    :artifact_identity,
    :baseline_path,
    :baseline_reference,
    :config,
    gate_results: []
  ]

  @typedoc "Aggregated benchmark result and hard-gate outcomes."
  @type t :: %__MODULE__{}

  @doc """
  Aggregates samples and evaluates every hard gate in `baseline`.

  A node or coordinator `:missing` sample makes both relevant combined metrics
  unavailable, so a process that exits cannot be hidden by the surviving
  component's observations.
  """
  @spec build(
          [Sample.t()],
          Baseline.t(),
          ArtifactIdentity.t() | map(),
          HostProfile.t() | map(),
          keyword()
        ) :: t()
  def build(samples, %Baseline{} = baseline, artifact_identity, host_profile, opts \\ [])
      when is_list(samples) do
    host = mapify(host_profile)
    artifact = mapify(artifact_identity)
    metrics = aggregate(samples, host)

    %__MODULE__{
      run_id: Keyword.get(opts, :run_id),
      host_profile: host,
      workload: Keyword.get(opts, :workload, "m5-shipped-artifact"),
      metrics: metrics,
      artifact_identity: artifact,
      baseline_path: baseline.path,
      baseline_reference: baseline.reference,
      config: Keyword.get(opts, :config, %{}),
      gate_results: evaluate(metrics, baseline.gates)
    }
  end

  @doc """
  Evaluates metric values against baseline gates in deterministic name order.
  """
  @spec evaluate(map(), [Baseline.gate()]) :: [map()]
  def evaluate(metrics, gates) when is_map(metrics) and is_list(gates) do
    gates
    |> Enum.sort_by(& &1.name)
    |> Enum.map(fn gate ->
      observed = Map.get(metrics, gate.metric)

      cond do
        not is_number(observed) ->
          gate_result(gate, observed, "fail", "metric was not emitted")

        gate.direction == "lower_is_better" and observed < gate.budget ->
          gate_result(gate, observed, "pass", nil)

        gate.direction == "lower_is_better" ->
          gate_result(gate, observed, "fail", "observed value does not satisfy strict budget")

        true ->
          gate_result(gate, observed, "fail", "unsupported gate direction")
      end
    end)
  end

  @doc "Returns true only when every configured hard gate passed."
  @spec pass?(t()) :: boolean()
  def pass?(%__MODULE__{gate_results: results}) do
    results != [] and Enum.all?(results, &(&1["status"] == "pass"))
  end

  @doc """
  Formats one actionable block per failed metric.
  """
  @spec failure_text(t()) :: String.t()
  def failure_text(%__MODULE__{} = summary) do
    summary.gate_results
    |> Enum.reject(&(&1["status"] == "pass"))
    |> Enum.map_join("\n", &format_failure(&1, summary))
  end

  @doc """
  Serialises the summary to a JSON string.
  """
  @spec to_json(t()) :: {:ok, String.t()} | {:error, term()}
  def to_json(%__MODULE__{} = summary) do
    Jason.encode(Map.from_struct(summary))
  end

  defp aggregate(samples, host) do
    ram_bytes = fetch(host, "ram_bytes")

    %{
      "beam.cpu.node_plus_coordinator.mean_percent" => combined_mean(samples, "cpu.percent"),
      "beam.memory.node_plus_coordinator.peak_percent" =>
        combined_ram_percent(samples, "memory.rss.bytes", ram_bytes),
      "node.cpu.mean_percent" => mean_metric(samples, :node, "cpu.percent"),
      "coordinator.cpu.mean_percent" => mean_metric(samples, :coordinator, "cpu.percent"),
      "llama.cpu.mean_percent" => mean_metric(samples, :llama, "cpu.percent"),
      "node.memory.rss.peak_bytes" => peak_metric(samples, :node, "memory.rss.bytes"),
      "coordinator.memory.rss.peak_bytes" =>
        peak_metric(samples, :coordinator, "memory.rss.bytes"),
      "llama.memory.rss.peak_bytes" => peak_metric(samples, :llama, "memory.rss.bytes"),
      "bundle.memory.rss.peak_bytes" => combined_peak(samples, "memory.rss.bytes")
    }
    |> Map.merge(workload_metrics(samples))
  end

  defp combined_mean(samples, metric_name) do
    case combined_values(samples, metric_name, [:node, :coordinator]) do
      {:ok, values} when values != [] -> mean(values)
      _ -> nil
    end
  end

  defp combined_ram_percent(samples, metric_name, ram_bytes)
       when is_number(ram_bytes) and ram_bytes > 0 do
    case combined_values(samples, metric_name, [:node, :coordinator]) do
      {:ok, values} when values != [] -> Enum.max(values) / ram_bytes * 100
      _ -> nil
    end
  end

  defp combined_ram_percent(_samples, _metric_name, _ram_bytes), do: nil

  defp combined_peak(samples, metric_name) do
    case combined_values(samples, metric_name, [:node, :coordinator, :llama]) do
      {:ok, values} when values != [] -> Enum.max(values)
      _ -> nil
    end
  end

  defp combined_values(samples, metric_name, sources) do
    relevant =
      Enum.filter(samples, fn sample ->
        sample.source in sources and sample.metric_name == metric_name
      end)

    missing_source? =
      Enum.any?(sources, fn source ->
        source_samples = Enum.filter(relevant, &(&1.source == source))

        source_samples == [] or
          Enum.any?(source_samples, &(:missing in &1.tags)) or
          not Enum.any?(source_samples, &is_number(&1.value))
      end)

    if missing_source? do
      {:error, :missing_metric}
    else
      values =
        relevant
        |> Enum.filter(&is_number(&1.value))
        |> Enum.group_by(& &1.timestamp)
        |> Enum.sort_by(&elem(&1, 0))
        |> Enum.flat_map(fn {_timestamp, timestamp_samples} ->
          by_source = Map.new(timestamp_samples, &{&1.source, &1.value})

          if Enum.all?(sources, &Map.has_key?(by_source, &1)) do
            [Enum.sum(Enum.map(sources, &Map.fetch!(by_source, &1)))]
          else
            []
          end
        end)

      if values == [], do: {:error, :missing_metric}, else: {:ok, values}
    end
  end

  defp mean_metric(samples, source, name) do
    values = metric_values(samples, source, name)
    if values == [], do: nil, else: mean(values)
  end

  defp peak_metric(samples, source, name) do
    case metric_values(samples, source, name) do
      [] -> nil
      values -> Enum.max(values)
    end
  end

  defp metric_values(samples, source, name) do
    for %Sample{source: ^source, metric_name: ^name, value: value} <- samples,
        is_number(value),
        do: value
  end

  defp mean(values), do: Enum.sum(values) / length(values)

  defp workload_metrics(samples) do
    samples
    |> Enum.filter(fn sample ->
      sample.source == :llama and String.starts_with?(sample.metric_name, "llama.")
    end)
    |> Enum.reduce(%{}, fn sample, metrics ->
      Map.put(metrics, sample.metric_name, sample.value)
    end)
  end

  defp gate_result(gate, observed, status, reason) do
    %{
      "name" => gate.name,
      "metric" => gate.metric,
      "observed" => observed,
      "budget" => gate.budget,
      "unit" => gate.unit,
      "direction" => gate.direction,
      "status" => status,
      "reason" => reason
    }
  end

  defp format_failure(result, summary) do
    observed =
      case result["observed"] do
        value when is_number(value) -> "#{format_number(value)} #{result["unit"]}"
        _ -> "(not recorded)"
      end

    artifact_version = fetch(summary.artifact_identity, "artifact_version") || "unknown"
    commit = fetch(summary.artifact_identity, "source_commit") || "unknown"
    host_arch = fetch(summary.host_profile, "architecture") || "unknown"
    cpu_model = fetch(summary.host_profile, "cpu_model") || "unknown"
    cpu_count = fetch(summary.host_profile, "cpu_count") || "unknown"
    ram_bytes = fetch(summary.host_profile, "ram_bytes")

    ram =
      if is_number(ram_bytes) do
        "#{Float.round(ram_bytes / 1_073_741_824, 1)} GiB"
      else
        "unknown RAM"
      end

    reason =
      case result["reason"] do
        nil -> ""
        text -> "\n  reason:   #{text}"
      end

    """
    M5 gate FAIL: #{result["name"]}
      metric:   #{result["metric"]}
      observed: #{observed}
      budget:   < #{format_number(result["budget"])} #{result["unit"]}
      artifact: exocomp_node v#{String.trim_leading(artifact_version, "v")} (commit #{short_commit(commit)})
      host:     #{host_arch} (#{cpu_model}, #{cpu_count} vCPU, #{ram})
      baseline: #{summary.baseline_path}#{reason}
    """
    |> String.trim_trailing()
  end

  defp format_number(value) when is_integer(value), do: Integer.to_string(value)
  defp format_number(value) when is_float(value), do: :erlang.float_to_binary(value, decimals: 3)

  defp short_commit(commit) when is_binary(commit), do: String.slice(commit, 0, 12)
  defp short_commit(commit), do: to_string(commit)

  defp mapify(%ArtifactIdentity{} = identity), do: ArtifactIdentity.to_map(identity)
  defp mapify(%HostProfile{} = profile), do: Map.from_struct(profile)
  defp mapify(map) when is_map(map), do: map

  defp fetch(map, key) do
    Map.get(map, key) || Map.get(map, String.to_existing_atom(key))
  rescue
    ArgumentError -> Map.get(map, key)
  end
end
