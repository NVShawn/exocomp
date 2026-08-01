# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Webhooks.Webhook do
  @moduledoc """
  Schema for webhook endpoints.

  Webhook endpoints are registered by admins for delivery of signed events.
  Each endpoint has a unique secret, event type subscriptions, and state
  tracking for delivery attempts.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          organization_id: Ecto.UUID.t() | nil,
          url: binary,
          secret_hash: binary,
          events: [binary],
          enabled: boolean,
          timeout_ms: non_neg_integer,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "webhooks" do
    field(:organization_id, Ecto.UUID)
    field(:url, :string)
    field(:secret_hash, :binary)
    field(:events, {:array, :string}, default: [])
    field(:enabled, :boolean, default: true)
    field(:timeout_ms, :integer, default: 30_000)

    timestamps(type: :naive_datetime)
  end

  @doc false
  def changeset(webhook, attrs) do
    webhook
    |> cast(attrs, [:organization_id, :url, :secret_hash, :events, :enabled, :timeout_ms])
    |> validate_required([:organization_id, :url, :secret_hash, :events])
    |> validate_length(:url, min: 1, max: 2048)
    |> validate_format(:url, ~r/^https?:\/\//)
    |> validate_timeout_ms()
  end

  defp validate_timeout_ms(changeset) do
    validate_change(changeset, :timeout_ms, fn :timeout_ms, timeout_ms ->
      if timeout_ms > 0 and timeout_ms <= 300_000 do
        []
      else
        [timeout_ms: "must be between 1 and 300000 ms"]
      end
    end)
  end
end
