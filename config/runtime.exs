# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
import Config

# Release services receive their protected state locations from the rendered
# systemd unit. Read them when the release boots, not while the immutable
# artifact is compiled inside the builder container.
if config_env() == :prod do
  a2a_ca_path = System.get_env("EXOCOMP_TLS_CA_PATH")
  a2a_cert_path = System.get_env("EXOCOMP_A2A_TLS_CERT_PATH")
  a2a_key_path = System.get_env("EXOCOMP_TLS_KEY_PATH")

  a2a_tls =
    if Enum.all?([a2a_ca_path, a2a_cert_path, a2a_key_path], &is_binary/1) do
      [
        cacertfile: String.to_charlist(a2a_ca_path),
        certfile: String.to_charlist(a2a_cert_path),
        keyfile: String.to_charlist(a2a_key_path),
        versions: [:"tlsv1.3", :"tlsv1.2"]
      ]
    else
      []
    end

  config :exocomp_coordinator,
    pki_online_state: System.get_env("EXOCOMP_PKI_ONLINE_STATE"),
    pki_offline_root_backup: System.get_env("EXOCOMP_PKI_OFFLINE_ROOT_BACKUP"),
    enrollment_token_store_path: System.get_env("EXOCOMP_ENROLLMENT_TOKEN_STORE"),
    cluster_invitation_store_path: System.get_env("EXOCOMP_CLUSTER_INVITATION_STORE"),
    a2a_tls: a2a_tls
end
