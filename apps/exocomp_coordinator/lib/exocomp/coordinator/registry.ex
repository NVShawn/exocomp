defmodule Exocomp.Coordinator.Registry do
  @moduledoc """
  ETS-backed live node registry.

  The ETS table is private to this process and replaced only after a complete
  new table has been built. On restart the registry reconstructs configured
  nodes from the active inventory.
  """

  use GenServer

  alias Exocomp.Coordinator.Inventory
  alias Exocomp.Coordinator.Inventory.Node

  @states [:unknown, :healthy, :degraded, :stale, :unreachable]

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @spec rebuild([Node.t()], GenServer.server()) :: :ok
  def rebuild(nodes, server \\ __MODULE__), do: GenServer.call(server, {:rebuild, nodes})

  @spec all(GenServer.server()) :: [map()]
  def all(server \\ __MODULE__), do: GenServer.call(server, :all)

  @spec get(String.t(), GenServer.server()) :: {:ok, map()} | :error
  def get(node_id, server \\ __MODULE__), do: GenServer.call(server, {:get, node_id})

  @spec update(String.t(), map(), GenServer.server()) ::
          :ok | {:error, :not_found | :invalid_state}
  def update(node_id, changes, server \\ __MODULE__) when is_map(changes) do
    GenServer.call(server, {:update, node_id, changes})
  end

  @impl true
  def init(_opts) do
    table = new_table()
    send(self(), :reconstruct)
    {:ok, table}
  end

  @impl true
  def handle_call({:rebuild, nodes}, _from, old_table) do
    new_table = new_table()
    Enum.each(nodes, &:ets.insert(new_table, {&1.id, initial_entry(&1)}))
    :ets.delete(old_table)
    {:reply, :ok, new_table}
  end

  def handle_call(:all, _from, table) do
    entries =
      table
      |> :ets.tab2list()
      |> Enum.map(&elem(&1, 1))
      |> Enum.sort_by(& &1.id)

    {:reply, entries, table}
  end

  def handle_call({:get, node_id}, _from, table) do
    reply =
      case :ets.lookup(table, node_id) do
        [{^node_id, entry}] -> {:ok, entry}
        [] -> :error
      end

    {:reply, reply, table}
  end

  def handle_call({:update, node_id, changes}, _from, table) do
    with [{^node_id, entry}] <- :ets.lookup(table, node_id),
         :ok <- valid_state(changes) do
      :ets.insert(table, {node_id, Map.merge(entry, changes)})
      {:reply, :ok, table}
    else
      [] -> {:reply, {:error, :not_found}, table}
      {:error, reason} -> {:reply, {:error, reason}, table}
    end
  end

  @impl true
  def handle_info(:reconstruct, table) do
    if Process.whereis(Inventory) do
      nodes = Inventory.current().nodes
      Enum.each(nodes, &:ets.insert(table, {&1.id, initial_entry(&1)}))
    end

    {:noreply, table}
  end

  defp new_table, do: :ets.new(__MODULE__, [:set, :private, read_concurrency: true])

  defp initial_entry(node) do
    %{
      id: node.id,
      hostname: node.hostname,
      port: node.port,
      certificate_identity: node.certificate_identity,
      capabilities: node.capabilities,
      labels: node.labels,
      addresses: [],
      last_successful_contact: nil,
      last_attempted_contact: nil,
      reachability: :unknown,
      agent_card_version: nil,
      supported_skills: [],
      diagnostic_summary: nil,
      consecutive_failures: 0,
      next_eligible_poll_at: nil
    }
  end

  defp valid_state(%{reachability: state}) when state not in @states, do: {:error, :invalid_state}
  defp valid_state(_changes), do: :ok
end
