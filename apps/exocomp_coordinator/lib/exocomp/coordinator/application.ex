defmodule Exocomp.Coordinator.Application do
  @moduledoc """
  Starts coordinator services only after protected PKI state is validated.

  Production startup requires explicit `:pki_online_state` and
  `:pki_offline_root_backup` application configuration plus the
  `EXOCOMP_ROOT_KEY_PASSPHRASE` environment variable. The passphrase is read
  only for validation and is never placed in child specifications or runtime
  state.
  """

  use Application

  alias Exocomp.Coordinator.PKI.Bootstrap

  @impl true
  def start(_type, _args) do
    case validate_pki() do
      {:ok, metadata} -> start_supervisor(metadata)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Starts a complete coordinator supervision tree with configurable process names.

  Intended for integration testing. Production startup uses the OTP `start/2`
  callback, which reads configuration from application environment.

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

  defp validate_pki do
    if Application.get_env(:exocomp_coordinator, :require_pki, true) do
      with {:ok, passphrase} <- System.fetch_env("EXOCOMP_ROOT_KEY_PASSPHRASE") do
        Bootstrap.initialize(
          online_state: Application.get_env(:exocomp_coordinator, :pki_online_state),
          offline_backup: Application.get_env(:exocomp_coordinator, :pki_offline_root_backup),
          root_key_protection: {:passphrase, passphrase}
        )
      else
        :error -> {:error, {:invalid_pki_configuration, :missing_root_key_protection}}
      end
    else
      {:ok, nil}
    end
  end

  defp start_supervisor(metadata) do
    enrollment_token_opts =
      []
      |> maybe_put(
        :store_path,
        enrollment_token_store_path(metadata)
      )
      |> maybe_put(
        :max_lifetime,
        Application.get_env(:exocomp_coordinator, :enrollment_token_lifetime)
      )

    children =
      [
        {Exocomp.Coordinator.Audit, Application.get_env(:exocomp_coordinator, :audit, [])}
      ] ++
        pki_children(metadata) ++
        [
          Exocomp.Coordinator.Registry,
          {Exocomp.Coordinator.Inventory,
           inventory_path: Application.get_env(:exocomp_coordinator, :inventory_path)},
          {Exocomp.Coordinator.EnrollmentToken, enrollment_token_opts}
        ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Exocomp.Coordinator.Supervisor
    )
  end

  defp start_named_supervisor(metadata, sup_name, opts) do
    prefix = Keyword.get(opts, :name_prefix, sup_name)

    audit_name = :"#{prefix}_audit"
    registry_name = :"#{prefix}_registry"
    inventory_name = :"#{prefix}_inventory"
    pki_state_name = :"#{prefix}_pki_state"
    enrollment_name = :"#{prefix}_enrollment_token"

    store_path =
      Keyword.get(
        opts,
        :store_path,
        Path.join(Path.dirname(metadata.online_state), "enrollment-tokens")
      )

    enrollment_token_opts =
      [name: enrollment_name, store_path: store_path, audit_server: audit_name]
      |> Keyword.merge(Keyword.get(opts, :enrollment_token_opts, []))

    audit_opts =
      [name: audit_name]
      |> Keyword.merge(Keyword.get(opts, :audit_opts, []))

    children =
      [
        {Exocomp.Coordinator.Audit, audit_opts},
        {Exocomp.Coordinator.PKI.State, [metadata: metadata, name: pki_state_name]},
        {Exocomp.Coordinator.Registry, [name: registry_name]},
        {Exocomp.Coordinator.Inventory,
         [name: inventory_name, inventory_path: Keyword.get(opts, :inventory_path)]},
        {Exocomp.Coordinator.EnrollmentToken, enrollment_token_opts}
      ]

    Supervisor.start_link(children, strategy: :one_for_one, name: sup_name)
  end

  defp pki_children(nil), do: []
  defp pki_children(metadata), do: [{Exocomp.Coordinator.PKI.State, metadata: metadata}]

  defp enrollment_token_store_path(metadata) do
    case Application.get_env(:exocomp_coordinator, :enrollment_token_store_path) do
      nil when not is_nil(metadata) ->
        Path.join(Path.dirname(metadata.online_state), "enrollment-tokens")

      configured ->
        configured
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
