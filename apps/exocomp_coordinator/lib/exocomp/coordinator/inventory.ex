defmodule Exocomp.Coordinator.Inventory do
  @moduledoc """
  Owns the active, versioned node inventory.

  Replacement is validated in full, installed into the registry, and audited
  before the active value changes. Any failure therefore leaves the prior
  inventory and registry active.
  """

  use GenServer

  alias Exocomp.Coordinator.{Audit, Error, Registry}
  alias Exocomp.Coordinator.Inventory.Node

  @version 1
  @type inventory :: %{version: pos_integer(), nodes: [Node.t()]}

  defstruct inventory: %{version: @version, nodes: []}, source: nil, error: nil

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @spec current(GenServer.server()) :: inventory()
  def current(server \\ __MODULE__), do: GenServer.call(server, :current)

  @spec status(GenServer.server()) :: map()
  def status(server \\ __MODULE__), do: GenServer.call(server, :status)

  @spec replace_json(binary(), GenServer.server()) :: :ok | {:error, Error.t()}
  def replace_json(json, server \\ __MODULE__) when is_binary(json) do
    case parse(json) do
      {:ok, inventory} ->
        GenServer.call(server, {:replace, inventory, :json})

      {:error, error} ->
        record_rejection(error, :json, server)
        {:error, error}
    end
  end

  @spec replace_file(Path.t(), GenServer.server()) :: :ok | {:error, Error.t()}
  def replace_file(path, server \\ __MODULE__) do
    case File.read(path) do
      {:ok, json} ->
        case parse(json) do
          {:ok, inventory} ->
            GenServer.call(server, {:replace, inventory, path})

          {:error, error} ->
            record_rejection(error, path, server)
            {:error, error}
        end

      {:error, reason} ->
        error =
          Error.new(:inventory_read_failed, "could not read inventory", %{reason: reason})

        record_rejection(error, path, server)
        {:error, error}
    end
  end

  @spec parse(binary()) :: {:ok, inventory()} | {:error, Error.t()}
  def parse(json) when is_binary(json) do
    try do
      json
      |> :json.decode()
      |> validate()
    rescue
      error ->
        {:error,
         Error.new(:malformed_inventory, "inventory is not valid JSON", %{
           reason: Exception.message(error)
         })}
    end
  end

  @impl true
  def init(opts) do
    state = %__MODULE__{}

    case Keyword.get(opts, :inventory_path) do
      path when is_binary(path) ->
        send(self(), {:load_initial, path})
        {:ok, %{state | source: path}}

      _other ->
        {:ok, state}
    end
  end

  @impl true
  def handle_call(:current, _from, state), do: {:reply, state.inventory, state}

  def handle_call(:status, _from, state) do
    status = %{
      source: state.source,
      version: state.inventory.version,
      node_count: length(state.inventory.nodes),
      error: state.error
    }

    {:reply, status, state}
  end

  def handle_call({:replace, inventory, source}, _from, state) do
    case apply_replacement(inventory, source, state) do
      {:ok, updated} -> {:reply, :ok, updated}
      {:error, error, unchanged} -> {:reply, {:error, error}, %{unchanged | error: error}}
    end
  end

  @impl true
  def handle_cast({:rejected, error}, state), do: {:noreply, %{state | error: error}}

  @impl true
  def handle_info({:load_initial, path}, state) do
    result =
      with {:ok, json} <- File.read(path),
           {:ok, inventory} <- parse(json) do
        apply_replacement(inventory, path, state)
      else
        {:error, %Error{} = error} ->
          {:error, error, state}

        {:error, reason} ->
          error =
            Error.new(:inventory_read_failed, "could not read inventory", %{reason: reason})

          {:error, error, state}
      end

    case result do
      {:ok, updated} -> {:noreply, updated}
      {:error, error, unchanged} -> {:noreply, %{unchanged | error: error}}
    end
  end

  defp apply_replacement(inventory, source, state) do
    correlation_id = Audit.correlation_id()

    with :ok <-
           safe_call(fn ->
             Audit.emit(
               :inventory_replaced,
               %{source: source, node_count: length(inventory.nodes), version: inventory.version},
               correlation_id: correlation_id
             )
           end),
         :ok <- safe_call(fn -> Registry.rebuild(inventory.nodes) end) do
      {:ok, %{state | inventory: inventory, source: source, error: nil}}
    else
      {:error, %Error{} = error} ->
        {:error, error, state}

      {:error, reason} ->
        error =
          Error.new(:inventory_replacement_failed, "inventory replacement was rejected", %{
            reason: inspect(reason),
            correlation_id: correlation_id
          })

        {:error, error, state}
    end
  end

  defp record_rejection(error, source, server) do
    GenServer.cast(server, {:rejected, error})

    Audit.emit(
      :inventory_replacement_rejected,
      %{source: source, error: error},
      correlation_id: Audit.correlation_id()
    )
  catch
    :exit, _reason -> :ok
  end

  defp safe_call(function) do
    function.()
  catch
    :exit, reason -> {:error, {:process_unavailable, reason}}
  end

  defp validate(%{"version" => @version, "nodes" => nodes}) when is_list(nodes) do
    with {:ok, validated} <- validate_nodes(nodes),
         :ok <- unique(validated, & &1.id, :duplicate_node_id),
         :ok <-
           unique(validated, & &1.certificate_identity, :duplicate_certificate_identity) do
      {:ok, %{version: @version, nodes: validated}}
    end
  end

  defp validate(%{"version" => @version}) do
    {:error, Error.new(:invalid_inventory_schema, "inventory nodes must be a list", %{})}
  end

  defp validate(%{"version" => version}) do
    {:error,
     Error.new(:unsupported_inventory_version, "unsupported inventory version", %{
       expected: @version,
       actual: version
     })}
  end

  defp validate(_value) do
    {:error,
     Error.new(:invalid_inventory_schema, "inventory must contain version and nodes", %{})}
  end

  defp validate_nodes(nodes) do
    nodes
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {node, index}, {:ok, valid} ->
      case validate_node(node, index) do
        {:ok, entry} -> {:cont, {:ok, [entry | valid]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, valid} -> {:ok, Enum.reverse(valid)}
      error -> error
    end
  end

  defp validate_node(node, index) when is_map(node) do
    with {:ok, id} <- nonempty_string(node["id"], "id", index),
         {:ok, hostname} <- nonempty_string(node["hostname"], "hostname", index),
         {:ok, port} <- port(node["port"], index),
         {:ok, identity} <-
           nonempty_string(node["certificate_identity"], "certificate_identity", index),
         {:ok, capabilities} <- string_list(node["capabilities"], "capabilities", index),
         {:ok, labels} <- labels(Map.get(node, "labels", %{}), index) do
      {:ok,
       %Node{
         id: id,
         hostname: hostname,
         port: port,
         certificate_identity: identity,
         capabilities: capabilities,
         labels: labels
       }}
    end
  end

  defp validate_node(_node, index), do: field_error(index, "node", "must be an object")

  defp nonempty_string(value, _field, _index)
       when is_binary(value) and byte_size(value) > 0,
       do: {:ok, value}

  defp nonempty_string(_value, field, index), do: field_error(index, field, "must be non-empty")

  defp port(value, _index) when is_integer(value) and value in 1..65_535, do: {:ok, value}
  defp port(_value, index), do: field_error(index, "port", "must be between 1 and 65535")

  defp string_list(value, _field, _index) when is_list(value) do
    if Enum.all?(value, &(is_binary(&1) and byte_size(&1) > 0)) and
         length(value) == length(Enum.uniq(value)) do
      {:ok, value}
    else
      {:error, Error.new(:invalid_inventory_node, "capabilities must be unique strings")}
    end
  end

  defp string_list(_value, field, index), do: field_error(index, field, "must be a list")

  defp labels(value, _index) when is_map(value) do
    if Enum.all?(value, fn {key, val} -> is_binary(key) and is_binary(val) end) do
      {:ok, value}
    else
      {:error, Error.new(:invalid_inventory_node, "labels must contain string values")}
    end
  end

  defp labels(_value, index), do: field_error(index, "labels", "must be an object")

  defp unique(nodes, key_fun, code) do
    values = Enum.map(nodes, key_fun)

    case values -- Enum.uniq(values) do
      [] ->
        :ok

      [duplicate | _] ->
        {:error, Error.new(code, "duplicate inventory identity", %{value: duplicate})}
    end
  end

  defp field_error(index, field, requirement) do
    {:error,
     Error.new(:invalid_inventory_node, "inventory node is invalid", %{
       index: index,
       field: field,
       requirement: requirement
     })}
  end
end
