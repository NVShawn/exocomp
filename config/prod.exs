# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
import Config

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
