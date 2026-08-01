# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.Qualification.MissionControl.Metrics do
  @moduledoc """
  Metrics collector for Mission Control scale qualification.

  Collects telemetry on:
  - Connection count (active clusters connected to MC)
  - BEAM metrics (processes, mailboxes, memory)
  - Database metrics (pool size, queue depth)
  - Event processing (outbox depth, delivery latency, loss)
  - Webhook/retention workers status

  All metrics are collected via HTTP polling of Mission Control metrics endpoint
  or through a configured RPC/telemetry interface.
  """

  alias Bench.Sample

  @doc """
  Polls Mission Control for current metrics.

  Returns a list of samples with the current state of connection count,
  BEAM metrics, database pool/queue, and worker status.

  This is a stub implementation that returns placeholder values. Real
  implementation will query Mission Control HTTP metrics endpoint or
  telemetry interface once MC is available.
  """
  @spec poll(mc_service_url :: binary()) :: {:ok, [Sample.t()]} | {:error, term()}
  def poll(_mc_service_url) do
    # Placeholder: Once Mission Control implements /metrics or similar,
    # this function will query it for:
    # - prometheus-format metrics
    # - cluster connection counts
    # - BEAM metrics (erlang:system_info)
    # - database pool statistics
    # - outbox/webhook/retention worker depths
    #
    # For now, returns empty list. Tests using this will mock the results.
    {:ok, []}
  end

  @doc """
  Collects BEAM metrics from local node (MC should export via introspection API).

  Returns samples for:
  - Process count
  - Mailbox depth (average across processes)
  - Memory usage (total, processes, binary, atom)
  - File descriptor count
  """
  @spec beam_metrics(node :: atom(), now :: DateTime.t()) :: [Sample.t()]
  def beam_metrics(_node \\ :mission_control, _now \\ DateTime.utc_now()) do
    beam_time = System.monotonic_time(:millisecond)

    [
      %Sample{
        source: :beam,
        metric_name: "mission_control.beam.process_count",
        value: placeholder_value(:process_count),
        timestamp: beam_time,
        unit: "processes",
        tags: []
      },
      %Sample{
        source: :beam,
        metric_name: "mission_control.beam.memory_total_bytes",
        value: placeholder_value(:memory_total),
        timestamp: beam_time,
        unit: "bytes",
        tags: []
      },
      %Sample{
        source: :beam,
        metric_name: "mission_control.beam.memory_processes_bytes",
        value: placeholder_value(:memory_processes),
        timestamp: beam_time,
        unit: "bytes",
        tags: []
      },
      %Sample{
        source: :beam,
        metric_name: "mission_control.beam.memory_binary_bytes",
        value: placeholder_value(:memory_binary),
        timestamp: beam_time,
        unit: "bytes",
        tags: []
      }
    ]
  end

  @doc """
  Collects database pool and queue metrics.

  Returns samples for:
  - Pool size (configured vs current)
  - Queue depth
  - Available connections
  """
  @spec database_metrics(now :: DateTime.t()) :: [Sample.t()]
  def database_metrics(_now \\ DateTime.utc_now()) do
    db_time = System.monotonic_time(:millisecond)

    [
      %Sample{
        source: :host,
        metric_name: "mission_control.database.pool_size",
        value: placeholder_value(:pool_size),
        timestamp: db_time,
        unit: "connections",
        tags: []
      },
      %Sample{
        source: :host,
        metric_name: "mission_control.database.queue_depth",
        value: placeholder_value(:queue_depth),
        timestamp: db_time,
        unit: "requests",
        tags: []
      },
      %Sample{
        source: :host,
        metric_name: "mission_control.database.available_connections",
        value: placeholder_value(:available_connections),
        timestamp: db_time,
        unit: "connections",
        tags: []
      }
    ]
  end

  @doc """
  Collects outbox and worker metrics.

  Returns samples for:
  - Event outbox depth (events waiting to be sent to clusters)
  - Webhook delivery worker queue depth
  - Retention job worker status
  """
  @spec worker_metrics(now :: DateTime.t()) :: [Sample.t()]
  def worker_metrics(_now \\ DateTime.utc_now()) do
    worker_time = System.monotonic_time(:millisecond)

    [
      %Sample{
        source: :host,
        metric_name: "mission_control.outbox.depth",
        value: placeholder_value(:outbox_depth),
        timestamp: worker_time,
        unit: "events",
        tags: []
      },
      %Sample{
        source: :host,
        metric_name: "mission_control.webhook_workers.queue_depth",
        value: placeholder_value(:webhook_queue),
        timestamp: worker_time,
        unit: "deliveries",
        tags: []
      },
      %Sample{
        source: :host,
        metric_name: "mission_control.retention_workers.active_count",
        value: placeholder_value(:retention_workers),
        timestamp: worker_time,
        unit: "workers",
        tags: []
      }
    ]
  end

  @doc """
  Collects cluster connection metrics.

  Returns samples for:
  - Connected cluster count
  - Disconnected cluster count (should be 0 at scale)
  - Heartbeat lag (p50, p95)
  """
  @spec connection_metrics(now :: DateTime.t()) :: [Sample.t()]
  def connection_metrics(_now \\ DateTime.utc_now()) do
    conn_time = System.monotonic_time(:millisecond)

    [
      %Sample{
        source: :host,
        metric_name: "mission_control.clusters.connected_count",
        value: placeholder_value(:connected_clusters),
        timestamp: conn_time,
        unit: "clusters",
        tags: []
      },
      %Sample{
        source: :host,
        metric_name: "mission_control.clusters.disconnected_count",
        value: placeholder_value(:disconnected_clusters),
        timestamp: conn_time,
        unit: "clusters",
        tags: []
      },
      %Sample{
        source: :host,
        metric_name: "mission_control.clusters.heartbeat_lag_ms_p50",
        value: placeholder_value(:heartbeat_lag_p50),
        timestamp: conn_time,
        unit: "milliseconds",
        tags: []
      },
      %Sample{
        source: :host,
        metric_name: "mission_control.clusters.heartbeat_lag_ms_p95",
        value: placeholder_value(:heartbeat_lag_p95),
        timestamp: conn_time,
        unit: "milliseconds",
        tags: []
      }
    ]
  end

  # Placeholder value generator for testing and demonstration
  # Once real MC service exists, these will be replaced with actual queries
  defp placeholder_value(:process_count), do: 500
  defp placeholder_value(:memory_total), do: 1_024 * 1_024 * 100  # 100 MB
  defp placeholder_value(:memory_processes), do: 1_024 * 1_024 * 60
  defp placeholder_value(:memory_binary), do: 1_024 * 1_024 * 20
  defp placeholder_value(:pool_size), do: 10
  defp placeholder_value(:queue_depth), do: 0
  defp placeholder_value(:available_connections), do: 10
  defp placeholder_value(:outbox_depth), do: 0
  defp placeholder_value(:webhook_queue), do: 0
  defp placeholder_value(:retention_workers), do: 2
  defp placeholder_value(:connected_clusters), do: 100
  defp placeholder_value(:disconnected_clusters), do: 0
  defp placeholder_value(:heartbeat_lag_p50), do: 100
  defp placeholder_value(:heartbeat_lag_p95), do: 200
end
