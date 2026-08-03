# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Repo.Migrations.CreateAuditEvents do
  use Ecto.Migration

  def up do
    create table(:audit_events, primary_key: false) do
      add(:event_id, :text, primary_key: true)

      add(:organization_id, references(:organizations, type: :binary_id, on_delete: :restrict),
        null: false
      )

      add(:cluster_id, :binary_id)
      add(:actor_type, :text, null: false)
      add(:actor_sub, :text)
      add(:actor_display_name, :text)
      add(:event_type, :text, null: false)
      add(:target, :map, null: false)
      add(:outcome, :text, null: false)
      add(:outcome_details, :map)
      add(:correlation_id, :text, null: false)
      add(:occurred_at, :utc_datetime_usec, null: false)
      add(:inserted_at, :utc_datetime_usec, null: false)
    end

    create(
      index(:audit_events, [:organization_id, :occurred_at, :event_id],
        name: :audit_events_organization_chronology_index
      )
    )

    create(
      index(:audit_events, [:organization_id, :correlation_id, :occurred_at, :event_id],
        name: :audit_events_organization_correlation_index
      )
    )

    create(
      constraint(:audit_events, :audit_events_actor_type_check,
        check: "actor_type IN ('operator', 'system', 'cluster')"
      )
    )

    create(
      constraint(:audit_events, :audit_events_outcome_check,
        check: "outcome IN ('ok', 'error')"
      )
    )

    create(
      constraint(:audit_events, :audit_events_actor_identity_check,
        check: """
        (actor_type = 'operator' AND actor_sub IS NOT NULL AND length(actor_sub) > 0)
        OR
        (actor_type IN ('system', 'cluster') AND actor_sub IS NULL AND actor_display_name IS NULL)
        """
      )
    )

    create(
      constraint(:audit_events, :audit_events_cluster_identity_check,
        check: "actor_type <> 'cluster' OR cluster_id IS NOT NULL"
      )
    )

    execute("""
    CREATE FUNCTION reject_audit_event_mutation()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      RAISE EXCEPTION 'audit_events are immutable'
        USING ERRCODE = '55000';
    END;
    $$
    """)

    execute("""
    CREATE TRIGGER audit_events_reject_mutation
    BEFORE UPDATE OR DELETE ON audit_events
    FOR EACH ROW EXECUTE FUNCTION reject_audit_event_mutation()
    """)
  end

  def down do
    execute("DROP TRIGGER IF EXISTS audit_events_reject_mutation ON audit_events")
    execute("DROP FUNCTION IF EXISTS reject_audit_event_mutation()")
    drop(table(:audit_events))
  end
end
