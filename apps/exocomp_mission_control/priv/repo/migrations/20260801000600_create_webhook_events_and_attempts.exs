# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Repo.Migrations.CreateWebhookEventsAndAttempts do
  use Ecto.Migration

  def change do
    create table(:webhook_events, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:organization_id, references(:organizations, type: :binary_id, on_delete: :restrict),
        null: false
      )

      # Unique, url-safe base64 event identifier used in signatures.
      add(:event_id, :text, null: false)
      add(:event_type, :text, null: false)
      # Canonical JSONB payload stored for inspection and replay.
      add(:payload, :map, null: false)
      # Exact JSON bytes used for signing — byte-identical to what is sent.
      add(:body_json, :text, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(
      unique_index(:webhook_events, [:organization_id, :event_id],
        name: :webhook_events_organization_id_event_id_index
      )
    )

    create(index(:webhook_events, [:organization_id, :inserted_at]))

    create table(:webhook_attempts, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(
        :webhook_event_id,
        references(:webhook_events, type: :binary_id, on_delete: :restrict),
        null: false
      )

      add(
        :webhook_endpoint_id,
        references(:webhook_endpoints, type: :binary_id, on_delete: :restrict),
        null: false
      )

      add(:status, :text, null: false, default: "pending")
      add(:http_status, :integer)
      add(:error_reason, :text)
      add(:attempt_number, :integer, null: false, default: 1)
      add(:next_retry_at, :utc_datetime)
      # Delivery timestamp header value stored for auditability.
      add(:delivery_timestamp, :text)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:webhook_attempts, [:webhook_event_id, :webhook_endpoint_id]))
    create(index(:webhook_attempts, [:webhook_endpoint_id, :status]))
    create(index(:webhook_attempts, [:next_retry_at], where: "status = 'pending'"))

    create(
      constraint(:webhook_attempts, :webhook_attempts_attempt_number_check,
        check: "attempt_number > 0"
      )
    )

    create(
      constraint(:webhook_attempts, :webhook_attempts_status_check,
        check: "status IN ('pending', 'success', 'failed', 'terminal_failure')"
      )
    )
  end
end
