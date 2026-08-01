# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.DatabaseTest do
  use Exocomp.MissionControl.DataCase, async: true

  alias Exocomp.MissionControl.{
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
    Ecto.Adapters.SQL.Sandbox.mode(Repo, :manual)
    migration_path = Application.app_dir(:exocomp_mission_control, "priv/repo/migrations")

    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      Ecto.Migrator.run(Repo, migration_path, :down, all: true)
      Ecto.Migrator.run(Repo, migration_path, :up, all: true)
    end)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        Ecto.Migrator.run(Repo, migration_path, :down, all: true)
      end)

      Application.stop(:exocomp_mission_control)
    end)

    :ok
  end

  test "the clean database migration can be reverted and reapplied" do
    migration_path = Application.app_dir(:exocomp_mission_control, "priv/repo/migrations")

    assert [20_260_801_000_300, 20_260_801_000_200, 20_260_801_000_000] =
             Ecto.Migrator.run(Repo, migration_path, :down, all: true)

    assert Enum.all?(Ecto.Migrator.migrations(Repo), fn {status, _version, _name} ->
             status == :down
           end)

    assert [20_260_801_000_000, 20_260_801_000_200, 20_260_801_000_300] =
             Ecto.Migrator.run(Repo, migration_path, :up, all: true)
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
