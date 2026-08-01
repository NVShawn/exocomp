# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :exocomp_mission_control, Exocomp.MissionControl.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Test OIDC configuration
config :exocomp_mission_control,
  oidc_provider_url: "http://localhost:9999",
  oidc_client_id: "test-client",
  oidc_client_secret: "test-secret",
  oidc_redirect_uri: "http://localhost:4002/auth/callback"
