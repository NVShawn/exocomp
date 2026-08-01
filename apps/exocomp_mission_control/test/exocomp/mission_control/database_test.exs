# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.DatabaseTest do
  use Exocomp.MissionControl.DataCase, async: true

  alias Exocomp.MissionControl.Repo

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

    assert [20_260_801_000_000] = Ecto.Migrator.run(Repo, migration_path, :down, all: true)

    assert [{:down, 20_260_801_000_000, _name}] =
             Ecto.Migrator.migrations(Repo)
             |> Enum.filter(fn {_status, version, _name} -> version == 20_260_801_000_000 end)

    assert [20_260_801_000_000] = Ecto.Migrator.run(Repo, migration_path, :up, all: true)
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
end
