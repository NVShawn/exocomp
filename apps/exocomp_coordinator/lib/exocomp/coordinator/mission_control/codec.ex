# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.Codec do
  @moduledoc """
  JSON codecs for Mission Control protocol envelopes.

  Handles encoding and decoding of cluster events, server commands, and
  acknowledgements. Validates schema versions, required fields, timestamps,
  and payload bounds.

  All timestamps are assumed to be ISO8601 format per the Mission Control
  specification. Validation is limited to well-formedness checks; full
  RFC3339 validation can be added at a higher level if needed.

  Errors include:
  - Missing required fields (schema_version, event_id, cluster_seq, kind, etc.)
  - Invalid types (event_id must be binary, cluster_seq must be integer, etc.)
  - Unsupported schema versions
  - Unknown kinds (not in the protocol allow-list)
  - Invalid timestamps
  - Oversized payloads (>100 KiB)
  """

  alias Exocomp.Coordinator.MissionControl.{
    Acknowledgement,
    Command,
    Event
  }

  # ---------------------------------------------------------------------------
  # Event encoding/decoding
  # ---------------------------------------------------------------------------

  @doc """
  Decode a JSON-parsed map into an `Event` struct.

  Returns `{:ok, event}` on success, or `{:error, reason}` when the input
  is malformed, missing required fields, or has invalid values.
  """
  @spec decode_event(term()) :: {:ok, Event.t()} | {:error, term()}
  def decode_event(params) when is_map(params) do
    Event.new(params)
  end

  def decode_event(other) do
    {:error, {:invalid_event_envelope, other}}
  end

  @doc """
  Encode an `Event` struct to a JSON-compatible map.

  All fields are included; optional fields like `correlation_id` may be `nil`.
  """
  @spec encode_event(Event.t()) :: map()
  def encode_event(%Event{} = event) do
    %{
      "schema_version" => event.schema_version,
      "event_id" => event.event_id,
      "cluster_seq" => event.cluster_seq,
      "kind" => event.kind,
      "occurred_at" => event.occurred_at,
      "correlation_id" => event.correlation_id,
      "payload" => event.payload
    }
  end

  # ---------------------------------------------------------------------------
  # Command encoding/decoding
  # ---------------------------------------------------------------------------

  @doc """
  Decode a JSON-parsed map into a `Command` struct.

  Returns `{:ok, command}` on success, or `{:error, reason}` when the input
  is malformed, missing required fields, or has invalid values.
  """
  @spec decode_command(term()) :: {:ok, Command.t()} | {:error, term()}
  def decode_command(params) when is_map(params) do
    Command.new(params)
  end

  def decode_command(other) do
    {:error, {:invalid_command_envelope, other}}
  end

  @doc """
  Encode a `Command` struct to a JSON-compatible map.
  """
  @spec encode_command(Command.t()) :: map()
  def encode_command(%Command{} = cmd) do
    %{
      "command_id" => cmd.command_id,
      "kind" => cmd.kind,
      "issued_at" => cmd.issued_at,
      "expires_at" => cmd.expires_at,
      "payload" => cmd.payload
    }
  end

  # ---------------------------------------------------------------------------
  # Acknowledgement encoding/decoding
  # ---------------------------------------------------------------------------

  @doc """
  Decode a JSON-parsed map into an `Acknowledgement` struct.

  Returns `{:ok, ack}` on success, or `{:error, reason}` when the input
  is malformed or missing required fields.
  """
  @spec decode_acknowledgement(term()) :: {:ok, Acknowledgement.t()} | {:error, term()}
  def decode_acknowledgement(params) when is_map(params) do
    Acknowledgement.new(params)
  end

  def decode_acknowledgement(other) do
    {:error, {:invalid_acknowledgement_envelope, other}}
  end

  @doc """
  Encode an `Acknowledgement` struct to a JSON-compatible map.
  """
  @spec encode_acknowledgement(Acknowledgement.t()) :: map()
  def encode_acknowledgement(%Acknowledgement{} = ack) do
    %{
      "acknowledged_at" => ack.acknowledged_at,
      "highest_seq" => ack.highest_seq,
      "session_id" => ack.session_id
    }
  end

  # ---------------------------------------------------------------------------
  # Batch operations (for protocol testing)
  # ---------------------------------------------------------------------------

  @doc """
  Decode multiple events from a list of JSON-parsed maps.

  Returns `{:ok, events}` on success, or `{:error, reason}` if any event fails.
  """
  @spec decode_events(term()) :: {:ok, [Event.t()]} | {:error, term()}
  def decode_events(params) when is_list(params) do
    Enum.reduce_while(params, {:ok, []}, fn raw, {:ok, acc} ->
      case decode_event(raw) do
        {:ok, event} -> {:cont, {:ok, [event | acc]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, reversed} -> {:ok, Enum.reverse(reversed)}
      err -> err
    end
  end

  def decode_events(other) do
    {:error, {:invalid_events_list, other}}
  end

  @doc """
  Encode multiple events to a list of JSON-compatible maps.
  """
  @spec encode_events([Event.t()]) :: [map()]
  def encode_events(events) when is_list(events) do
    Enum.map(events, &encode_event/1)
  end
end
