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
    a2a_tls: a2a_tls

  # Load coordinator configuration and wire Mission Control config into app env.
  # The coordinator config file is loaded at runtime, and if a mission_control block
  # is present and enabled, it is wired into the application environment so the
  # supervisor can conditionally start the Mission Control client.
  case Exocomp.Coordinator.Config.load() do
    {:ok, config} ->
      Application.put_env(:exocomp_coordinator, :mission_control_config, config.mission_control)

    {:error, reason} ->
      fields =
        case reason do
          {:missing_fields, values} when is_list(values) -> Enum.join(values, ", ")
          {:type_errors, values} when is_list(values) -> Enum.join(values, ", ")
          _ -> inspect(reason, limit: 10, printable_limit: 512)
        end

      raise "Invalid coordinator configuration: #{fields}. " <>
              "Fix the file referenced by EXOCOMP_COORDINATOR_CONFIG_FILE before startup."
  end
end
