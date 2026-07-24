import Config

config :exocomp_coordinator,
  require_pki: config_env() != :test,
  pki_online_state: System.get_env("EXOCOMP_PKI_ONLINE_STATE"),
  pki_offline_root_backup: System.get_env("EXOCOMP_PKI_OFFLINE_ROOT_BACKUP"),
  enrollment_token_store_path: System.get_env("EXOCOMP_ENROLLMENT_TOKEN_STORE")
