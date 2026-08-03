# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Repo.Migrations.CreateWebhookEndpoints do
  use Ecto.Migration

  def change do
    create table(:webhook_endpoints, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:organization_id, references(:organizations, type: :binary_id, on_delete: :restrict),
        null: false
      )

      add(:url, :text, null: false)
      add(:subscribed_event_types, {:array, :text}, null: false)
      add(:enabled, :boolean, null: false, default: true)
      add(:encrypted_secret, :binary, null: false)
      add(:encrypted_secret_version, :integer, null: false)
      add(:creator_operator_sub, :text, null: false)
      add(:creator_correlation_id, :text, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:webhook_endpoints, [:organization_id, :id]))

    create(
      constraint(:webhook_endpoints, :webhook_endpoints_subscribed_event_types_not_empty_check,
        check: "cardinality(subscribed_event_types) > 0"
      )
    )

    create(
      constraint(:webhook_endpoints, :webhook_endpoints_encrypted_secret_version_check,
        check: "encrypted_secret_version > 0"
      )
    )
  end
end
