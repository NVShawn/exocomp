# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Repo.Migrations.CreateOrganizationScopeExamples do
  use Ecto.Migration

  def change do
    create table(:organization_scope_examples, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:organization_id, references(:organizations, type: :binary_id, on_delete: :restrict),
        null: false
      )

      add(:key, :text, null: false)
      add(:value, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create(
      unique_index(:organization_scope_examples, [:organization_id, :key],
        name: :organization_scope_examples_organization_id_key_index
      )
    )
  end
end
