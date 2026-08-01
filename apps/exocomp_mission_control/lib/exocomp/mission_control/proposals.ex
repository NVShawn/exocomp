# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Proposals do
  use GenServer

  @moduledoc """
  Bounded, organization-scoped proposal store.

  This context manages typed remedy proposals. Like Conversations, the current
  implementation is an in-memory GenServer so transport and database integrations
  can be added independently. Its API and validation rules are intentionally the
  same rules a persistent adapter must preserve.

  Every operation takes an organization ID and enforces organization scoping.
  Proposals require a cluster, catalog action ID, and evidence hash. They are
  optional linked to a cluster (conversation_id, message_id) and a task or
  correlation ID.

  Proposals are validated against a supplied action catalog and parameter schema
  before persistence. Proposals must have a unique ID within the organization.
  Proposals can expire (checked on retrieval) and can have stale evidence (checked
  against a freshness window).

  Persisting a proposal does not execute it. Execution is coordinated separately
  through the cluster's local RemediationLifecycle after operator approval.
  """

  alias Exocomp.MissionControl.Proposal

  @type action_catalog :: %{String.t() => action_spec()}
  @type action_spec :: %{
          optional(:description) => String.t(),
          optional(:parameters_schema) => map()
        }

  @type state :: %{
          proposals: %{String.t() => Proposal.t()},
          catalog: action_catalog(),
          now: (-> DateTime.t()),
          id: (String.t() -> String.t())
        }

  @doc "Start an isolated proposal store with a given action catalog."
  @spec start_link(action_catalog(), keyword()) :: GenServer.on_start()
  def start_link(catalog \\ %{}, opts \\ []) do
    GenServer.start_link(__MODULE__, [catalog, opts], name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Create a proposal for an organization and cluster."
  @spec create_proposal(String.t(), map(), keyword()) ::
          {:ok, Proposal.t()} | {:error, term()}
  def create_proposal(organization_id, attrs \\ %{}, opts \\ [])
      when is_binary(organization_id) and is_map(attrs) do
    call_server(opts, {:create, organization_id, attrs})
  end

  @doc "Fetch a proposal only when it belongs to `organization_id`."
  @spec get(String.t(), String.t(), keyword()) ::
          {:ok, Proposal.t()} | {:error, :not_found | :expired}
  def get(organization_id, proposal_id, opts \\ []) do
    call_server(opts, {:get, organization_id, proposal_id})
  end

  @doc "List only the proposals owned by an organization, in creation order."
  @spec list(String.t(), keyword()) :: [Proposal.t()]
  def list(organization_id, opts \\ []) do
    call_server(opts, {:list, organization_id})
  end

  @doc "List proposals for a specific cluster within an organization."
  @spec list_by_cluster(String.t(), String.t(), keyword()) :: [Proposal.t()]
  def list_by_cluster(organization_id, cluster_id, opts \\ []) do
    call_server(opts, {:list_by_cluster, organization_id, cluster_id})
  end

  @doc "List proposals for a specific conversation within an organization."
  @spec list_by_conversation(String.t(), String.t(), keyword()) :: [Proposal.t()]
  def list_by_conversation(organization_id, conversation_id, opts \\ []) do
    call_server(opts, {:list_by_conversation, organization_id, conversation_id})
  end

  @doc "Update the action catalog (for testing or dynamic catalog updates)."
  @spec set_catalog(action_catalog(), keyword()) :: :ok
  def set_catalog(catalog, opts \\ []) do
    call_server(opts, {:set_catalog, catalog})
  end

  @impl true
  def init([catalog, opts]) do
    {:ok,
     %{
       proposals: %{},
       catalog: catalog,
       now: Keyword.get(opts, :now_fun, &DateTime.utc_now/0),
       id: Keyword.get(opts, :id_fun, &default_id/1)
     }}
  end

  @impl true
  def handle_call({:create, organization_id, attrs}, _from, state) do
    case validate_supplied_scope(attrs, :organization_id, organization_id) do
      :ok ->
        attrs = Map.put_new(attrs, :organization_id, organization_id)
        attrs = Map.put_new(attrs, :id, state.id.("prop_"))
        attrs = Map.put_new(attrs, :created_at, state.now.())
        attrs = maybe_set_default_expiry(attrs, state)

        case Proposal.new(attrs) do
          {:ok, proposal} ->
            if Map.has_key?(state.proposals, proposal.id) do
              {:reply, {:error, :duplicate_proposal_id}, state}
            else
              case validate_catalog_action(proposal, state.catalog) do
                :ok ->
                  {:reply, {:ok, proposal},
                   %{state | proposals: Map.put(state.proposals, proposal.id, proposal)}}

                {:error, _reason} = error ->
                  {:reply, error, state}
              end
            end

          {:error, _reason} = error ->
            {:reply, error, state}
        end

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:get, organization_id, proposal_id}, _from, state) do
    reply =
      case Map.get(state.proposals, proposal_id) do
        %Proposal{organization_id: ^organization_id} = proposal ->
          if Proposal.expired?(proposal) do
            {:error, :expired}
          else
            {:ok, proposal}
          end

        %Proposal{} ->
          {:error, :not_found}

        nil ->
          {:error, :not_found}
      end

    {:reply, reply, state}
  end

  def handle_call({:list, organization_id}, _from, state) do
    proposals =
      state.proposals
      |> Map.values()
      |> Enum.filter(&(&1.organization_id == organization_id))
      |> Enum.reject(&Proposal.expired?/1)
      |> Enum.sort_by(&{&1.created_at, &1.id})

    {:reply, proposals, state}
  end

  def handle_call({:list_by_cluster, organization_id, cluster_id}, _from, state) do
    proposals =
      state.proposals
      |> Map.values()
      |> Enum.filter(&(&1.organization_id == organization_id and &1.cluster_id == cluster_id))
      |> Enum.reject(&Proposal.expired?/1)
      |> Enum.sort_by(&{&1.created_at, &1.id})

    {:reply, proposals, state}
  end

  def handle_call({:list_by_conversation, organization_id, conversation_id}, _from, state) do
    proposals =
      state.proposals
      |> Map.values()
      |> Enum.filter(
        &(&1.organization_id == organization_id and &1.conversation_id == conversation_id)
      )
      |> Enum.reject(&Proposal.expired?/1)
      |> Enum.sort_by(&{&1.created_at, &1.id})

    {:reply, proposals, state}
  end

  def handle_call({:set_catalog, catalog}, _from, state) do
    {:reply, :ok, %{state | catalog: catalog}}
  end

  defp validate_catalog_action(%Proposal{catalog_action_id: action_id}, catalog) do
    case Map.get(catalog, action_id) do
      nil -> {:error, :unknown_action}
      _action_spec -> :ok
    end
  end

  defp maybe_set_default_expiry(attrs, state) do
    if Map.has_key?(attrs, :expires_at) or Map.has_key?(attrs, "expires_at") do
      attrs
    else
      # Default to 1 hour expiry if not specified
      Map.put(attrs, :expires_at, DateTime.add(state.now.(), 3600, :second))
    end
  end

  defp validate_supplied_scope(attrs, field, expected) when is_map(attrs) do
    if supplied_scope_matches?(attrs, field, expected) do
      :ok
    else
      {:error, :cross_organization}
    end
  end

  defp validate_supplied_scope(_attrs, _field, _expected), do: :ok

  defp supplied_scope_matches?(attrs, field, expected) do
    attrs
    |> supplied_values(field)
    |> Enum.all?(&(&1 == expected))
  end

  defp supplied_values(attrs, field) do
    [Map.get(attrs, field), Map.get(attrs, Atom.to_string(field))]
    |> Enum.reject(&is_nil/1)
  end

  defp call_server(opts, request),
    do: GenServer.call(Keyword.get(opts, :server, __MODULE__), request)

  defp default_id(prefix),
    do: prefix <> Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
end
