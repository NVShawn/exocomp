# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
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

  alias Exocomp.ClusterProfile.Ceph
  alias Exocomp.ClusterProfile.Ceph.Validator
  alias Exocomp.Coordinator.{Audit, Config, ProfileCoverage}

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
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  # ── GenServer callbacks ───────────────────────────────────────────────────────

  @impl GenServer
  def init(opts) do
    config_path = opts[:config_path]

    case start_stack(config_path, opts) do
      {:ok, bandit_pid, config} ->
        {:ok, %{config_path: config_path, bandit_pid: bandit_pid, config: config, opts: opts}}

      {:error, reason} ->
        Logger.error("[CoordinatorListener] startup failed: #{inspect(redact_reason(reason))}")
        {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call(:reload, _from, state) do
    GenServer.stop(state.bandit_pid)

    case start_stack(state.config_path, state.opts) do
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

  defp start_stack(config_path, opts) do
    with {:ok, config} <- load_config(config_path),
         {:ok, config} <- validate_profile_coverage(config, opts),
         {:ok, bandit_pid} <- start_bandit(config, opts) do
      {:ok, bandit_pid, config}
    end
  end

  defp load_config(path) do
    case Config.load(path, allow_invalid_ceph_profile: true) do
      {:ok, config} ->
        {:ok, config}

      {:error, reason} ->
        Logger.error("[CoordinatorListener] config load error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp validate_profile_coverage(
         %Config{ceph_profile: nil, ceph_profile_error: nil} = config,
         opts
       ) do
    mark_profile_available(opts)
    {:ok, config}
  end

  defp validate_profile_coverage(
         %Config{ceph_profile: nil, ceph_profile_error: error} = config,
         opts
       ) do
    failure = %{
      code: :invalid_configuration,
      field: "cluster_profiles.ceph",
      path: nil,
      mode: nil,
      uid: nil,
      severity: :error,
      action_required: invalid_profile_action(error)
    }

    degrade_profile(opts, [failure], nil)
    {:ok, config}
  end

  defp validate_profile_coverage(
         %Config{ceph_profile: %Ceph.Config{} = ceph_profile} = config,
         opts
       ) do
    stat_fn = Keyword.get(opts, :ceph_stat_fn, &File.stat/1)

    case Validator.validate(ceph_profile, stat_fn) do
      :ok ->
        mark_profile_available(opts)
        {:ok, config}

      {:error, failures} ->
        degrade_profile(opts, failures, ceph_profile.version)
        {:ok, config}
    end
  end

  defp mark_profile_available(opts) do
    coverage_server = Keyword.get(opts, :profile_coverage, ProfileCoverage)

    try do
      ProfileCoverage.mark_available(Ceph.id(), coverage_server)
    catch
      :exit, _reason -> :ok
    end
  end

  defp degrade_profile(opts, failures, version) do
    coverage_server = Keyword.get(opts, :profile_coverage, ProfileCoverage)
    audit_server = Keyword.get(opts, :audit_server, Audit)
    details = %{failures: Enum.map(failures, &failure_metadata/1)}

    try do
      ProfileCoverage.mark_degraded(Ceph.id(), details, coverage_server)
    catch
      :exit, _reason -> :ok
    end

    attributes = %{
      component: "cluster_profile",
      profile_id: Ceph.id(),
      profile_version: version || Ceph.version(),
      coverage: "degraded",
      failures: details.failures
    }

    try do
      Audit.emit(:ceph_profile_validation_failed, attributes, server: audit_server)
    catch
      :exit, _reason -> :ok
    end
  end

  defp failure_metadata(failure) do
    Map.take(failure, [:code, :field, :path, :mode, :uid, :severity, :action_required])
  end

  defp invalid_profile_action({:invalid_ceph_profile, reason}) do
    "Correct cluster_profiles.ceph configuration: #{reason}"
  end

  defp invalid_profile_action(_reason), do: "Correct cluster_profiles.ceph configuration"

  defp start_bandit(config, opts) do
    case Keyword.get(opts, :bandit_start_fn) do
      fun when is_function(fun, 1) ->
        fun.(config)

      nil ->
        profile_coverage = Keyword.get(opts, :profile_coverage, ProfileCoverage)

        Bandit.start_link(
          plug:
            {Exocomp.Coordinator.CoordinatorRouter,
             coordinator_id: config.coordinator_id, profile_coverage: profile_coverage},
          scheme: :https,
          port: config.listen.port,
          ip: parse_ip(config.listen.host),
          startup_log: false,
          thousand_island_options: [transport_options: build_tls_opts(config)]
        )
    end
  end

  defp build_tls_opts(config) do
    [
      certfile: config.tls.coord_cert,
      keyfile: config.tls.coord_key,
      cacertfile: config.tls.ca_cert,
      verify: :verify_peer,
      # Allow connections without a client certificate so that enrolling nodes
      # (which do not yet have a coordinator-issued cert) can reach /v1/enroll.
      # mTLS is still enforced for all A2A routes via the authenticate_mtls plug
      # in A2ARouter, and the renewal route (/v1/renew) requires a client cert
      # at the application layer.
      fail_if_no_peer_cert: false,
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
