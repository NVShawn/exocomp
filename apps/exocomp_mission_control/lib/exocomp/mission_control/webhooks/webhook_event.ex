# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Webhooks.WebhookEvent do
  @moduledoc """
  Schema for durable webhook events.

  Events are retained for at least 24 hours to allow replaying failed deliveries.
  Each event has a unique ID (url-safe base64), event type, and JSON payload.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          organization_id: Ecto.UUID.t() | nil,
          event_id: binary,
          event_type: binary,
          payload: map,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "webhook_events" do
    field(:organization_id, Ecto.UUID)
    field(:event_id, :string)
    field(:event_type, :string)
    field(:payload, :map, default: %{})

    timestamps(type: :naive_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:organization_id, :event_id, :event_type, :payload])
    |> validate_required([:organization_id, :event_id, :event_type, :payload])
    |> unique_constraint(:event_id, name: :webhook_events_organization_id_event_id_index)
  end

  @doc """
  Generates a unique event ID (url-safe base64 without padding).
  """
  @spec generate_event_id() :: binary
  def generate_event_id do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64(padding: false)
  end
end
