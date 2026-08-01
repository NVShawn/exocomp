# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.Acknowledgement do
  @moduledoc """
  A Mission Control acknowledgement of cluster event delivery.

  The coordinator maintains a durable event outbox and expects Mission Control
  to acknowledge events for durability and idempotency. Acknowledgements carry:
  - `acknowledged_at`: ISO8601 timestamp when the acknowledgement was issued
  - `highest_seq`: Highest contiguous cluster sequence number committed
  - `session_id`: Session identifier to prevent replay across reconnections

  Acknowledgements are cumulative: acknowledging sequence N implicitly
  acknowledges all sequences 1..N. Mission Control uses the sequence number
  to detect gaps in event delivery and trigger replay.
  """

  @enforce_keys [:acknowledged_at, :highest_seq, :session_id]

  defstruct acknowledged_at: nil,
            highest_seq: nil,
            session_id: nil

  @type t :: %__MODULE__{
          acknowledged_at: String.t(),
          highest_seq: integer(),
          session_id: String.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(params) when is_map(params) do
    with {:ok, acknowledged_at} <- validate_acknowledged_at(params),
         {:ok, highest_seq} <- validate_highest_seq(params),
         {:ok, session_id} <- validate_session_id(params) do
      {:ok,
       %__MODULE__{
         acknowledged_at: acknowledged_at,
         highest_seq: highest_seq,
         session_id: session_id
       }}
    end
  end

  defp validate_acknowledged_at(params) do
    case Map.get(params, "acknowledged_at") do
      ts when is_binary(ts) and byte_size(ts) > 0 ->
        {:ok, ts}

      nil ->
        {:error, :missing_acknowledged_at}

      other ->
        {:error, {:invalid_acknowledged_at, other}}
    end
  end

  defp validate_highest_seq(params) do
    case Map.get(params, "highest_seq") do
      seq when is_integer(seq) and seq >= 0 ->
        {:ok, seq}

      nil ->
        {:error, :missing_highest_seq}

      other ->
        {:error, {:invalid_highest_seq, other}}
    end
  end

  defp validate_session_id(params) do
    case Map.get(params, "session_id") do
      id when is_binary(id) and byte_size(id) > 0 ->
        {:ok, id}

      nil ->
        {:error, :missing_session_id}

      other ->
        {:error, {:invalid_session_id, other}}
    end
  end
end
