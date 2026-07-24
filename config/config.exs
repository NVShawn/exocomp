import Config

replay_ledger_path =
  if config_env() == :prod do
    "/var/lib/exocomp/replay_ledger.dets"
  else
    Path.join(System.tmp_dir!(), "exocomp_replay_ledger_#{config_env()}.dets")
  end

config :exocomp_node, :replay_ledger_path, replay_ledger_path
