# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
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

  @version 2
  @supported_versions [1, 2]
  @type inventory :: %{
          version: pos_integer(),
          nodes: [Node.t()],
          cluster_profile: String.t() | nil
        }

  defstruct inventory: %{version: @version, nodes: [], cluster_profile: nil},
            source: nil,
            error: nil,
            reconcile_server: Exocomp.Coordinator.ServiceScheduler

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
    state = %__MODULE__{
      reconcile_server: Keyword.get(opts, :reconcile_server, Exocomp.Coordinator.ServiceScheduler)
    }

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
      {:ok, updated} ->
        notify_reconciliation(updated.reconcile_server)
        {:reply, :ok, updated}

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
      {:ok, updated} ->
        notify_reconciliation(updated.reconcile_server)
        {:noreply, updated}

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

  defp notify_reconciliation(server) do
    Exocomp.Coordinator.ServiceScheduler.inventory_replaced(server)
  catch
    :exit, _reason -> :ok
  end

  defp safe_call(function) do
    function.()
  catch
    :exit, reason -> {:error, {:process_unavailable, reason}}
  end

  defp validate(%{"version" => version, "nodes" => nodes} = input) when is_list(nodes) and version in @supported_versions do
    cluster_profile = Map.get(input, "cluster_profile", nil)

    with {:ok, validated} <- validate_cluster_profile(cluster_profile),
         {:ok, nodes_list} <- validate_nodes(nodes, version),
         :ok <- unique(nodes_list, & &1.id, :duplicate_node_id),
         :ok <-
           unique(nodes_list, & &1.certificate_identity, :duplicate_certificate_identity) do
      {:ok, %{version: version, nodes: nodes_list, cluster_profile: validated}}
    end
  end

  defp validate(%{"version" => version, "nodes" => _nodes}) when version not in @supported_versions do
    {:error,
     Error.new(:unsupported_inventory_version, "unsupported inventory version", %{
       expected: @version,
       actual: version
     })}
  end

  defp validate(%{"version" => _version, "nodes" => _nodes}) do
    {:error, Error.new(:invalid_inventory_schema, "inventory nodes must be a list", %{})}
  end

  defp validate(%{"version" => version}) when version in @supported_versions do
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

  defp validate_cluster_profile(nil), do: {:ok, nil}

  defp validate_cluster_profile(profile) when is_binary(profile) and byte_size(profile) > 0,
    do: {:ok, profile}

  defp validate_cluster_profile(_value) do
    {:error,
     Error.new(:invalid_inventory_schema, "cluster_profile must be a non-empty string or null",
       %{})}
  end

  defp validate_nodes(nodes, version) do
    nodes
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {node, index}, {:ok, valid} ->
      case validate_node(node, index, version) do
        {:ok, entry} -> {:cont, {:ok, [entry | valid]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, valid} -> {:ok, Enum.reverse(valid)}
      error -> error
    end
  end

  defp validate_node(node, index, version) when is_map(node) do
    with {:ok, id} <- nonempty_string(node["id"], "id", index),
         {:ok, hostname} <- nonempty_string(node["hostname"], "hostname", index),
         {:ok, port} <- port(node["port"], index),
         {:ok, identity} <-
           nonempty_string(node["certificate_identity"], "certificate_identity", index),
         {:ok, capabilities} <- string_list(node["capabilities"], "capabilities", index),
         {:ok, labels} <- labels(Map.get(node, "labels", %{}), index),
         {:ok, monitoring} <- validate_monitoring(Map.get(node, "monitoring"), index, version) do
      {:ok,
       %Node{
         id: id,
         hostname: hostname,
         port: port,
         certificate_identity: identity,
         capabilities: capabilities,
         labels: labels,
         monitoring: monitoring
       }}
    end
  end

  defp validate_node(_node, index, _version), do: field_error(index, "node", "must be an object")

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

  defp validate_monitoring(nil, _index, _version), do: {:ok, nil}

  defp validate_monitoring(_value, _index, 1) do
    {:error,
     Error.new(:invalid_inventory_node, "monitoring is not supported in version 1", %{})}
  end

  defp validate_monitoring(monitoring, index, 2) when is_map(monitoring) do
    with {:ok, automatic} <-
           validate_automatic(Map.get(monitoring, "automatic", false), index),
         {:ok, services} <-
           validate_services(Map.get(monitoring, "services", []), index) do
      {:ok, %{automatic: automatic, services: services}}
    end
  end

  defp validate_monitoring(_value, index, _version) do
    field_error(index, "monitoring", "must be an object")
  end

  defp validate_automatic(value, _index) when is_boolean(value), do: {:ok, value}

  defp validate_automatic(_value, index),
    do: field_error(index, "monitoring.automatic", "must be a boolean")

  defp validate_services(services, _index) when is_list(services) do
    services
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {service, svc_index}, {:ok, valid} ->
      case validate_service(service, svc_index) do
        {:ok, entry} -> {:cont, {:ok, [entry | valid]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, valid} ->
        # Check for duplicate service names
        names = Enum.map(valid, & &1.name)

        case names -- Enum.uniq(names) do
          [] -> {:ok, Enum.reverse(valid)}
          [dup | _] -> {:error, Error.new(:invalid_inventory_node, "duplicate service name", %{value: dup})}
        end

      error ->
        error
    end
  end

  defp validate_services(_value, index),
    do: field_error(index, "monitoring.services", "must be a list")

  defp validate_service(service, svc_index) when is_map(service) do
    with {:ok, name} <-
           validate_service_name(Map.get(service, "name"), svc_index),
         {:ok, url} <-
           validate_health_check_url(Map.get(service, "health_check_url"), svc_index) do
      {:ok, %{name: name, health_check_url: url}}
    end
  end

  defp validate_service(_value, svc_index),
    do: service_error(svc_index, "service", "must be an object")

  defp validate_service_name(value, _svc_index) when is_binary(value) do
    if String.ends_with?(value, ".service") and byte_size(value) > 8 do
      {:ok, value}
    else
      {:error,
       Error.new(:invalid_inventory_node, "service name must end with .service", %{
         value: value
       })}
    end
  end

  defp validate_service_name(_value, svc_index),
    do: service_error(svc_index, "name", "must be a non-empty string ending with .service")

  defp validate_health_check_url(value, _svc_index) when is_binary(value) do
    case URI.parse(value) do
      %URI{scheme: "http", host: host} when host in ["127.0.0.1", "localhost"] ->
        {:ok, value}

      %URI{scheme: "http", host: "::1"} ->
        {:ok, value}

      _other ->
        {:error,
         Error.new(:invalid_inventory_node,
           "health_check_url must be http://127.0.0.1:port/path, http://localhost:port/path, or http://[::1]:port/path",
           %{value: value})}
    end
  end

  defp validate_health_check_url(_value, svc_index),
    do: service_error(svc_index, "health_check_url", "must be a valid http loopback URL")

  defp service_error(index, field, requirement) do
    {:error,
     Error.new(:invalid_inventory_node, "service is invalid", %{
       index: index,
       field: field,
       requirement: requirement
     })}
  end

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
