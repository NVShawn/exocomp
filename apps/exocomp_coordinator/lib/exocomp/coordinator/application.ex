# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Application do
  @moduledoc """
  Starts coordinator services.

  Normal startup launches the full supervision tree: Audit, Registry,
  Inventory, Resolver, HealthPoller, GoalStore, Orchestrator, TaskRegistry,
  and (when `require_pki` is true) PKI.State, PKI.CertificateRegistry,
  EnrollmentToken, and Listener.

  PKI validation is gated by the `:require_pki` application config (default
  true; set to false in test environment). When enabled, `Bootstrap.load_online_state/1`
  validates the configured online PKI directory without requiring the offline
  root backup. If PKI loading fails, the application fails to start.

  Integration tests that exercise PKI and enrollment call
  `start_supervised_tree/1` directly to start a named, isolated sub-tree with
  configurable process names and real PKI state.
  """

  use Application

  require Logger

  alias Exocomp.Coordinator.{Audit, ClusterInvitationStore, EnrollmentToken, Listener}
  alias Exocomp.Coordinator.PKI.{Bootstrap, CertificateRegistry, State}

  @impl true
  def start(_type, _args) do
    require_pki? = Application.get_env(:exocomp_coordinator, :require_pki, true)

    case build_children(require_pki?) do
      {:ok, children} ->
        Supervisor.start_link(children,
          strategy: :one_for_one,
          name: Exocomp.Coordinator.Supervisor
        )

      {:error, _reason} = error ->
        error
    end
  end

  # ── Child list construction ───────────────────────────────────────────────────

  defp build_children(require_pki?) do
    if require_pki? do
      case pki_and_listener_children() do
        {:ok, extra} -> {:ok, base_children() ++ extra ++ mission_control_children()}
        {:error, _} = error -> error
      end
    else
      {:ok, base_children() ++ mission_control_children()}
    end
  end

  defp base_children do
    [
      {Audit, Application.get_env(:exocomp_coordinator, :audit, [])},
      {Exocomp.Coordinator.EventOutbox,
       [
         path: Application.get_env(:exocomp_coordinator, :event_outbox_path),
         cluster_id: Application.get_env(:exocomp_coordinator, :cluster_id)
       ]
       |> Keyword.merge(Application.get_env(:exocomp_coordinator, :event_outbox, []))},
      {Exocomp.Coordinator.Registry, Application.get_env(:exocomp_coordinator, :registry, [])},
      {Exocomp.Coordinator.Inventory,
       inventory_path: Application.get_env(:exocomp_coordinator, :inventory_path),
       reconcile_server: Exocomp.Coordinator.ServiceScheduler},
      {Exocomp.Coordinator.Resolver, Application.get_env(:exocomp_coordinator, :resolver, [])},
      {Task.Supervisor, name: Exocomp.Coordinator.PollTaskSupervisor},
      {Task.Supervisor, name: Exocomp.Coordinator.ServiceTaskSupervisor},
      {Exocomp.Coordinator.ServiceScheduler,
       Application.get_env(:exocomp_coordinator, :service_scheduler, [])},
      {Exocomp.Coordinator.HealthPoller,
       Application.get_env(:exocomp_coordinator, :health_poller, []) ++
         [service_scheduler: Exocomp.Coordinator.ServiceScheduler]},
      {Exocomp.Coordinator.GoalStore, Application.get_env(:exocomp_coordinator, :goal_store, [])},
      {Task.Supervisor, name: Exocomp.Coordinator.DiagTaskSupervisor},
      {Exocomp.Coordinator.Orchestrator,
       Application.get_env(:exocomp_coordinator, :orchestrator, [])},
      Exocomp.Coordinator.TaskRegistry,
      {Exocomp.Coordinator.RemediationLifecycle,
       Application.get_env(:exocomp_coordinator, :remediation_lifecycle, [])},
      {ClusterInvitationStore,
       store_path: Application.get_env(:exocomp_coordinator, :cluster_invitation_store_path),
       audit_server: Audit}
    ]
  end

  @doc """
  Returns the Mission Control supervision subtree children based on the current
  application environment configuration.

  Used for testing to verify that Mission Control children are included or
  excluded based on the :mission_control_config application setting.

  Returns a list of child specs (which may be empty if Mission Control is not
  configured or disabled).
  """
  def mission_control_children_for_test do
    mission_control_children()
  end

  # Build the existing Mission Control subtree from the validated config. The
  # subtree owns the outbound connection; keeping it here preserves the
  # coordinator's single, optional outbound integration point and never adds an
  # inbound listener.
  defp mission_control_children do
    case Application.get_env(:exocomp_coordinator, :mission_control_config) do
      nil ->
        []

      mc_config when is_map(mc_config) ->
        if Map.get(mc_config, :enabled) == true do
          [{Exocomp.Coordinator.MissionControl.Supervisor, mc_config}]
        else
          []
        end

      _ ->
        []
    end
  end

  # Loads the online PKI state and returns child specs for PKI.State,
  # PKI.CertificateRegistry, EnrollmentToken, and Listener. Returns
  # {:error, reason} if the online PKI state is absent or invalid, causing
  # the application to fail to start.
  defp pki_and_listener_children do
    online_state = Application.get_env(:exocomp_coordinator, :pki_online_state)

    if is_nil(online_state) do
      Logger.error(
        "[CoordinatorApp] require_pki is true but pki_online_state is not configured; " <>
          "set the EXOCOMP_PKI_ONLINE_STATE environment variable"
      )

      {:error, :pki_not_configured}
    else
      case Bootstrap.load_online_state(online_state: online_state) do
        {:ok, metadata} ->
          enrollment_store_path =
            Application.get_env(:exocomp_coordinator, :enrollment_token_store_path) ||
              Path.join(Path.dirname(online_state), "enrollment-tokens")

          cert_registry_path =
            Application.get_env(:exocomp_coordinator, :cert_registry_store_path) ||
              Path.join(Path.dirname(online_state), "cert-registry")

          children = [
            {State, [metadata: metadata]},
            {CertificateRegistry, [store_path: cert_registry_path]},
            {EnrollmentToken, [store_path: enrollment_store_path, audit_server: Audit]},
            {Listener, Application.get_env(:exocomp_coordinator, :listener, [])}
          ]

          {:ok, children}

        {:error, error} ->
          Logger.error(
            "[CoordinatorApp] PKI state load failed (#{inspect(error.code)}); " <>
              "ensure the PKI ceremony has been completed and the online state is intact"
          )

          {:error, {:pki_load_failed, error.code}}
      end
    end
  end

  @doc """
  Starts a complete coordinator supervision tree with configurable process names.

  Intended for integration testing of PKI and enrollment. Production startup
  uses the OTP `start/2` callback, which reads configuration from the
  application environment.

  Required options:
    - `:online_state` — absolute path to the online PKI directory
    - `:offline_backup` — absolute path to the offline root backup directory
    - `:root_key_protection` — `{:passphrase, value}` to unlock the root key

  Optional options:
    - `:supervisor_name` — registered name for the supervisor process
    - `:name_prefix` — atom prefix used to derive unique child process names;
      defaults to `:supervisor_name` when not provided
    - `:store_path` — enrollment token store directory (default: derived from
      online_state as a sibling `enrollment-tokens` directory)
    - `:cert_registry_store_path` — certificate registry store directory
      (default: derived from online_state as a sibling `cert-registry` directory)
    - `:enrollment_token_opts` — extra keyword options merged into the
      EnrollmentToken child spec (e.g., `:inventory_fn`, `:now_fn`)
    - `:audit_opts` — extra keyword options merged into the Audit child spec
      (e.g., `:sink`)
    - `:inventory_path` — path to an inventory JSON file to load at startup
  """
  @spec start_supervised_tree(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_supervised_tree(opts) when is_list(opts) do
    pki_opts = [
      online_state: Keyword.fetch!(opts, :online_state),
      offline_backup: Keyword.fetch!(opts, :offline_backup),
      root_key_protection: Keyword.fetch!(opts, :root_key_protection)
    ]

    case Bootstrap.initialize(pki_opts) do
      {:ok, metadata} ->
        sup_name = Keyword.get(opts, :supervisor_name, __MODULE__)
        start_named_supervisor(metadata, sup_name, opts)

      {:error, error} ->
        {:error, error}
    end
  end

  defp start_named_supervisor(metadata, sup_name, opts) do
    prefix = Keyword.get(opts, :name_prefix, sup_name)

    audit_name = :"#{prefix}_audit"
    registry_name = :"#{prefix}_registry"
    inventory_name = :"#{prefix}_inventory"
    pki_state_name = :"#{prefix}_pki_state"
    enrollment_name = :"#{prefix}_enrollment_token"
    invitation_name = :"#{prefix}_cluster_invitation_store"
    cert_registry_name = :"#{prefix}_cert_registry"

    store_path =
      Keyword.get(
        opts,
        :store_path,
        Path.join(Path.dirname(metadata.online_state), "enrollment-tokens")
      )

    cert_registry_path =
      Keyword.get(
        opts,
        :cert_registry_store_path,
        Path.join(Path.dirname(metadata.online_state), "cert-registry")
      )

    enrollment_token_opts =
      [name: enrollment_name, store_path: store_path, audit_server: audit_name]
      |> Keyword.merge(Keyword.get(opts, :enrollment_token_opts, []))

    invitation_store_path =
      Keyword.get(
        opts,
        :cluster_invitation_store_path,
        Path.join(Path.dirname(metadata.online_state), "cluster-invitations")
      )

    invitation_opts =
      [name: invitation_name, store_path: invitation_store_path, audit_server: audit_name]
      |> Keyword.merge(Keyword.get(opts, :cluster_invitation_opts, []))

    audit_opts =
      [name: audit_name]
      |> Keyword.merge(Keyword.get(opts, :audit_opts, []))

    children = [
      {Exocomp.Coordinator.Audit, audit_opts},
      {Exocomp.Coordinator.PKI.State, [metadata: metadata, name: pki_state_name]},
      {Exocomp.Coordinator.PKI.CertificateRegistry,
       [name: cert_registry_name, store_path: cert_registry_path]},
      {Exocomp.Coordinator.Registry, [name: registry_name]},
      {Exocomp.Coordinator.Inventory,
       [name: inventory_name, inventory_path: Keyword.get(opts, :inventory_path)]},
      {Exocomp.Coordinator.EnrollmentToken, enrollment_token_opts},
      {ClusterInvitationStore, invitation_opts}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: sup_name)
  end
end
