# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Webhooks.WebhookEvent do
  @moduledoc """
  Schema for durable webhook events.

  Events are retained for at least 24 hours to allow replaying failed
  deliveries. Each event has a unique, organization-scoped event ID
  (url-safe base64). The `body_json` field stores the exact JSON bytes
  that are signed; delivery uses these bytes verbatim so that the
  request body is byte-identical to the signed content.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Exocomp.MissionControl.Organization

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "webhook_events" do
    belongs_to(:organization, Organization)
    field(:event_id, :string)
    field(:event_type, :string)
    field(:payload, :map, default: %{})
    # Exact JSON bytes used for signing and delivery.
    field(:body_json, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          organization_id: Ecto.UUID.t() | nil,
          event_id: binary() | nil,
          event_type: binary() | nil,
          payload: map(),
          body_json: binary() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:organization_id, :event_id, :event_type, :payload, :body_json])
    |> validate_required([:organization_id, :event_id, :event_type, :payload, :body_json])
    |> unique_constraint(:event_id,
      name: :webhook_events_organization_id_event_id_index
    )
  end

  @doc """
  Generates a unique event ID (url-safe base64 without padding).
  """
  @spec generate_event_id() :: binary()
  def generate_event_id do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64(padding: false)
  end
end
