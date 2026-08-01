# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.MissionControl.Command do
  @moduledoc """
  A Mission Control server-to-cluster command envelope.

  Commands are issued by Mission Control operators to clusters for approval,
  denial, or other administrative actions. They include:
  - `command_id`: Unique identifier for deduplication
  - `kind`: Command type from the allow-list
  - `issued_at`: ISO8601 timestamp when issued
  - `expires_at`: ISO8601 timestamp when command expires
  - `payload`: Type-specific command parameters, bounded by size limits

  Commands remain in a durable server outbox until the active cluster session
  acknowledges them or they expire. Commands are validated but not executed
  by the cluster until an explicit acknowledgement is received and verified.

  Valid command kinds (initial allow-list):
  - `approval.decide` — operator decision on a typed remedy proposal
  - `conversation.message` — operator message for cluster-local reasoning
  - `cluster.disconnect` — administrative cluster disconnection
  """

  @enforce_keys [:command_id, :kind, :issued_at, :expires_at, :payload]

  defstruct command_id: nil,
            kind: nil,
            issued_at: nil,
            expires_at: nil,
            payload: nil

  @valid_kinds [
    "approval.decide",
    "conversation.message",
    "cluster.disconnect"
  ]

  # Maximum payload size in bytes (100 KiB, consistent with events)
  @max_payload_size 102_400

  @type t :: %__MODULE__{
          command_id: String.t(),
          kind: String.t(),
          issued_at: String.t(),
          expires_at: String.t(),
          payload: map()
        }

  @spec valid_kinds() :: [String.t()]
  def valid_kinds, do: @valid_kinds

  @spec max_payload_size() :: integer()
  def max_payload_size, do: @max_payload_size

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(params) when is_map(params) do
    with {:ok, command_id} <- validate_command_id(params),
         {:ok, kind} <- validate_kind(params),
         {:ok, issued_at} <- validate_issued_at(params),
         {:ok, expires_at} <- validate_expires_at(params),
         :ok <- validate_expiry_order(issued_at, expires_at),
         {:ok, payload} <- validate_payload(params) do
      {:ok,
       %__MODULE__{
         command_id: command_id,
         kind: kind,
         issued_at: issued_at,
         expires_at: expires_at,
         payload: payload
       }}
    end
  end

  defp validate_command_id(params) do
    case Map.get(params, "command_id") do
      id when is_binary(id) and byte_size(id) > 0 ->
        {:ok, id}

      nil ->
        {:error, :missing_command_id}

      other ->
        {:error, {:invalid_command_id, other}}
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

  defp validate_issued_at(params) do
    case Map.get(params, "issued_at") do
      ts when is_binary(ts) and byte_size(ts) > 0 ->
        {:ok, ts}

      nil ->
        {:error, :missing_issued_at}

      other ->
        {:error, {:invalid_issued_at, other}}
    end
  end

  defp validate_expires_at(params) do
    case Map.get(params, "expires_at") do
      ts when is_binary(ts) and byte_size(ts) > 0 ->
        {:ok, ts}

      nil ->
        {:error, :missing_expires_at}

      other ->
        {:error, {:invalid_expires_at, other}}
    end
  end

  defp validate_expiry_order(issued_at, expires_at) do
    case {issued_at, expires_at} do
      {issued, expires} when issued < expires -> :ok
      {issued, expires} when issued == expires -> :ok
      _not_ordered -> {:error, :expires_before_issued}
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
