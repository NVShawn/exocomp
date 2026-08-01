# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.DatabaseConfigTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.DatabaseConfig

  test "uses DATABASE_URL for local environments when supplied" do
    env = %{"DATABASE_URL" => "postgres://db.example/mission_control"}

    assert [url: "postgres://db.example/mission_control"] =
             DatabaseConfig.local_repo_config(:test, &Map.get(env, &1))
  end

  test "builds password-free local defaults from PG variables" do
    env = %{"PGHOST" => "db.internal", "PGPORT" => "5544", "PGUSER" => "operator"}

    assert [
             database: "exocomp_mission_control_dev",
             hostname: "db.internal",
             port: 5544,
             username: "operator"
           ] = DatabaseConfig.local_repo_config(:dev, &Map.get(env, &1))
  end

  test "uses a supplied local password without inventing one" do
    env = %{"PGPASSWORD" => "from-secret-store"}

    assert [password: "from-secret-store"] =
             Keyword.take(DatabaseConfig.local_repo_config(:test, &Map.get(env, &1)), [:password])
  end

  test "falls back to a safe port for malformed PGPORT" do
    env = %{"PGPORT" => "not-a-port"}
    config = DatabaseConfig.local_repo_config(:test, &Map.get(env, &1))

    assert config[:port] == 5432
  end

  test "production requires a non-blank DATABASE_URL" do
    env = %{"DATABASE_URL" => "  "}

    error =
      assert_raise RuntimeError, fn ->
        DatabaseConfig.production_repo_config!(&Map.get(env, &1))
      end

    assert error.message =~ "DATABASE_URL"
    assert byte_size(error.message) < 256
  end

  test "production passes the URL through without exposing it in validation" do
    env = %{"DATABASE_URL" => "postgres://db.example/mission_control"}

    assert [url: "postgres://db.example/mission_control"] =
             DatabaseConfig.production_repo_config!(&Map.get(env, &1))
  end
end
