# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Command do
  @moduledoc """
  Durable server-to-cluster command stored in the Mission Control outbox.

  A command remains `pending` after a socket write. It becomes
  `acknowledged` only after the authenticated cluster acknowledges its command
  ID, so a lost connection is always safe to replay.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @statuses ~w(pending acknowledged expired)
  @valid_kinds ~w(approval.decide conversation.message cluster.disconnect)
  @max_payload_bytes 102_400

  @type t :: %__MODULE__{
          command_id: String.t(),
          kind: String.t(),
          issued_at: DateTime.t(),
          expires_at: DateTime.t(),
          organization_id: String.t(),
          cluster_id: String.t(),
          payload: map(),
          status: String.t(),
          acknowledged_at: DateTime.t() | nil
        }

  @primary_key false
  schema "command_outbox" do
    field(:command_id, :string, primary_key: true)
    field(:kind, :string)
    field(:issued_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)
    field(:organization_id, :string)
    field(:cluster_id, :string)
    field(:payload, :map)
    field(:status, :string, default: "pending")
    field(:acknowledged_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end

  @doc "The command kinds supported by both protocol peers."
  @spec valid_kinds() :: [String.t()]
  def valid_kinds, do: @valid_kinds

  @doc false
  @spec statuses() :: [String.t()]
  def statuses, do: @statuses

  @doc "Maximum JSON-encoded payload size accepted by the protocol."
  @spec max_payload_bytes() :: pos_integer()
  def max_payload_bytes, do: @max_payload_bytes

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = command, attrs) when is_map(attrs) do
    command
    |> cast(attrs, [
      :command_id,
      :kind,
      :issued_at,
      :expires_at,
      :organization_id,
      :cluster_id,
      :payload,
      :status,
      :acknowledged_at
    ])
    |> validate_required([
      :command_id,
      :kind,
      :issued_at,
      :expires_at,
      :organization_id,
      :cluster_id,
      :payload
    ])
    |> validate_inclusion(:kind, @valid_kinds)
    |> validate_inclusion(:status, @statuses)
    |> validate_length(:command_id, min: 1, max: 128)
    |> validate_length(:organization_id, min: 1, max: 128)
    |> validate_length(:cluster_id, min: 1, max: 128)
    |> validate_payload()
    |> validate_expiry()
    |> unique_constraint(:command_id, name: :command_outbox_pkey)
    |> check_constraint(:status, name: :command_outbox_status_check)
    |> check_constraint(:expires_at, name: :command_outbox_expires_after_issued_check)
  end

  @doc "Builds the protocol envelope sent to the coordinator."
  @spec envelope(t()) :: map()
  def envelope(%__MODULE__{} = command) do
    %{
      "command_id" => command.command_id,
      "kind" => command.kind,
      "issued_at" => DateTime.to_iso8601(command.issued_at),
      "expires_at" => DateTime.to_iso8601(command.expires_at),
      "payload" => command.payload
    }
  end

  defp validate_payload(changeset) do
    validate_change(changeset, :payload, fn :payload, payload ->
      case Jason.encode(payload) do
        {:ok, encoded} when byte_size(encoded) <= @max_payload_bytes -> []
        {:ok, _encoded} -> [payload: "exceeds the maximum protocol size"]
        {:error, _reason} -> [payload: "must be JSON encodable"]
      end
    end)
  end

  defp validate_expiry(changeset) do
    validate_change(changeset, :expires_at, fn :expires_at, expires_at ->
      case get_field(changeset, :issued_at) do
        %DateTime{} = issued_at ->
          if DateTime.compare(expires_at, issued_at) == :gt,
            do: [],
            else: [expires_at: "must be after issued_at"]

        _other ->
          []
      end
    end)
  end
end
