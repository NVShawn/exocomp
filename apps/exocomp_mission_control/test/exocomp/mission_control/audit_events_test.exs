# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AuditEventsTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.{AuditEvent, AuditEvents}

  defmodule CaptureRepo do
    def insert(changeset) do
      send(self(), {:insert, changeset})
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end

    def one(query) do
      send(self(), {:one, query})
      nil
    end

    def all(query) do
      send(self(), {:all, query})
      []
    end
  end

  test "record scopes and redacts before repository insertion" do
    organization_id = Ecto.UUID.generate()

    assert {:ok, %AuditEvent{organization_id: ^organization_id} = event} =
             AuditEvents.record(
               organization_id,
               %{
                 actor_type: :operator,
                 actor_sub: "operator-sub",
                 event_type: "command.issued",
                 target: %{
                   "id" => "command-1",
                   "token" => "secret-token",
                   "raw_logs" => ["secret output"]
                 },
                 outcome: :ok,
                 outcome_details: %{private_key: "secret-key"}
               },
               repo: CaptureRepo
             )

    assert event.target == %{
             "id" => "command-1",
             "token" => "[REDACTED]",
             "raw_logs" => "[REDACTED]"
           }

    assert event.outcome_details == %{private_key: "[REDACTED]"}
    assert String.starts_with?(event.event_id, "evt_")
    assert String.starts_with?(event.correlation_id, "corr_")
    assert_received {:insert, %Ecto.Changeset{valid?: true}}
  end

  test "persistence changesets enforce actor identity invariants" do
    organization_id = Ecto.UUID.generate()

    operator =
      AuditEvents.insert_changeset(organization_id, %{
        actor_type: :operator,
        event_type: "approval.granted",
        target: %{},
        outcome: :ok
      })

    refute operator.valid?
    assert "is required for operator audit events" in errors_on(operator).actor_sub

    cluster =
      AuditEvents.insert_changeset(organization_id, %{
        actor_type: :cluster,
        actor_sub: "not-allowed",
        event_type: "cluster.connected",
        target: %{},
        outcome: :ok
      })

    refute cluster.valid?
    assert "is only valid for operator audit events" in errors_on(cluster).actor_sub
    assert "is required for cluster audit events" in errors_on(cluster).cluster_id
  end

  test "all read APIs fail closed without an organization predicate" do
    assert {:error, :organization_required} = AuditEvents.get(nil, "evt-1", repo: CaptureRepo)
    assert {:error, :organization_required} = AuditEvents.list(nil, repo: CaptureRepo)

    assert {:error, :organization_required} =
             AuditEvents.by_correlation(nil, "corr-1", repo: CaptureRepo)

    refute_received {:one, _}
    refute_received {:all, _}
  end

  test "normal context rejects update and delete attempts without touching a repository" do
    assert {:error, :immutable} =
             AuditEvents.update(Ecto.UUID.generate(), "evt-1", %{outcome: :error},
               repo: CaptureRepo
             )

    assert {:error, :immutable} =
             AuditEvents.delete(Ecto.UUID.generate(), "evt-1", repo: CaptureRepo)

    refute_received {:insert, _}
    refute_received {:one, _}
    refute_received {:all, _}
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
  end
end
