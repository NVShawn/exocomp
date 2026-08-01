# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.OrganizationScopedRecord do
  @moduledoc "Example tenant-owned record used to pin scoping conventions."

  use Ecto.Schema
  import Ecto.Changeset

  alias Exocomp.MissionControl.Organization

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "organization_scope_examples" do
    field(:key, :string)
    field(:value, :map, default: %{})

    belongs_to(:organization, Organization)
    timestamps(type: :utc_datetime_usec)
  end

  @doc "Validates the example tenant-owned record."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = record, attrs) when is_map(attrs) do
    record
    |> cast(attrs, [:key, :value, :organization_id])
    |> validate_required([:key, :organization_id])
    |> validate_length(:key, min: 1, max: 200)
    |> foreign_key_constraint(:organization_id)
    |> unique_constraint(:key, name: :organization_scope_examples_organization_id_key_index)
  end

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          key: String.t() | nil,
          value: map(),
          organization_id: Ecto.UUID.t() | nil,
          organization: Organization.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
