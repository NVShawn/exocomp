# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Analysis.Soak do
  @moduledoc """
  Detects sustained post-warm-up resource growth in a soak sample series.

  A series fails only when both its least-squares slope is positive and its
  final-window median exceeds its initial-window median by more than the
  bounded-cache allowance. This rejects persistent leaks without classifying
  ordinary high-water-mark noise as growth.
  """

  alias Bench.Sample

  @minimum_samples 4
  @memory_allowance_bytes 4 * 1_024 * 1_024
  @required_exact [
    {:node, "memory.rss.bytes"},
    {:coordinator, "memory.rss.bytes"},
    {:llama, "memory.rss.bytes"},
    {:node, "file_descriptors.open"},
    {:coordinator, "file_descriptors.open"},
    {:llama, "file_descriptors.open"},
    {:node, "beam.process.count"},
    {:coordinator, "beam.process.count"},
    {:node, "node.task_history.count"},
    {:coordinator, "coordinator.task_history.count"}
  ]

  @doc """
  Analyzes all required soak series plus every emitted named-process mailbox.

  Returns derived samples including slope/hour, window growth, stability for
  every series, required-metric completeness, and the overall hard result.
  """
  @spec analyze([Sample.t()], keyword()) :: {:ok, [Sample.t()]} | {:error, term()}
  def analyze(samples, opts \\ []) when is_list(samples) do
    minimum_samples = Keyword.get(opts, :minimum_samples, @minimum_samples)
    cutoff = Keyword.get(opts, :start_timestamp)
    samples = after_cutoff(samples, cutoff)
    mailbox_series = mailbox_series(samples)
    series = @required_exact ++ mailbox_series

    {analyses, missing} =
      Enum.reduce(series, {[], []}, fn {source, name} = key, {results, missing} ->
        observations = observations(samples, source, name)

        if length(observations) >= minimum_samples do
          {[analyze_series(key, observations) | results], missing}
        else
          {results, [key | missing]}
        end
      end)

    timestamp = System.system_time(:millisecond)
    complete = missing == [] and mailbox_sources_present?(mailbox_series)
    stable = complete and Enum.all?(analyses, & &1.stable)

    derived =
      analyses
      |> Enum.reverse()
      |> Enum.flat_map(&analysis_samples(&1, timestamp))

    {:ok,
     derived ++
       [
         sample(timestamp, "soak.required_metrics_present", bool(complete), "bool"),
         sample(timestamp, "soak.series.count", length(analyses), "count"),
         sample(timestamp, "soak.pass", bool(stable), "bool")
       ]}
  end

  defp analyze_series({source, name}, observations) do
    {timestamps, values} = Enum.unzip(observations)
    first_timestamp = hd(timestamps)
    elapsed_hours = max((List.last(timestamps) - first_timestamp) / 3_600_000, 1 / 3_600_000)
    x = Enum.map(timestamps, &((&1 - first_timestamp) / 3_600_000))
    slope = linear_slope(x, values)
    window_size = max(div(length(values), 4), 1)
    start_median = values |> Enum.take(window_size) |> median()
    end_median = values |> Enum.take(-window_size) |> median()
    growth = end_median - start_median
    allowance = allowance(name, start_median, elapsed_hours)
    sustained = slope > 0 and growth > allowance

    %{
      key: metric_key(source, name),
      slope_per_hour: slope,
      growth: growth,
      allowance: allowance,
      stable: not sustained
    }
  end

  defp analysis_samples(analysis, timestamp) do
    [
      sample(
        timestamp,
        "soak.#{analysis.key}.slope_per_hour",
        analysis.slope_per_hour,
        "per_hour"
      ),
      sample(timestamp, "soak.#{analysis.key}.window_growth", analysis.growth, "count"),
      sample(timestamp, "soak.#{analysis.key}.growth_allowance", analysis.allowance, "count"),
      sample(timestamp, "soak.#{analysis.key}.stable", bool(analysis.stable), "bool")
    ]
  end

  defp observations(samples, source, name) do
    samples
    |> Enum.flat_map(fn
      %Sample{
        source: ^source,
        metric_name: ^name,
        timestamp: timestamp,
        value: value,
        tags: tags
      }
      when is_integer(timestamp) and is_number(value) ->
        if :missing in tags or :unavailable in tags, do: [], else: [{timestamp, value}]

      _sample ->
        []
    end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  defp mailbox_series(samples) do
    samples
    |> Enum.filter(&String.starts_with?(&1.metric_name, "beam.mailbox."))
    |> Enum.map(&{&1.source, &1.metric_name})
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp mailbox_sources_present?(series) do
    Enum.all?([:node, :coordinator], fn source ->
      Enum.any?(series, &match?({^source, _name}, &1))
    end)
  end

  defp after_cutoff(samples, nil), do: samples

  defp after_cutoff(samples, cutoff) when is_integer(cutoff) do
    Enum.filter(samples, fn
      %Sample{timestamp: timestamp} when is_integer(timestamp) -> timestamp >= cutoff
      _sample -> false
    end)
  end

  defp allowance(name, start, _elapsed_hours) do
    cond do
      String.contains?(name, "memory.") -> max(@memory_allowance_bytes, abs(start) * 0.02)
      true -> 0
    end
  end

  defp linear_slope(x, y) do
    mean_x = mean(x)
    mean_y = mean(y)

    numerator =
      Enum.zip(x, y)
      |> Enum.reduce(0.0, fn {xi, yi}, sum -> sum + (xi - mean_x) * (yi - mean_y) end)

    denominator = Enum.reduce(x, 0.0, fn xi, sum -> sum + :math.pow(xi - mean_x, 2) end)
    if denominator == 0, do: 0.0, else: numerator / denominator
  end

  defp median(values) do
    sorted = Enum.sort(values)
    count = length(sorted)
    middle = div(count, 2)

    if rem(count, 2) == 1 do
      Enum.at(sorted, middle)
    else
      (Enum.at(sorted, middle - 1) + Enum.at(sorted, middle)) / 2
    end
  end

  defp mean(values), do: Enum.sum(values) / length(values)
  defp bool(true), do: 1
  defp bool(false), do: 0

  defp metric_key(source, name) do
    "#{source}.#{String.replace(name, ~r/[^a-zA-Z0-9]+/, "_")}"
  end

  defp sample(timestamp, name, value, unit) do
    %Sample{
      timestamp: timestamp,
      source: :beam,
      metric_name: name,
      value: value,
      unit: unit,
      tags: []
    }
  end
end
