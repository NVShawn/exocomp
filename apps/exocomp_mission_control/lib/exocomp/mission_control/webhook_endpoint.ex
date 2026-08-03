# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.WebhookEndpoint do
  @moduledoc """
  Durable, organization-owned webhook endpoint configuration.

  The endpoint's HMAC secret is stored only as AES-GCM ciphertext. It is never
  a field on this schema in plaintext and the ciphertext is excluded from
  `Inspect` so normal logs, exceptions, and database-debug output cannot expose
  it. The public context returns the generated plaintext exactly once from
  creation or rotation; it cannot be recovered by endpoint reads.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Exocomp.MissionControl.Organization

  @derive {Inspect, except: [:encrypted_secret]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "webhook_endpoints" do
    belongs_to(:organization, Organization)
    field(:url, :string)
    field(:subscribed_event_types, {:array, :string})
    field(:enabled, :boolean, default: true)
    field(:encrypted_secret, :binary)
    field(:encrypted_secret_version, :integer)
    field(:creator_operator_sub, :string)
    field(:creator_correlation_id, :string)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          organization_id: Ecto.UUID.t() | nil,
          url: String.t() | nil,
          subscribed_event_types: [String.t()] | nil,
          enabled: boolean() | nil,
          encrypted_secret: binary() | nil,
          encrypted_secret_version: pos_integer() | nil,
          creator_operator_sub: String.t() | nil,
          creator_correlation_id: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @doc "Builds the insert changeset used only by the webhook context."
  @spec create_changeset(t(), map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = endpoint, attrs) when is_map(attrs) do
    endpoint
    |> cast(attrs, [
      :organization_id,
      :url,
      :subscribed_event_types,
      :enabled,
      :encrypted_secret,
      :encrypted_secret_version,
      :creator_operator_sub,
      :creator_correlation_id
    ])
    |> validate_required([
      :organization_id,
      :url,
      :subscribed_event_types,
      :enabled,
      :encrypted_secret,
      :encrypted_secret_version,
      :creator_operator_sub,
      :creator_correlation_id
    ])
    |> validate_length(:url, min: 1, max: 2_048)
    |> validate_length(:subscribed_event_types, min: 1, max: 64)
    |> validate_each_event_type()
    |> validate_length(:creator_operator_sub, min: 1, max: 500)
    |> validate_length(:creator_correlation_id, min: 1, max: 128)
    |> validate_number(:encrypted_secret_version, greater_than: 0)
    |> foreign_key_constraint(:organization_id)
    |> check_constraint(:subscribed_event_types,
      name: :webhook_endpoints_subscribed_event_types_not_empty_check
    )
    |> check_constraint(:encrypted_secret_version,
      name: :webhook_endpoints_encrypted_secret_version_check
    )
  end

  @doc "Builds a whitelist-only configuration update changeset."
  @spec update_changeset(t(), map()) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = endpoint, attrs) when is_map(attrs) do
    endpoint
    |> cast(attrs, [:url, :subscribed_event_types, :enabled])
    |> validate_length(:url, min: 1, max: 2_048)
    |> validate_length(:subscribed_event_types, min: 1, max: 64)
    |> validate_each_event_type()
    |> check_constraint(:subscribed_event_types,
      name: :webhook_endpoints_subscribed_event_types_not_empty_check
    )
  end

  @doc "Builds the secret-only changeset used by rotation."
  @spec secret_changeset(t(), binary(), pos_integer()) :: Ecto.Changeset.t()
  def secret_changeset(%__MODULE__{} = endpoint, encrypted_secret, version)
      when is_binary(encrypted_secret) and is_integer(version) do
    endpoint
    |> cast(
      %{encrypted_secret: encrypted_secret, encrypted_secret_version: version},
      [:encrypted_secret, :encrypted_secret_version]
    )
    |> validate_required([:encrypted_secret, :encrypted_secret_version])
    |> validate_number(:encrypted_secret_version, greater_than: 0)
    |> check_constraint(:encrypted_secret_version,
      name: :webhook_endpoints_encrypted_secret_version_check
    )
  end

  defp validate_each_event_type(changeset) do
    validate_change(changeset, :subscribed_event_types, fn :subscribed_event_types, event_types ->
      if Enum.all?(event_types, &(is_binary(&1) and byte_size(&1) in 1..200)) do
        []
      else
        [subscribed_event_types: "contains an invalid event type"]
      end
    end)
  end
end
