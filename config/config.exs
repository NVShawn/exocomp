# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
import Config

config :exocomp_coordinator,
  require_pki: config_env() != :test,
  pki_online_state: System.get_env("EXOCOMP_PKI_ONLINE_STATE"),
  pki_offline_root_backup: System.get_env("EXOCOMP_PKI_OFFLINE_ROOT_BACKUP"),
  enrollment_token_store_path: System.get_env("EXOCOMP_ENROLLMENT_TOKEN_STORE")

replay_ledger_path =
  if config_env() == :prod do
    "/var/lib/exocomp-node/replay_ledger.dets"
  else
    Path.join(System.tmp_dir!(), "exocomp_replay_ledger_#{config_env()}.dets")
  end

config :exocomp_node, :replay_ledger_path, replay_ledger_path

recovery_audit_path =
  if config_env() == :prod do
    "/var/lib/exocomp-node/recovery-audit.jsonl"
  else
    Path.join(System.tmp_dir!(), "exocomp_recovery_audit_#{config_env()}.jsonl")
  end

config :exocomp_node, :recovery_audit_path, recovery_audit_path

# Mission Control configuration
config :exocomp_mission_control,
  ecto_repos: [Exocomp.MissionControl.Repo]

config :exocomp_mission_control, Exocomp.MissionControl.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  url: [host: "localhost"],
  server: false,
  render_errors: [
    formats: [html: Exocomp.MissionControl.ErrorHTML],
    layout: false
  ],
  pubsub_server: Exocomp.MissionControl.PubSub,
  live_view: [signing_salt: "mission-control-live-view-signing-salt"]

if config_env() != :prod do
  config :exocomp_mission_control, Exocomp.MissionControl.Endpoint,
    secret_key_base: "mission-control-test-secret-key-base-at-least-sixty-four-bytes-long-2026"
end

# OIDC Configuration - can be overridden by environment variables
config :exocomp_mission_control,
  oidc_provider_url: System.get_env("OIDC_PROVIDER_URL"),
  oidc_client_id: System.get_env("OIDC_CLIENT_ID"),
  oidc_client_secret: System.get_env("OIDC_CLIENT_SECRET"),
  oidc_redirect_uri: System.get_env("OIDC_REDIRECT_URI", "http://localhost:4000/auth/callback")

# Telemetry
config :telemetry, :metrics, []

import_config "#{config_env()}.exs"
