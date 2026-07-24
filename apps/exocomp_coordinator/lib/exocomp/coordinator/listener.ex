defmodule Exocomp.Coordinator.Listener do
  @moduledoc """
  GenServer that starts and owns a Bandit mTLS HTTPS server for the
  coordinator A2A service.

  ## Startup sequence

  `init/1` runs the following checks in order, stopping the GenServer (and
  propagating to the supervisor) on the first failure:

  1. Load configuration via `Exocomp.Coordinator.Config.load/1`.
  2. Build TLS options.
  3. Start Bandit via `Bandit.start_link/1`.

  The resulting Bandit process is linked to this GenServer. If Bandit exits
  abnormally, the GenServer exits and the OTP supervisor handles the restart.

  ## Config reload

  Call `GenServer.call(listener_pid, :reload)` to reload configuration and
  restart the Bandit child atomically. If the reload succeeds the call returns
  `:ok`. If the reload fails the call returns `{:error, reason}` and the
  GenServer stops (the OTP supervisor will restart it from scratch).

  ## Fail-closed

  Any failure in startup or reload prevents the listener from accepting
  connections. TLS configuration errors or missing certs cause the process to
  stop before the port is opened.
  """

  use GenServer

  require Logger

  alias Exocomp.Coordinator.Config

  # ── OTP child spec ────────────────────────────────────────────────────────────

  @doc """
  Starts the Listener under a supervisor.

  `opts` is a keyword list; `:config_path` specifies the path to the JSON
  configuration file (optional; falls back to the
  `EXOCOMP_COORDINATOR_CONFIG_FILE` environment variable, then
  `/etc/exocomp/coordinator.json`).
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
        Logger.error("[CoordinatorListener] startup failed: #{inspect(redact_reason(reason))}")
        {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call(:reload, _from, state) do
    GenServer.stop(state.bandit_pid)

    case start_stack(state.config_path) do
      {:ok, bandit_pid, config} ->
        new_state = %{state | bandit_pid: bandit_pid, config: config}
        {:reply, :ok, new_state}

      {:error, reason} ->
        Logger.error("[CoordinatorListener] reload failed: #{inspect(redact_reason(reason))}")
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
         {:ok, bandit_pid} <- start_bandit(config) do
      {:ok, bandit_pid, config}
    end
  end

  defp load_config(path) do
    case Config.load(path) do
      {:ok, config} ->
        {:ok, config}

      {:error, reason} ->
        Logger.error("[CoordinatorListener] config load error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp start_bandit(config) do
    ssl_opts = build_tls_opts(config)
    ip = parse_ip(config.listen.host)

    Bandit.start_link(
      plug: {Exocomp.Coordinator.A2ARouter, coordinator_id: config.coordinator_id},
      scheme: :https,
      port: config.listen.port,
      ip: ip,
      startup_log: false,
      thousand_island_options: [transport_options: ssl_opts]
    )
  end

  defp build_tls_opts(config) do
    [
      certfile: config.tls.coord_cert,
      keyfile: config.tls.coord_key,
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

  defp redact_state(%{config: %Config{} = config} = state) do
    redacted_tls = %{config.tls | coord_key: "[REDACTED]"}
    %{state | config: %{config | tls: redacted_tls}}
  end

  defp redact_state(state), do: state

  defp redact_reason({:invalid_chain, _}), do: {:invalid_chain, "[REDACTED]"}
  defp redact_reason(other), do: other
end
