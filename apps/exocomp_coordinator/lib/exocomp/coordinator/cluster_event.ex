# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ClusterEvent do
  @moduledoc """
  Validator for versioned cluster event envelopes.

  The envelope is deliberately strict. Organization and cluster identity are
  transport properties, not accepted JSON fields, and are supplied separately
  by `ClusterEventIngestor`.
  """

  alias Exocomp.Coordinator.Error

  @schema_version 1
  @max_event_bytes 262_144
  @allowed_kinds ~w(
    cluster.hello
    cluster.heartbeat
    status.snapshot
    alert.opened
    alert.updated
    alert.resolved
    conversation.reply
    proposal.created
    approval.result
    action.status
    audit.event
  )
  @fields ~w(schema_version event_id cluster_seq kind occurred_at correlation_id payload)a

  @type t :: %{
          schema_version: pos_integer(),
          event_id: String.t(),
          cluster_seq: pos_integer(),
          kind: String.t(),
          occurred_at: String.t(),
          correlation_id: String.t(),
          payload: map()
        }

  @doc "Returns the currently supported event envelope schema version."
  @spec schema_version() :: pos_integer()
  def schema_version, do: @schema_version

  @doc "Returns the initial event vocabulary."
  @spec allowed_kinds() :: [String.t()]
  def allowed_kinds, do: @allowed_kinds

  @doc "Validates and canonicalizes an event envelope."
  @spec validate(map(), keyword()) :: {:ok, t()} | {:error, Error.t()}
  def validate(envelope, opts \\ [])

  def validate(envelope, opts) when is_map(envelope) do
    supported_version = Keyword.get(opts, :schema_version, @schema_version)
    max_event_bytes = Keyword.get(opts, :max_event_bytes, @max_event_bytes)

    with :ok <- validate_fields(envelope),
         {:ok, schema_version} <- value(envelope, :schema_version),
         :ok <- validate_version(schema_version, supported_version),
         {:ok, event_id} <- required_string(envelope, :event_id, 256),
         {:ok, cluster_seq} <- positive_integer(envelope, :cluster_seq),
         {:ok, kind} <- required_kind(envelope),
         {:ok, occurred_at} <- required_timestamp(envelope),
         {:ok, correlation_id} <- required_string(envelope, :correlation_id, 256),
         {:ok, payload} <- required_map(envelope, :payload),
         {:ok, canonical} <-
           canonical_event(
             schema_version,
             event_id,
             cluster_seq,
             kind,
             occurred_at,
             correlation_id,
             payload
           ),
         :ok <- validate_size(canonical, max_event_bytes) do
      {:ok, canonical}
    end
  end

  def validate(_envelope, _opts),
    do: {:error, Error.new(:invalid_event_schema, "event envelope must be a JSON object")}

  defp validate_fields(envelope) do
    actual = Map.keys(envelope)
    expected = Enum.map(@fields, &Atom.to_string/1)

    unknown =
      Enum.reject(actual, fn key ->
        key in @fields or (is_atom(key) and Atom.to_string(key) in expected)
      end)

    missing =
      Enum.reject(@fields, fn key ->
        Map.has_key?(envelope, key) or Map.has_key?(envelope, Atom.to_string(key))
      end)

    cond do
      unknown != [] ->
        {:error,
         Error.new(:invalid_event_schema, "event envelope contains unknown fields", %{
           fields: Enum.map(unknown, &to_string/1)
         })}

      missing != [] ->
        {:error,
         Error.new(:invalid_event_schema, "event envelope is missing required fields", %{
           fields: Enum.map(missing, &Atom.to_string/1)
         })}

      true ->
        :ok
    end
  end

  defp value(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error -> Map.fetch(map, Atom.to_string(key))
    end
  end

  defp validate_version(version, supported_version)
       when version == supported_version and is_integer(version) and version > 0,
       do: :ok

  defp validate_version(version, supported_version) do
    {:error,
     Error.new(:unsupported_event_schema_version, "event schema version is unsupported", %{
       expected: supported_version,
       actual: version
     })}
  end

  defp required_string(map, key, max_length) do
    with {:ok, value} <- value(map, key),
         true <- is_binary(value),
         true <- String.trim(value) != "",
         true <- String.length(value) <= max_length do
      {:ok, value}
    else
      _ ->
        {:error,
         Error.new(:invalid_event_schema, "#{key} must be a non-empty bounded string", %{
           field: Atom.to_string(key),
           max_length: max_length
         })}
    end
  end

  defp positive_integer(map, key) do
    case value(map, key) do
      {:ok, value} when is_integer(value) and value > 0 -> {:ok, value}
      _ -> {:error, Error.new(:invalid_event_schema, "cluster_seq must be a positive integer")}
    end
  end

  defp required_kind(map) do
    with {:ok, kind} <- required_string(map, :kind, 128),
         true <- kind in @allowed_kinds do
      {:ok, kind}
    else
      false ->
        {:error, Error.new(:invalid_event_kind, "event kind is not supported")}

      {:error, _} = error ->
        error
    end
  end

  defp required_timestamp(map) do
    with {:ok, occurred_at} <- required_string(map, :occurred_at, 64),
         {:ok, _datetime, _offset} <- DateTime.from_iso8601(occurred_at) do
      {:ok, occurred_at}
    else
      _ -> {:error, Error.new(:invalid_event_schema, "occurred_at must be an ISO-8601 timestamp")}
    end
  end

  defp required_map(map, key) do
    case value(map, key) do
      {:ok, value} when is_map(value) -> {:ok, value}
      _ -> {:error, Error.new(:invalid_event_schema, "payload must be a JSON object")}
    end
  end

  defp canonical_event(
         schema_version,
         event_id,
         cluster_seq,
         kind,
         occurred_at,
         correlation_id,
         payload
       ) do
    {:ok,
     %{
       schema_version: schema_version,
       event_id: event_id,
       cluster_seq: cluster_seq,
       kind: kind,
       occurred_at: occurred_at,
       correlation_id: correlation_id,
       payload: payload
     }}
  end

  defp validate_size(event, max_event_bytes)
       when is_integer(max_event_bytes) and max_event_bytes > 0 do
    case Jason.encode(event) do
      {:ok, encoded} when byte_size(encoded) <= max_event_bytes ->
        :ok

      {:ok, encoded} ->
        {:error,
         Error.new(:event_too_large, "event envelope exceeds the maximum size", %{
           max_bytes: max_event_bytes,
           actual_bytes: byte_size(encoded)
         })}

      {:error, _reason} ->
        {:error, Error.new(:invalid_event_schema, "payload contains a non-JSON value")}
    end
  end

  defp validate_size(_event, _max_event_bytes),
    do: {:error, Error.new(:invalid_event_schema, "event size limit is invalid")}
end
