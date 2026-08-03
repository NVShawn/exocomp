# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
import Config

database_url = System.get_env("DATABASE_URL")

port =
  case Integer.parse(System.get_env("PGPORT", "5432")) do
    {port, ""} when port in 1..65_535 -> port
    _ -> 5432
  end

repo_config =
  if is_binary(database_url) and String.trim(database_url) != "" do
    [url: database_url]
  else
    [
      database: System.get_env("PGDATABASE", "exocomp_mission_control_dev"),
      hostname: System.get_env("PGHOST", "localhost"),
      port: port,
      username: System.get_env("PGUSER", "postgres")
    ]
  end

repo_config =
  if Keyword.has_key?(repo_config, :url) or System.get_env("PGPASSWORD") in [nil, ""] do
    repo_config
  else
    Keyword.put(repo_config, :password, System.get_env("PGPASSWORD"))
  end

config :exocomp_mission_control,
       Exocomp.MissionControl.Repo,
       Keyword.merge(repo_config, pool_size: 10)

# For development, we disable any cache and enable debugging/tracing.
config :exocomp_mission_control, Exocomp.MissionControl.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  code_reloader: true,
  check_origin: false,
  watchers: []

# Watch static and templates for browser reloading.
config :exocomp_mission_control, Exocomp.MissionControl.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/exocomp/mission_control/(live|views)/.*(ex)$"
    ]
  ]

config :logger, level: :debug
