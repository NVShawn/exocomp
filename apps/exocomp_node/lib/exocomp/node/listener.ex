defmodule Exocomp.Node.Listener do
  @moduledoc """
  GenServer that starts and owns a Bandit mTLS HTTPS server.

  ## Startup sequence

  `init/1` runs the following checks in order, stopping the GenServer (and
  propagating to the supervisor) on the first failure:

  1. Load configuration via `Exocomp.Node.Config.load/1`.
  2. Validate TLS identity via `Exocomp.Node.Identity.validate/1`.
  3. Build TLS options.
  4. Start Bandit via `Bandit.start_link/1`.

  The resulting Bandit process is linked to this GenServer.  If Bandit exits
  abnormally, the GenServer exits and the OTP supervisor handles the restart.

  ## Config reload

  Call `GenServer.call(listener_pid, :reload)` to reload configuration and
  restart the Bandit child atomically.  If the reload succeeds the call
  returns `:ok` and the listener continues.  If the reload fails the call
  returns `{:error, reason}` and the GenServer stops (the OTP supervisor will
  restart it from scratch).

  ## Fail-closed

  Any failure in startup or reload prevents the listener from accepting
  connections.  TLS configuration errors, missing certs, bad key permissions,
  or SAN mismatches all cause the process to stop before the port is opened.
  """

  use GenServer

  require Logger

  alias Exocomp.Node.Config
  alias Exocomp.Node.Identity

  # ── OTP child spec ────────────────────────────────────────────────────────────

  @doc """
  Starts the Listener under a supervisor.

  `opts` is a keyword list; `:config_path` specifies the path to the JSON
  configuration file (optional; falls back to the `EXOCOMP_CONFIG_FILE`
  environment variable, then `/etc/exocomp/config.json`).
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # ── GenServer callbacks ───────────────────────────────────────────────────────

  @impl GenServer
  def init(opts) do
    config_path = opts[:config_path]

    case start_stack(config_path) do
      {:ok, bandit_pid, config} ->
        {:ok, %{config_path: config_path, bandit_pid: bandit_pid, config: config}}

      {:error, reason} ->
        Logger.error("[Listener] startup failed: #{inspect(redact_reason(reason))}")

        {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call(:reload, _from, state) do
    # Stop the existing Bandit process.  A :normal exit does not propagate
    # across the link so this GenServer stays alive.
    GenServer.stop(state.bandit_pid)

    case start_stack(state.config_path) do
      {:ok, bandit_pid, config} ->
        new_state = %{state | bandit_pid: bandit_pid, config: config}
        {:reply, :ok, new_state}

      {:error, reason} ->
        Logger.error("[Listener] reload failed: #{inspect(redact_reason(reason))}")

        # Reply to caller before stopping so they receive the error.
        {:stop, reason, {:error, reason}, state}
    end
  end

  @impl GenServer
  def format_status(status) do
    Map.update(status, :state, status[:state], &redact_state/1)
  end

  # ── Internal helpers ──────────────────────────────────────────────────────────

  defp start_stack(config_path) do
    with {:ok, config} <- load_config(config_path),
         :ok <- Identity.validate(config),
         {:ok, bandit_pid} <- start_bandit(config) do
      {:ok, bandit_pid, config}
    end
  end

  defp load_config(path) do
    case Config.load(path) do
      {:ok, config} ->
        {:ok, config}

      {:error, reason} ->
        Logger.error("[Listener] config load error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp start_bandit(config) do
    ssl_opts = build_tls_opts(config)
    ip = parse_ip(config.listen.host)

    Bandit.start_link(
      plug: {Exocomp.Node.A2ARouter, node_id: config.node_id},
      scheme: :https,
      port: config.listen.port,
      ip: ip,
      startup_log: false,
      thousand_island_options: [transport_options: ssl_opts]
    )
  end

  defp build_tls_opts(config) do
    [
      certfile: config.tls.node_cert,
      keyfile: config.tls.node_key,
      cacertfile: config.tls.ca_cert,
      verify: :verify_peer,
      fail_if_no_peer_cert: true,
      versions: [:"tlsv1.3"]
    ]
  end

  defp parse_ip(host) do
    case :inet.parse_address(String.to_charlist(host)) do
      {:ok, ip} -> ip
      {:error, _} -> {127, 0, 0, 1}
    end
  end

  # Redact the TLS key path from the state included in OTP crash reports.
  defp redact_state(%{config: %Config{} = config} = state) do
    redacted_tls = %{config.tls | node_key: "[REDACTED]"}
    %{state | config: %{config | tls: redacted_tls}}
  end

  defp redact_state(state), do: state

  # Strip cert bytes and key paths from error reasons before logging.
  # The chain reason may embed binary data; the san_mismatch error already
  # omits actual SAN values (only the expected node_id is included, which is
  # not sensitive).
  defp redact_reason({:invalid_chain, _}), do: {:invalid_chain, "[REDACTED]"}
  defp redact_reason(other), do: other
end
