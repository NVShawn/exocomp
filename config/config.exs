# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
import Config

config :exocomp_coordinator,
  require_pki: config_env() != :test,
  pki_online_state: System.get_env("EXOCOMP_PKI_ONLINE_STATE"),
  pki_offline_root_backup: System.get_env("EXOCOMP_PKI_OFFLINE_ROOT_BACKUP"),
  enrollment_token_store_path: System.get_env("EXOCOMP_ENROLLMENT_TOKEN_STORE"),
  cluster_id: System.get_env("EXOCOMP_CLUSTER_ID"),
  event_outbox_path:
    System.get_env("EXOCOMP_EVENT_OUTBOX_PATH") ||
      if(config_env() == :prod,
        do: "/var/lib/exocomp-coordinator/event_outbox.json",
        else:
          Path.join(System.tmp_dir!(), "exocomp-coordinator-event-outbox-#{config_env()}.json")
      ),
  event_store_path:
    if(config_env() == :prod,
      do: System.get_env("EXOCOMP_EVENT_STORE_PATH", "/var/lib/exocomp-coordinator/events.bin"),
      else: nil
    )

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
