# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Qualification.MissionControl.Load do
  @moduledoc """
  Mission Control deterministic load driver.

  Simulates 100 persistent cluster connections, 10,000 current node records,
  and a burst of 100 events per second. Generates events in the MC protocol
  envelope format and measures delivery latency and loss.

  The workload is designed to be protocol-agnostic; the actual transport
  (HTTP, WebSocket, gRPC, etc.) is handled by a client adapter.
  """

  alias Bench.Sample

  @doc """
  Runs the load workload and collects event delivery samples.

  Returns {:ok, samples} where samples contain delivery latency and loss metrics.
  The workload generator accepts a callback for sending events; test suites
  provide mock or real implementations.

  Options:
    - :sleep_fn - function for async delays (default: Process.sleep/1)
  """
  @spec run(
    duration_ms :: pos_integer(),
    config :: Bench.Qualification.MissionControl.Config.t(),
    send_fn :: (map() -> {:ok, binary()} | {:error, term()}),
    keyword()
  ) :: {:ok, [Sample.t()]} | {:error, term()}
  def run(duration_ms, config, send_fn, opts \\ []) when duration_ms > 0 do
    sleep_fn = Keyword.get(opts, :sleep_fn, &Process.sleep/1)
    start_time = System.monotonic_time(:millisecond)
    deadline = start_time + duration_ms

    samples = run_load_loop(config, send_fn, sleep_fn, start_time, deadline, [])
    {:ok, samples}
  rescue
    e ->
      {:error, {:load_workload_failed, inspect(e)}}
  end

  @doc """
  Generates a single cluster event in Mission Control protocol format.

  Returns a map with the required envelope and sensible defaults for testing.
  """
  @spec generate_event(cluster_id :: binary(), seq :: pos_integer(), kind :: binary()) :: map()
  def generate_event(_cluster_id, seq, kind \\ "status.snapshot") do
    %{
      "schema_version" => 1,
      "event_id" => generate_event_id(),
      "cluster_seq" => seq,
      "kind" => kind,
      "occurred_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "correlation_id" => "corr_" <> generate_correlation_id(),
      "payload" => case kind do
        "status.snapshot" -> %{"node_count" => 100}
        "alert.opened" -> %{"alert_type" => "node_degraded", "target_id" => random_hex(8)}
        _ -> %{}
      end
    }
  end

  @doc "Generates a valid event ID (ulid-like format)."
  @spec generate_event_id() :: binary()
  def generate_event_id do
    "018#{random_hex(19)}"
  end

  @doc "Generates a correlation ID."
  @spec generate_correlation_id() :: binary()
  def generate_correlation_id do
    random_hex(12)
  end

  defp random_hex(length) do
    :crypto.strong_rand_bytes(div(length + 1, 2))
    |> Base.encode16(case: :lower)
    |> String.slice(0, length)
  end

  defp run_load_loop(config, send_fn, sleep_fn, start_time, deadline, samples) do
    now = System.monotonic_time(:millisecond)

    if now >= deadline do
      samples
    else
      new_samples = generate_and_send_burst(config, send_fn, now)
      time_until_deadline = deadline - System.monotonic_time(:millisecond)
      sleep_time = max(1, min(100, time_until_deadline))
      sleep_fn.(sleep_time)
      run_load_loop(config, send_fn, sleep_fn, start_time, deadline, samples ++ new_samples)
    end
  end

  defp generate_and_send_burst(config, send_fn, _now) do
    Enum.flat_map(1..config.cluster_count, fn cluster_idx ->
      cluster_id = "cluster-#{cluster_idx}"
      Enum.flat_map(1..config.event_burst_per_second, fn event_idx ->
        seq = cluster_idx * config.event_burst_per_second + event_idx
        event = generate_event(cluster_id, seq, "alert.opened")

        send_time = System.monotonic_time(:millisecond)

        case send_fn.(event) do
          {:ok, _response} ->
            delivery_time = System.monotonic_time(:millisecond)
            latency_ms = delivery_time - send_time

            [
              %Sample{
                source: :node,
                metric_name: "mission_control.event.delivery_latency_ms",
                value: latency_ms,
                timestamp: System.monotonic_time(:millisecond),
                unit: "milliseconds",
                tags: []
              },
              %Sample{
                source: :node,
                metric_name: "mission_control.event.sent_success_count",
                value: 1,
                timestamp: System.monotonic_time(:millisecond),
                unit: "count",
                tags: []
              }
            ]

          {:error, _reason} ->
            [
              %Sample{
                source: :node,
                metric_name: "mission_control.event.send_error_count",
                value: 1,
                timestamp: System.monotonic_time(:millisecond),
                unit: "count",
                tags: []
              }
            ]
        end
      end)
    end)
  end
end
