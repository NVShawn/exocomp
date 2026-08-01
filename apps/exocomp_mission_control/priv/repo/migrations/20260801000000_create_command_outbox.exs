# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Repo.Migrations.CreateCommandOutbox do
  use Ecto.Migration

  def change do
    create table(:command_outbox, primary_key: false) do
      add(:command_id, :text, primary_key: true)
      add(:kind, :text, null: false)
      add(:issued_at, :utc_datetime_usec, null: false)
      add(:expires_at, :utc_datetime_usec, null: false)
      add(:organization_id, :text, null: false)
      add(:cluster_id, :text, null: false)
      add(:payload, :map, null: false)
      add(:status, :text, null: false, default: "pending")
      add(:acknowledged_at, :utc_datetime_usec)

      timestamps(type: :utc_datetime_usec)
    end

    create(
      index(:command_outbox, [:organization_id, :cluster_id, :status, :expires_at],
        name: :command_outbox_pending_delivery_idx
      )
    )

    create(
      constraint(:command_outbox, :command_outbox_status_check,
        check: "status IN ('pending', 'acknowledged', 'expired')"
      )
    )
  end
end
