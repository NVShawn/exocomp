# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.RemediationAdapter.CephCooldown do
  @moduledoc """
  Durable cooldown tracking for Ceph daemon restart recovery.

  Cooldown state is stored as correlated Coordinator.Audit events by default.
  Tests and alternate deployments may inject reader/writer functions, but a
  missing or unreadable durable audit trail is treated as unavailable by
  cooldown_status/3 so policy can fail closed.
  """

  alias Exocomp.Coordinator.Audit

  @type cooldown_event :: %{
          node_id: String.t(),
          daemon_id: String.t(),
          target_unit: String.t(),
          reason: atom(),
          timestamp: String.t(),
          expires_at: String.t()
        }

  @default_cooldown_ms 30 * 60 * 1000

  @doc "Return whether a daemon is in cooldown; audit-read errors are false here for compatibility."
  @spec in_cooldown?(String.t(), String.t(), keyword()) :: boolean()
  def in_cooldown?(daemon_id, node_id, opts \\ []) do
    case cooldown_status(daemon_id, node_id, opts) do
      {:ok, value} -> value
      {:error, _reason} -> false
    end
  end

  @doc """
  Return cooldown state while preserving an audit availability error.

  Callers that are deciding whether to execute an action should use this
  function and deny when it returns an error. That prevents an audit outage
  from turning into an unbounded restart loop.
  """
  @spec cooldown_status(String.t(), String.t(), keyword()) ::
          {:ok, boolean()} | {:error, term()}
  def cooldown_status(daemon_id, node_id, opts \\ []) do
    cooldown_ms = Keyword.get(opts, :cooldown_ms, @default_cooldown_ms)
    audit_reader = audit_reader(opts)

    case safe_call(fn -> audit_reader.(daemon_id) end) do
      {:ok, {:ok, events}} when is_list(events) ->
        {:ok, check_active_cooldown(events, daemon_id, node_id, cooldown_ms)}

      {:ok, {:error, reason}} ->
        {:error, reason}

      {:ok, other} ->
        {:error, {:invalid_audit_reader_result, other}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Record a durable cooldown event after a verification failure."
  @spec record_cooldown(String.t(), String.t(), String.t(), atom(), keyword()) ::
          {:ok, cooldown_event()} | {:error, term()}
  def record_cooldown(daemon_id, node_id, target_unit, reason, opts \\ []) do
    cooldown_ms = Keyword.get(opts, :cooldown_ms, @default_cooldown_ms)
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    expires_at =
      DateTime.utc_now() |> DateTime.add(cooldown_ms, :millisecond) |> DateTime.to_iso8601()

    event =
      %{
        "type" => "cooldown_entered",
        "node_id" => node_id,
        "daemon_id" => daemon_id,
        "target_unit" => target_unit,
        "reason" => reason_to_string(reason),
        "timestamp" => timestamp,
        "expires_at" => expires_at
      }
      |> maybe_put_correlation_id(opts)

    case safe_call(fn -> audit_writer(opts).(daemon_id, event) end) do
      {:ok, :ok} -> {:ok, to_atom_keys(event)}
      {:ok, {:error, _} = error} -> error
      {:ok, other} -> {:error, {:invalid_audit_writer_result, other}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Record a durable event clearing cooldown after successful recovery."
  @spec clear_cooldown(String.t(), keyword()) :: :ok | {:error, term()}
  def clear_cooldown(daemon_id, opts \\ []) do
    event =
      %{
        "type" => "cooldown_cleared",
        "daemon_id" => daemon_id,
        "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601()
      }
      |> maybe_put_correlation_id(opts)

    case safe_call(fn -> audit_writer(opts).(daemon_id, event) end) do
      {:ok, :ok} -> :ok
      {:ok, {:error, _} = error} -> error
      {:ok, other} -> {:error, {:invalid_audit_writer_result, other}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp audit_reader(opts) do
    case Keyword.fetch(opts, :audit_reader) do
      {:ok, reader} -> reader
      :error -> fn daemon_id -> default_audit_reader(daemon_id, audit_server(opts)) end
    end
  end

  defp audit_writer(opts) do
    case Keyword.fetch(opts, :audit_writer) do
      {:ok, writer} ->
        writer

      :error ->
        fn daemon_id, event ->
          default_audit_writer(
            daemon_id,
            event,
            audit_server(opts),
            Keyword.get(opts, :correlation_id)
          )
        end
    end
  end

  defp audit_server(opts) do
    Keyword.get(
      opts,
      :audit_server,
      Application.get_env(:exocomp_coordinator, :ceph_audit_server, Audit)
    )
  end

  defp default_audit_reader(daemon_id, audit_server) do
    case Audit.events(audit_server) do
      {:ok, events} ->
        {:ok,
         Enum.flat_map(events, fn event ->
           event_type = Map.get(event, "event_type") || Map.get(event, :event_type)
           attributes = Map.get(event, "attributes") || Map.get(event, :attributes) || %{}
           event_daemon_id = Map.get(attributes, "daemon_id") || Map.get(attributes, :daemon_id)

           if event_daemon_id == daemon_id and
                event_type in ["cooldown_entered", "cooldown_cleared"] do
             [Map.put(attributes, "type", event_type)]
           else
             []
           end
         end)}

      {:error, _reason} = error ->
        error
    end
  end

  defp default_audit_writer(_daemon_id, event, audit_server, correlation_id) do
    event_type = Map.get(event, "type", "cooldown_entered")

    Audit.emit(event_type, event,
      server: audit_server,
      correlation_id: correlation_id || Map.get(event, "correlation_id")
    )
  rescue
    error -> {:error, {:audit_exception, Exception.message(error)}}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp check_active_cooldown(events, daemon_id, node_id, cooldown_ms) do
    now = DateTime.utc_now()

    events
    |> Enum.reverse()
    |> Enum.reduce_while(false, fn event, _acc ->
      event_daemon_id = value(event, :daemon_id, "daemon_id")
      event_node_id = value(event, :node_id, "node_id")
      event_type = value(event, :type, "type")

      cond do
        event_daemon_id != daemon_id ->
          {:cont, false}

        event_type in ["cooldown_cleared", :cooldown_cleared] ->
          {:halt, false}

        event_type in [nil, "cooldown_entered", :cooldown_entered] ->
          # Only match cooldown events that belong to this node (when node_id is recorded)
          if not is_nil(event_node_id) and event_node_id != node_id do
            {:cont, false}
          else
            case expiry(event, cooldown_ms) do
              {:ok, expiry_at} -> {:halt, DateTime.compare(now, expiry_at) == :lt}
              :error -> {:cont, false}
            end
          end

        true ->
          {:cont, false}
      end
    end)
  end

  defp expiry(event, cooldown_ms) do
    case value(event, :expires_at, "expires_at") do
      expires_at when is_binary(expires_at) ->
        case DateTime.from_iso8601(expires_at) do
          {:ok, datetime, _offset} -> {:ok, datetime}
          _ -> :error
        end

      _ ->
        case value(event, :timestamp, "timestamp") do
          timestamp when is_binary(timestamp) ->
            case DateTime.from_iso8601(timestamp) do
              {:ok, datetime, _offset} -> {:ok, DateTime.add(datetime, cooldown_ms, :millisecond)}
              _ -> :error
            end

          _ ->
            :error
        end
    end
  end

  defp to_atom_keys(map) do
    Map.new(map, fn
      {"type", value} -> {:type, value}
      {"node_id", value} -> {:node_id, value}
      {"daemon_id", value} -> {:daemon_id, value}
      {"target_unit", value} -> {:target_unit, value}
      {"reason", value} -> {:reason, reason_atom(value)}
      {"timestamp", value} -> {:timestamp, value}
      {"expires_at", value} -> {:expires_at, value}
      {key, value} -> {key, value}
    end)
  end

  defp reason_atom(value) when is_atom(value), do: value

  defp reason_atom(value) when is_binary(value) do
    try do
      String.to_existing_atom(value)
    rescue
      ArgumentError -> value
    end
  end

  defp reason_atom(value), do: value
  defp reason_to_string(value) when is_atom(value), do: Atom.to_string(value)
  defp reason_to_string(value), do: inspect(value)

  defp maybe_put_correlation_id(event, opts) do
    case Keyword.get(opts, :correlation_id) do
      value when is_binary(value) and byte_size(value) > 0 ->
        Map.put(event, "correlation_id", value)

      _ ->
        event
    end
  end

  defp value(map, atom_key, string_key) when is_map(map),
    do: Map.get(map, atom_key) || Map.get(map, string_key)

  defp value(_map, _atom_key, _string_key), do: nil

  defp safe_call(function) do
    {:ok, function.()}
  rescue
    error -> {:error, {:exception, Exception.message(error)}}
  catch
    kind, reason -> {:error, {kind, reason}}
  end
end
