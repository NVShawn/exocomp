# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Workload.Soak do
  @moduledoc """
  Runs a bounded workload repeatedly for an explicit soak duration.

  The iteration schedule is calculated up front, so dependency-injected clocks
  and no-op sleepers used by harness tests cannot create an infinite loop.
  """

  alias Bench.Sample

  @spec run(pos_integer(), pos_integer(), (-> {:ok, [Sample.t()]} | {:error, term()}), keyword()) ::
          {:ok, [Sample.t()]} | {:error, term()}
  def run(duration_ms, interval_ms, workload_fn, opts \\ [])
      when is_integer(duration_ms) and duration_ms > 0 and is_integer(interval_ms) and
             interval_ms > 0 and is_function(workload_fn, 0) do
    sleep_fn = Keyword.get(opts, :sleep_fn, &Process.sleep/1)
    now_fn = Keyword.get(opts, :now_fn, fn -> System.monotonic_time(:millisecond) end)
    iterations = max(div(duration_ms + interval_ms - 1, interval_ms), 1)
    started = now_fn.()

    0..(iterations - 1)
    |> Enum.reduce_while({:ok, []}, fn iteration, {:ok, samples} ->
      case workload_fn.() do
        {:ok, iteration_samples} ->
          target_elapsed = min((iteration + 1) * interval_ms, duration_ms)
          actual_elapsed = max(now_fn.() - started, 0)
          :ok = sleep_fn.(max(target_elapsed - actual_elapsed, 0))
          {:cont, {:ok, samples ++ iteration_samples}}

        {:error, reason} ->
          {:halt, {:error, {:soak_workload_failed, iteration + 1, reason}}}
      end
    end)
    |> case do
      {:ok, samples} ->
        {:ok,
         samples ++
           [
             %Sample{
               timestamp: System.system_time(:millisecond),
               source: :beam,
               metric_name: "soak.load.iterations",
               value: iterations,
               unit: "count",
               tags: []
             }
           ]}

      error ->
        error
    end
  end
end
