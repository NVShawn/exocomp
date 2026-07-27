# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.QualificationProbe do
  @moduledoc """
  Opt-in runtime sampler used by shipped-artifact qualification.

  The sampler is never part of an application supervision tree. A qualification
  driver starts it over release RPC, samples the VM that is actually serving
  the installed artifact, exports the observations, and stops it. This avoids
  treating the benchmark harness VM as node or coordinator telemetry.
  """

  use GenServer

  @name __MODULE__
  @default_interval_ms 1_000

  @type source :: :node | :coordinator

  @doc """
  Starts the probe without linking it to the short-lived RPC evaluator.

  `:named_processes` is a list of `{metric_label, registered_name}` pairs.
  `:history` is a list of `{metric_label, zero_arity_function}` pairs used for
  bounded task and goal history sizes.
  """
  @spec start(keyword()) :: :ok | {:error, term()}
  def start(opts) when is_list(opts) do
    case GenServer.start(__MODULE__, opts, name: @name) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> {:error, :already_started}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Collects one final observation, exports JSON sample maps, and stops."
  @spec export_and_stop() :: {:ok, String.t()} | {:error, term()}
  def export_and_stop do
    case Process.whereis(@name) do
      nil -> {:error, :not_started}
      _pid -> GenServer.call(@name, :export_and_stop, 30_000)
    end
  end

  @impl true
  def init(opts) do
    with {:ok, source} <- source(Keyword.get(opts, :source)),
         {:ok, interval_ms} <-
           positive_integer(Keyword.get(opts, :interval_ms, @default_interval_ms)),
         {:ok, named_processes} <- pairs(Keyword.get(opts, :named_processes, []), :process),
         {:ok, history} <- pairs(Keyword.get(opts, :history, []), :function) do
      state = %{
        source: source,
        interval_ms: interval_ms,
        named_processes: named_processes,
        history: history,
        samples: [],
        timer: nil
      }

      {:ok, state |> collect() |> schedule()}
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_info(:sample, state) do
    {:noreply, state |> Map.put(:timer, nil) |> collect() |> schedule()}
  end

  @impl true
  def handle_call(:export_and_stop, _from, state) do
    state = collect(state)
    samples = state.samples |> Enum.reverse() |> Jason.encode!()
    {:stop, :normal, {:ok, samples}, state}
  end

  @impl true
  def terminate(_reason, %{timer: timer}) when is_reference(timer) do
    Process.cancel_timer(timer)
    :ok
  end

  def terminate(_reason, _state), do: :ok

  defp collect(state) do
    timestamp = System.system_time(:millisecond)

    samples = [
      sample(state, timestamp, "beam.memory.total.bytes", :erlang.memory(:total), "bytes"),
      sample(
        state,
        timestamp,
        "beam.process.count",
        :erlang.system_info(:process_count),
        "count"
      ),
      sample(state, timestamp, "beam.run_queue.count", :erlang.statistics(:run_queue), "count")
    ]

    mailbox_samples =
      Enum.map(state.named_processes, fn {label, registered_name} ->
        value =
          case Process.whereis(registered_name) do
            nil -> nil
            pid -> process_info_value(pid, :message_queue_len)
          end

        sample(state, timestamp, "beam.mailbox.#{label}.depth", value, "count")
      end)

    history_samples =
      Enum.map(state.history, fn {label, observation} ->
        sample(state, timestamp, "#{label}.count", safe_observe(observation), "count")
      end)

    %{state | samples: Enum.reverse(samples ++ mailbox_samples ++ history_samples, state.samples)}
  end

  defp sample(state, timestamp, metric_name, value, unit) do
    %{
      "timestamp" => timestamp,
      "source" => Atom.to_string(state.source),
      "metric_name" => metric_name,
      "value" => value,
      "unit" => unit,
      "tags" => if(is_number(value), do: [], else: ["unavailable"])
    }
  end

  defp safe_observe(observation) do
    case observation.() do
      value when is_number(value) -> value
      _other -> nil
    end
  rescue
    _error -> nil
  catch
    _kind, _reason -> nil
  end

  defp process_info_value(pid, key) do
    case Process.info(pid, key) do
      {^key, value} when is_number(value) -> value
      _other -> nil
    end
  end

  defp schedule(state) do
    %{state | timer: Process.send_after(self(), :sample, state.interval_ms)}
  end

  defp source(source) when source in [:node, :coordinator], do: {:ok, source}
  defp source(source), do: {:error, {:invalid_source, source}}

  defp positive_integer(value) when is_integer(value) and value > 0, do: {:ok, value}
  defp positive_integer(value), do: {:error, {:invalid_interval, value}}

  defp pairs(values, kind) when is_list(values) do
    if Enum.all?(values, &valid_pair?(&1, kind)) do
      {:ok, values}
    else
      {:error, {:invalid_pairs, kind}}
    end
  end

  defp pairs(_values, kind), do: {:error, {:invalid_pairs, kind}}

  defp valid_pair?({label, name}, :process), do: is_binary(label) and is_atom(name)

  defp valid_pair?({label, function}, :function),
    do: is_binary(label) and is_function(function, 0)

  defp valid_pair?(_value, _kind), do: false
end
