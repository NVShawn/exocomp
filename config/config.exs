# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
import Config

config :exocomp_coordinator,
  require_pki: config_env() != :test,
  pki_online_state: System.get_env("EXOCOMP_PKI_ONLINE_STATE"),
  pki_offline_root_backup: System.get_env("EXOCOMP_PKI_OFFLINE_ROOT_BACKUP"),
  enrollment_token_store_path: System.get_env("EXOCOMP_ENROLLMENT_TOKEN_STORE"),
  ceph_stability_window_ms: if(config_env() == :test, do: 0, else: 30_000),
  ceph_stability_poll_interval_ms: if(config_env() == :test, do: 1, else: 1_000),
  remediation_lifecycle: [
    adapter: Exocomp.Coordinator.RemediationAdapter.Router
  ]

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
