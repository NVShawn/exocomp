# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
import Config

pool_size =
  case Integer.parse(System.get_env("EXOCOMP_DB_POOL_SIZE", "10")) do
    {pool_size, ""} when pool_size > 0 -> pool_size
    _ -> 10
  end

# DATABASE_URL is intentionally read in config/runtime.exs so production
# credentials are supplied by the runtime secret store, never compiled into a
# release. Keep only non-secret pool settings in this environment file.
config :exocomp_mission_control, Exocomp.MissionControl.Repo, pool_size: pool_size

config :exocomp_mission_control, Exocomp.MissionControl.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: {:system, "HOSTNAME"}, port: 443],
  server: true

# Do not print debug messages in production
config :logger, level: :notice

# Runtime configuration, not compile-time
# OIDC settings must be provided via environment variables in production
config :exocomp_mission_control,
  oidc_provider_url: System.get_env("OIDC_PROVIDER_URL"),
  oidc_client_id: System.get_env("OIDC_CLIENT_ID"),
  oidc_client_secret: System.get_env("OIDC_CLIENT_SECRET"),
  oidc_redirect_uri: System.get_env("OIDC_REDIRECT_URI")
