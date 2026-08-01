# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Command do
  @moduledoc """
  Durable server-to-cluster command stored in the Mission Control outbox.

  A command is considered delivered only after the coordinator acknowledges
  it.  The `status` field therefore intentionally has no `delivered` state:
  sending a command is retryable and is not execution.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending acknowledged expired)

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

  @doc false
  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(command, attrs) do
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
    |> validate_inclusion(:status, @statuses)
    |> validate_length(:command_id, min: 1, max: 128)
    |> validate_length(:kind, min: 1, max: 128)
    |> validate_length(:organization_id, min: 1, max: 128)
    |> validate_length(:cluster_id, min: 1, max: 128)
    |> validate_change(:payload, &validate_payload/2)
    |> unique_constraint(:command_id, name: :command_outbox_pkey)
  end

  @doc false
  @spec statuses() :: [String.t()]
  def statuses, do: @statuses

  defp validate_payload(:payload, payload) when is_map(payload), do: []
  defp validate_payload(:payload, _payload), do: [payload: "must be a map"]
end
