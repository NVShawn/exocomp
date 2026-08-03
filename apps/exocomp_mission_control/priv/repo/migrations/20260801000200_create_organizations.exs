# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :text, null: false)
      add(:slug, :text, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:organizations, [:slug], name: :organizations_slug_index))
  end
end
