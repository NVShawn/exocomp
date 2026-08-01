# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Repo.Migrations.CreateProposals do
  use Ecto.Migration

  def change do
    create table(:proposals, primary_key: false) do
      add(:proposal_id, :text, primary_key: true)
      add(:organization_id, :text, null: false)
      add(:cluster_id, :text, null: false)
      add(:task_id, :text)
      add(:correlation_id, :text)
      add(:node_id, :text)
      add(:target_id, :text)
      add(:action_id, :text, null: false)
      add(:parameters, :map, null: false, default: %{})
      add(:evidence_refs, :map, null: false, default: %{})
      add(:evidence_hash, :text)
      add(:evidence_observed_at, :utc_datetime_usec)
      add(:evidence_fresh_until, :utc_datetime_usec, null: false)
      add(:evidence_expires_at, :utc_datetime_usec)
      add(:evidence_freshness_until, :utc_datetime_usec)
      add(:expires_at, :utc_datetime_usec, null: false)
      add(:status, :text, null: false, default: "pending")
      add(:decision, :text)
      add(:decided_at, :utc_datetime_usec)
      add(:decided_by_sub, :text)
      add(:decided_by_display_name, :text)
      add(:decided_by_organization_id, :text)
      add(:decision_correlation_id, :text)
      add(:decision_actor, :map)
      add(:denial_reason, :text)
      add(:approval_command_id, :text)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:proposals, [:organization_id, :cluster_id, :status]))
    create(index(:proposals, [:organization_id, :expires_at]))

    create(
      constraint(:proposals, :proposals_status_check,
        check: "status IN ('pending', 'approved', 'denied', 'expired', 'failed', 'executed')"
      )
    )
  end
end
