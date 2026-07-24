defmodule Mix.Tasks.Exocomp.Coordinator.Init do
  @shortdoc "Initialize or validate coordinator PKI state"

  @moduledoc """
  Explicitly initializes the coordinator's online PKI state and offline root
  backup.

      EXOCOMP_ROOT_KEY_PASSPHRASE='at least 16 bytes' \
        mix exocomp.coordinator.init \
          --online-state /var/lib/exocomp/pki \
          --offline-root-backup /secure/offline/exocomp-root

  The protection input is accepted only through
  `EXOCOMP_ROOT_KEY_PASSPHRASE`; it must not be supplied on the command line.
  A successful run exits zero for both newly initialized and already
  initialized state. Invalid arguments or protected state exit non-zero.
  """

  use Mix.Task

  alias Exocomp.Coordinator.PKI.Bootstrap

  @requirements ["app.config"]
  @switches [online_state: :string, offline_root_backup: :string]

  @impl Mix.Task
  def run(args) do
    with {options, [], []} <- OptionParser.parse(args, strict: @switches),
         {:ok, online_state} <- fetch_option(options, :online_state),
         {:ok, offline_backup} <- fetch_option(options, :offline_root_backup),
         {:ok, passphrase} <- System.fetch_env("EXOCOMP_ROOT_KEY_PASSPHRASE"),
         {:ok, metadata} <-
           Bootstrap.initialize(
             online_state: online_state,
             offline_backup: offline_backup,
             root_key_protection: {:passphrase, passphrase}
           ) do
      print_success(metadata)
    else
      {_, _, _} ->
        Mix.raise(
          "invalid arguments; require --online-state and --offline-root-backup absolute paths"
        )

      :error ->
        Mix.raise("EXOCOMP_ROOT_KEY_PASSPHRASE is required")

      {:error, :missing_option} ->
        Mix.raise(
          "invalid arguments; require --online-state and --offline-root-backup absolute paths"
        )

      {:error, error} ->
        Mix.raise("PKI initialization failed (#{error.code}): #{error.message}")
    end
  end

  defp fetch_option(options, key) do
    case Keyword.fetch(options, key) do
      {:ok, value} when is_binary(value) and value != "" -> {:ok, value}
      _other -> {:error, :missing_option}
    end
  end

  defp print_success(metadata) do
    outcome =
      case metadata.disposition do
        :initialized -> "PKI_INITIALIZED"
        :already_initialized -> "PKI_ALREADY_INITIALIZED"
      end

    Mix.shell().info(outcome)
    Mix.shell().info("offline_root_backup=#{metadata.offline_backup}")
    Mix.shell().info("root_fingerprint=#{metadata.root_fingerprint}")
  end
end
