# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.Event do
  @moduledoc """
  A Mission Control cluster event envelope.

  Events are the primary delivery mechanism for cluster state changes to
  Mission Control. They carry schema versioning, deduplication identifiers,
  sequence numbers, and bounded payloads.

  The event envelope includes:
  - `schema_version`: Protocol version (currently 1)
  - `event_id`: Unique identifier for deduplication (e.g., UUIDv7)
  - `cluster_seq`: Monotonic per-cluster sequence number for gap detection
  - `kind`: Event type from the initial allow-list
  - `occurred_at`: ISO8601 timestamp when the event occurred
  - `correlation_id`: Reuses A2A correlation ID for tracing
  - `payload`: Type-specific event data, bounded by size limits

  Valid event kinds (initial allow-list from Mission Control plan):
  - `cluster.hello` — cluster handshake and metadata
  - `cluster.heartbeat` — periodic connectivity signal
  - `status.snapshot` — materialized cluster/node state
  - `alert.opened` — new alert from cluster
  - `alert.updated` — alert modification
  - `alert.resolved` — alert closure
  - `conversation.reply` — message from cluster-local conversation agent
  - `proposal.created` — typed remedy proposal from cluster
  - `approval.result` — outcome of an approved action
  - `action.status` — execution status update
  - `audit.event` — audited action or decision

  Payloads are schema-validated, size-bounded, and redacted before ingestion.
  """

  @enforce_keys [:schema_version, :event_id, :cluster_seq, :kind, :occurred_at, :payload]

  defstruct schema_version: nil,
            event_id: nil,
            cluster_seq: nil,
            kind: nil,
            occurred_at: nil,
            correlation_id: nil,
            payload: nil

  # Schema version is versioned independently from A2A
  @current_schema_version 1

  @valid_kinds [
    "cluster.hello",
    "cluster.heartbeat",
    "status.snapshot",
    "alert.opened",
    "alert.updated",
    "alert.resolved",
    "conversation.reply",
    "proposal.created",
    "approval.result",
    "action.status",
    "audit.event"
  ]

  # Maximum payload size in bytes (100 KiB)
  @max_payload_size 102_400

  @type t :: %__MODULE__{
          schema_version: integer(),
          event_id: String.t(),
          cluster_seq: integer(),
          kind: String.t(),
          occurred_at: String.t(),
          correlation_id: String.t() | nil,
          payload: map()
        }

  @spec current_schema_version() :: integer()
  def current_schema_version, do: @current_schema_version

  @spec valid_kinds() :: [String.t()]
  def valid_kinds, do: @valid_kinds

  @spec max_payload_size() :: integer()
  def max_payload_size, do: @max_payload_size

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(params) when is_map(params) do
    with {:ok, schema_version} <- validate_schema_version(params),
         {:ok, event_id} <- validate_event_id(params),
         {:ok, cluster_seq} <- validate_cluster_seq(params),
         {:ok, kind} <- validate_kind(params),
         {:ok, occurred_at} <- validate_occurred_at(params),
         {:ok, payload} <- validate_payload(params) do
      {:ok,
       %__MODULE__{
         schema_version: schema_version,
         event_id: event_id,
         cluster_seq: cluster_seq,
         kind: kind,
         occurred_at: occurred_at,
         correlation_id: Map.get(params, "correlation_id"),
         payload: payload
       }}
    end
  end

  defp validate_schema_version(params) do
    case Map.get(params, "schema_version") do
      v when is_integer(v) and v > 0 ->
        if v == @current_schema_version do
          {:ok, v}
        else
          {:error, {:unsupported_schema_version, v}}
        end

      nil ->
        {:error, :missing_schema_version}

      other ->
        {:error, {:invalid_schema_version, other}}
    end
  end

  defp validate_event_id(params) do
    case Map.get(params, "event_id") do
      id when is_binary(id) and byte_size(id) > 0 ->
        {:ok, id}

      nil ->
        {:error, :missing_event_id}

      other ->
        {:error, {:invalid_event_id, other}}
    end
  end

  defp validate_cluster_seq(params) do
    case Map.get(params, "cluster_seq") do
      seq when is_integer(seq) and seq >= 0 ->
        {:ok, seq}

      nil ->
        {:error, :missing_cluster_seq}

      other ->
        {:error, {:invalid_cluster_seq, other}}
    end
  end

  defp validate_kind(params) do
    case Map.get(params, "kind") do
      kind when is_binary(kind) ->
        if kind in @valid_kinds do
          {:ok, kind}
        else
          {:error, {:unknown_kind, kind}}
        end

      nil ->
        {:error, :missing_kind}

      other ->
        {:error, {:invalid_kind, other}}
    end
  end

  defp validate_occurred_at(params) do
    case Map.get(params, "occurred_at") do
      ts when is_binary(ts) and byte_size(ts) > 0 ->
        # Basic ISO8601 validation: must be non-empty binary
        # More sophisticated validation (RFC3339) happens at codec layer
        {:ok, ts}

      nil ->
        {:error, :missing_occurred_at}

      other ->
        {:error, {:invalid_occurred_at, other}}
    end
  end

  defp validate_payload(params) do
    case Map.get(params, "payload") do
      payload when is_map(payload) ->
        encoded = :erlang.term_to_binary(payload)

        if byte_size(encoded) <= @max_payload_size do
          {:ok, payload}
        else
          {:error, {:payload_oversized, byte_size(encoded)}}
        end

      nil ->
        {:error, :missing_payload}

      other ->
        {:error, {:invalid_payload, other}}
    end
  end
end
