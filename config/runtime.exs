# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
import Config

# Release services receive their protected state locations from the rendered
# systemd unit. Read them when the release boots, not while the immutable
# artifact is compiled inside the builder container.
if config_env() == :prod do
  config :exocomp_coordinator,
    pki_online_state: System.get_env("EXOCOMP_PKI_ONLINE_STATE"),
    pki_offline_root_backup: System.get_env("EXOCOMP_PKI_OFFLINE_ROOT_BACKUP"),
    enrollment_token_store_path: System.get_env("EXOCOMP_ENROLLMENT_TOKEN_STORE")
end
