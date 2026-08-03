# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.DatabaseTest do
  # This module tears the shared schema down and rebuilds it in setup_all, so it
  # must not race the other Mission Control database users.
  use Exocomp.MissionControl.DataCase, async: false

  alias Exocomp.MissionControl.{
    AuditEvent,
    AuditEvents,
    OrganizationScopedRecord,
    OrganizationScopedRecords,
    Organizations,
    Repo
  }

  if System.get_env("EXOCOMP_RUN_DB_TESTS") == "1" do
    @moduletag :database
  else
    @moduletag skip: "set EXOCOMP_RUN_DB_TESTS=1 to run against PostgreSQL"
  end

  setup_all do
    {:ok, _applications} = Application.ensure_all_started(:exocomp_mission_control)
    migration_path = Application.app_dir(:exocomp_mission_control, "priv/repo/migrations")

    # Migrator transactions run in supervised tasks and need independent pool
    # checkouts. Auto mode keeps those checkouts outside per-test sandboxes.
    Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)

    assert [
             20_260_801_000_400,
             20_260_801_000_300,
             20_260_801_000_200,
             20_260_801_000_000
           ] = Ecto.Migrator.run(Repo, migration_path, :down, all: true)

    assert Enum.all?(Ecto.Migrator.migrations(Repo), fn {status, _version, _name} ->
             status == :down
           end)

    assert [
             20_260_801_000_000,
             20_260_801_000_200,
             20_260_801_000_300,
             20_260_801_000_400
           ] = Ecto.Migrator.run(Repo, migration_path, :up, all: true)

    Ecto.Adapters.SQL.Sandbox.mode(Repo, :manual)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)
      Ecto.Migrator.run(Repo, migration_path, :down, all: true)

      Application.stop(:exocomp_mission_control)
    end)

    :ok
  end

  test "audit events persist every actor type, redact secrets, and remain tenant scoped" do
    {organization_a, organization_b} = create_organizations()
    correlation_id = "corr_database_acceptance"
    cluster_id = Ecto.UUID.generate()

    assert {:ok, operator_event} =
             AuditEvents.record(organization_a.id, %{
               actor_type: :operator,
               actor_sub: "operator-sub",
               actor_display_name: "operator@example.com",
               event_type: "approval.granted",
               target: %{
                 "type" => "proposal",
                 "token" => "plaintext-token",
                 "raw_logs" => ["arbitrary secret log"]
               },
               outcome: :ok,
               outcome_details: %{"private_key" => "plaintext-key"},
               correlation_id: correlation_id,
               occurred_at: ~U[2026-08-03 10:00:00.000000Z]
             })

    assert {:ok, _system_event} =
             AuditEvents.record(organization_a.id, %{
               actor_type: :system,
               event_type: "command.expired",
               target: %{"type" => "command"},
               outcome: :error,
               correlation_id: correlation_id,
               occurred_at: ~U[2026-08-03 10:00:01.000000Z]
             })

    assert {:ok, _cluster_event} =
             AuditEvents.record(organization_a.id, %{
               actor_type: :cluster,
               cluster_id: cluster_id,
               event_type: "cluster.connected",
               target: %{"type" => "cluster"},
               outcome: :ok,
               correlation_id: correlation_id,
               occurred_at: ~U[2026-08-03 10:00:02.000000Z]
             })

    assert [operator, system, cluster] =
             AuditEvents.by_correlation(organization_a.id, correlation_id)

    assert [operator.event_id, system.event_id, cluster.event_id] ==
             Enum.map(AuditEvents.list(organization_a.id), & &1.event_id)

    assert operator.target["token"] == "[REDACTED]"
    assert operator.target["raw_logs"] == "[REDACTED]"
    assert operator.outcome_details["private_key"] == "[REDACTED]"
    refute inspect(operator) =~ "plaintext-token"
    refute inspect(operator) =~ "plaintext-key"
    refute inspect(operator) =~ "arbitrary secret log"

    assert operator.actor_type == :operator
    assert system.actor_type == :system
    assert cluster.actor_type == :cluster
    assert cluster.cluster_id == cluster_id

    assert nil == AuditEvents.get(organization_b.id, operator_event.event_id)
    assert [] == AuditEvents.by_correlation(organization_b.id, correlation_id)
  end

  test "audit inserts participate in transaction rollback" do
    {organization, _other} = create_organizations()
    correlation_id = "corr_rolled_back"

    transaction =
      Ecto.Multi.new()
      |> AuditEvents.put_in_multi(:audit, organization.id, %{
        actor_type: :system,
        event_type: "command.issued",
        target: %{"type" => "command"},
        outcome: :ok,
        correlation_id: correlation_id
      })
      |> Ecto.Multi.run(:forced_failure, fn _repo, _changes -> {:error, :forced} end)

    assert {:error, :forced_failure, :forced, %{audit: %AuditEvent{}}} =
             Repo.transaction(transaction)

    assert [] == AuditEvents.by_correlation(organization.id, correlation_id)
  end

  test "normal contexts and the database both reject audit mutation" do
    {organization, _other} = create_organizations()

    assert {:ok, event} =
             AuditEvents.record(organization.id, %{
               actor_type: :system,
               event_type: "system.started",
               target: %{},
               outcome: :ok
             })

    assert {:error, :immutable} =
             AuditEvents.update(organization.id, event.event_id, %{outcome: :error})

    assert {:error, :immutable} = AuditEvents.delete(organization.id, event.event_id)

    assert_raise Postgrex.Error, ~r/audit_events are immutable/, fn ->
      Repo.transaction(fn ->
        event
        |> Ecto.Changeset.change(event_type: "system.changed")
        |> Repo.update!()
      end)
    end

    assert %AuditEvent{event_type: "system.started"} =
             AuditEvents.get(organization.id, event.event_id)

    assert_raise Postgrex.Error, ~r/audit_events are immutable/, fn ->
      Repo.transaction(fn -> Repo.delete!(event) end)
    end

    assert %AuditEvent{} = AuditEvents.get(organization.id, event.event_id)
  end

  test "a concurrent sandbox owner cannot observe another test's uncommitted schema" do
    Repo.query!("CREATE TABLE mission_control_sandbox_probe (value text)")

    task =
      Task.async(fn ->
        owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Repo, shared: false)

        try do
          Repo.query!("SELECT to_regclass('public.mission_control_sandbox_probe')")
        after
          Ecto.Adapters.SQL.Sandbox.stop_owner(owner)
        end
      end)

    assert %{rows: [[nil]]} = Task.await(task)
  end

  test "organization-owned inserts fail closed and records cannot cross organization scope" do
    {organization_a, organization_b} = create_organizations()

    assert {:error, changeset} = OrganizationScopedRecords.create(nil, %{key: "setting"})
    assert "organization_id is required" in errors_on(changeset).organization_id
    assert Repo.aggregate(OrganizationScopedRecord, :count) == 0

    assert {:ok, record} =
             OrganizationScopedRecords.create(organization_a.id, %{key: "setting", value: %{}})

    assert nil == OrganizationScopedRecords.get(organization_b.id, record.id)

    assert {:error, :not_found} =
             OrganizationScopedRecords.update(organization_b.id, record.id, %{key: "changed"})

    assert {:error, :not_found} = OrganizationScopedRecords.delete(organization_b.id, record.id)

    assert %OrganizationScopedRecord{key: "setting"} =
             OrganizationScopedRecords.get(organization_a.id, record.id)

    assert [] = OrganizationScopedRecords.list(organization_b.id)

    assert [%OrganizationScopedRecord{id: record_id}] =
             OrganizationScopedRecords.list(organization_a.id)

    assert record_id == record.id
  end

  test "tenant examples enforce organization foreign keys and per-organization uniqueness" do
    {organization_a, organization_b} = create_organizations()

    assert {:ok, _record} = OrganizationScopedRecords.create(organization_a.id, %{key: "setting"})
    assert {:ok, _record} = OrganizationScopedRecords.create(organization_b.id, %{key: "setting"})

    assert {:error, duplicate_changeset} =
             OrganizationScopedRecords.create(organization_a.id, %{key: "setting"})

    assert "has already been taken" in errors_on(duplicate_changeset).key

    assert {:error, foreign_key_changeset} =
             OrganizationScopedRecords.create(Ecto.UUID.generate(), %{key: "orphan"})

    assert "does not exist" in errors_on(foreign_key_changeset).organization_id
  end

  defp create_organizations do
    {:ok, organization_a} =
      Organizations.create(%{name: "Organization A", slug: "organization-a"})

    {:ok, organization_b} =
      Organizations.create(%{name: "Organization B", slug: "organization-b"})

    {organization_a, organization_b}
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
  end
end
