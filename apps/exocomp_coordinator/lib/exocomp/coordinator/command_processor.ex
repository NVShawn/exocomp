# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.CommandReceipt do
  @moduledoc "The acknowledgement returned after a command is durably received."

  @enforce_keys [:command_id, :correlation_id, :status, :acknowledged_at]
  defstruct [:command_id, :correlation_id, :status, :acknowledged_at, duplicate: false]

  @type t :: %__MODULE__{
          command_id: String.t(),
          correlation_id: String.t(),
          status: :received,
          acknowledged_at: String.t(),
          duplicate: boolean()
        }
end

defmodule Exocomp.Coordinator.CommandResult do
  @moduledoc "The authoritative terminal result for a coordinator command."

  @enforce_keys [
    :event_id,
    :command_id,
    :correlation_id,
    :command_kind,
    :status,
    :occurred_at
  ]
  defstruct [
    :event_id,
    :command_id,
    :correlation_id,
    :command_kind,
    :status,
    :result,
    :error,
    :occurred_at
  ]

  @type t :: %__MODULE__{
          event_id: String.t(),
          command_id: String.t(),
          correlation_id: String.t(),
          command_kind: String.t(),
          status: :completed | :failed | :expired,
          result: term(),
          error: term(),
          occurred_at: String.t()
        }
end

defmodule Exocomp.Coordinator.CommandProcessor do
  @moduledoc """
  Receives and executes Mission Control commands exactly once.

  A command is first claimed and synced in the DETS ledger. Only the process
  that wins that claim schedules the handler. Receipt acknowledgement is
  deliberately separate from terminal execution status: `accept/2` returns a
  `%CommandReceipt{}` while `result/2` and the JSON-lines outbox expose the
  eventual terminal result.

  Pending claims are fail-closed on restart. They are converted to a terminal
  `:failed` result rather than being executed again. This is the same safety
  boundary as the node replay ledger, applied to coordinator command IDs.

  Handlers are supplied by the caller because command-specific chat and remedy
  handlers are outside this task. A handler may be a two-argument function
  `(payload, context)`, a one-argument function `(payload)`, an `{module,
  function}` tuple, or a module exporting `handle/2` or `handle/1`.
  """

  use GenServer

  alias Exocomp.Coordinator.{CommandReceipt, CommandResult}

  @schema_version 1
  @default_max_payload_bytes 1_048_576
  @default_table :exocomp_coordinator_command_ledger
  @default_ledger_path "/var/lib/exocomp-coordinator/commands.dets"
  @default_event_path "/var/lib/exocomp-coordinator/command-results.jsonl"
  @terminal_states [:completed, :failed, :expired]

  defstruct [
    :table,
    :dets,
    :ledger_path,
    :event_path,
    :now_fn,
    :handlers,
    :default_handler,
    :max_payload_bytes,
    events: [],
    event_ids: MapSet.new(),
    workers: %{}
  ]

  @type server :: GenServer.server()

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Accepts a command and returns its durable receipt acknowledgement."
  @spec accept(map(), server()) :: {:ok, CommandReceipt.t()} | {:error, term()}
  def accept(command, server \\ __MODULE__)

  def accept(command, server) when is_map(command) do
    GenServer.call(server, {:accept, command})
  end

  def accept(_command, _server), do: {:error, {:invalid_command, "command must be a map"}}

  @doc "Alias for `accept/2` used by delivery adapters."
  @spec handle_command(map(), server()) :: {:ok, CommandReceipt.t()} | {:error, term()}
  def handle_command(command, server \\ __MODULE__), do: accept(command, server)

  @doc "Returns the authoritative terminal result for a command ID."
  @spec result(String.t(), server()) :: {:ok, CommandResult.t()} | {:error, :not_found | :pending}
  def result(command_id, server \\ __MODULE__) when is_binary(command_id) do
    GenServer.call(server, {:result, command_id})
  end

  @doc "Returns the original receipt for a command ID."
  @spec receipt(String.t(), server()) :: {:ok, CommandReceipt.t()} | {:error, :not_found}
  def receipt(command_id, server \\ __MODULE__) when is_binary(command_id) do
    GenServer.call(server, {:receipt, command_id})
  end

  @doc "Returns all terminal result events currently present in the outbox."
  @spec events(server()) :: [map()]
  def events(server \\ __MODULE__), do: GenServer.call(server, :events)

  @doc "Returns the current command lifecycle status."
  @spec status(String.t(), server()) :: {:ok, atom()} | {:error, :not_found}
  def status(command_id, server \\ __MODULE__) when is_binary(command_id) do
    GenServer.call(server, {:status, command_id})
  end

  @impl true
  def init(opts) do
    table = Keyword.get(opts, :table, @default_table)
    ledger_path = ledger_path(opts)
    event_path = event_path(opts)
    dets = Keyword.get(opts, :dets_module, :dets)

    with :ok <- File.mkdir_p(Path.dirname(ledger_path)),
         :ok <- File.mkdir_p(Path.dirname(event_path)),
         {:ok, ^table} <-
           dets.open_file(table, file: String.to_charlist(ledger_path), type: :set),
         {:ok, events} <- load_events(event_path) do
      state = %__MODULE__{
        table: table,
        dets: dets,
        ledger_path: ledger_path,
        event_path: event_path,
        now_fn: Keyword.get(opts, :now_fn, &DateTime.utc_now/0),
        handlers: normalize_handlers(Keyword.get(opts, :handlers, %{})),
        default_handler: Keyword.get(opts, :handler),
        max_payload_bytes: Keyword.get(opts, :max_payload_bytes, @default_max_payload_bytes),
        events: events,
        event_ids: MapSet.new(Enum.map(events, &Map.get(&1, "event_id")))
      }

      case repair_records(state) do
        {:ok, repaired} -> {:ok, repaired}
        {:error, reason} -> close_and_stop(state, {:storage_unavailable, reason})
      end
    else
      {:error, reason} ->
        {:stop, {:storage_unavailable, reason}}

      other ->
        {:stop, {:storage_unavailable, other}}
    end
  rescue
    error -> {:stop, {:storage_unavailable, Exception.message(error)}}
  catch
    kind, reason -> {:stop, {:storage_unavailable, {kind, reason}}}
  end

  @impl true
  def handle_call({:accept, command}, _from, state) do
    with {:ok, normalized} <- validate_command(command, state),
         {:ok, reply, updated} <- claim_or_replay(normalized, state) do
      {:reply, reply, updated}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:result, command_id}, _from, state) do
    reply =
      case lookup(state, command_id) do
        {:ok, %{status: status, terminal: terminal}} when status in @terminal_states ->
          {:ok, result_struct(terminal)}

        {:ok, %{status: :pending}} ->
          {:error, :pending}

        :not_found ->
          {:error, :not_found}
      end

    {:reply, reply, state}
  end

  def handle_call({:receipt, command_id}, _from, state) do
    reply =
      case lookup(state, command_id) do
        {:ok, %{receipt: receipt}} -> {:ok, receipt_struct(receipt)}
        :not_found -> {:error, :not_found}
      end

    {:reply, reply, state}
  end

  def handle_call({:status, command_id}, _from, state) do
    reply =
      case lookup(state, command_id) do
        {:ok, %{status: status}} -> {:ok, status}
        :not_found -> {:error, :not_found}
      end

    {:reply, reply, state}
  end

  def handle_call(:events, _from, state), do: {:reply, state.events, state}

  @impl true
  def handle_info({:execute, command_id}, state) do
    case lookup(state, command_id) do
      {:ok, %{status: :pending, command: command}} ->
        handler = Map.get(state.handlers, command.kind, state.default_handler)
        parent = self()

        {pid, ref} =
          spawn_monitor(fn ->
            outcome = invoke_handler(handler, command)
            send(parent, {:handler_result, command_id, outcome})
          end)

        {:noreply, %{state | workers: Map.put(state.workers, ref, {command_id, pid})}}

      _other ->
        {:noreply, state}
    end
  end

  def handle_info({:handler_result, command_id, outcome}, state) do
    state = remove_worker_for_command(state, command_id)

    case outcome do
      {:ok, value} -> complete(command_id, :completed, value, nil, state)
      {:error, reason} -> complete(command_id, :failed, nil, reason, state)
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    case Map.pop(state.workers, ref) do
      {nil, _workers} ->
        {:noreply, state}

      {{command_id, _pid}, workers} ->
        state = %{state | workers: workers}

        case lookup(state, command_id) do
          {:ok, %{status: :pending}} ->
            complete(command_id, :failed, nil, {:handler_crash, inspect(reason)}, state)

          _other ->
            {:noreply, state}
        end
    end
  end

  def handle_info(_message, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, %{dets: dets, table: table, workers: workers}) do
    Enum.each(workers, fn {_ref, {_command_id, pid}} -> Process.exit(pid, :shutdown) end)
    dets.close(table)
    :ok
  end

  # ── Claim and execution ────────────────────────────────────────────────────

  defp claim_or_replay(command, state) do
    case lookup(state, command.command_id) do
      :not_found ->
        claim_new(command, state)

      {:ok, %{fingerprint: fingerprint} = record} ->
        if fingerprint != fingerprint(command) do
          {:error, :command_id_conflict}
        else
          receipt = receipt_struct(record.receipt, true)
          {:ok, {:ok, receipt}, state}
        end
    end
  end

  defp claim_new(command, state) do
    receipt = %{
      command_id: command.command_id,
      correlation_id: command.correlation_id,
      status: :received,
      acknowledged_at: timestamp(state),
      duplicate: false
    }

    record = %{
      command: command,
      fingerprint: fingerprint(command),
      receipt: receipt,
      status: :pending,
      terminal: nil,
      event: nil,
      event_published: false
    }

    cond do
      DateTime.compare(now(state), command.expires_at) != :lt ->
        expired = expire_record(record, state)

        with {:ok, state} <- persist_record(state, command.command_id, expired),
             {:ok, state} <- publish_record_event(state, command.command_id, expired) do
          {:ok, {:ok, receipt_struct(receipt)}, state}
        else
          {:error, reason, _state} -> {:error, reason}
          {:error, reason} -> {:error, reason}
        end

      is_nil(handler_for(command, state)) ->
        record = terminal_record(record, :failed, nil, {:unsupported_kind, command.kind}, state)

        with {:ok, state} <- persist_record(state, command.command_id, record),
             {:ok, state} <- publish_record_event(state, command.command_id, record) do
          {:ok, {:ok, receipt_struct(receipt)}, state}
        else
          {:error, reason, _state} -> {:error, reason}
          {:error, reason} -> {:error, reason}
        end

      true ->
        with {:ok, state} <- persist_record(state, command.command_id, record) do
          send(self(), {:execute, command.command_id})
          {:ok, {:ok, receipt_struct(receipt)}, state}
        end
    end
  end

  defp handler_for(command, state) do
    Map.get(state.handlers, command.kind, state.default_handler)
  end

  defp complete(command_id, status, value, error, state) do
    case lookup(state, command_id) do
      {:ok, %{status: :pending} = record} ->
        terminal = terminal_record(record, status, value, error, state)

        case persist_record(state, command_id, terminal) do
          {:ok, state} ->
            case publish_record_event(state, command_id, terminal) do
              {:ok, state} ->
                {:noreply, state}

              {:error, reason, state} ->
                {:stop, {:event_outbox_unavailable, reason}, state}
            end

          {:error, reason} ->
            {:stop, {:storage_unavailable, reason}, state}
        end

      _other ->
        {:noreply, state}
    end
  end

  defp expire_record(record, state),
    do: terminal_record(record, :expired, nil, :expired, state)

  defp terminal_record(record, status, value, error, state) do
    command = record.command
    occurred_at = timestamp(state)
    event_id = event_id(command.command_id)

    terminal = %{
      event_id: event_id,
      command_id: command.command_id,
      correlation_id: command.correlation_id,
      command_kind: command.kind,
      status: status,
      result: value,
      error: error,
      occurred_at: occurred_at
    }

    %{record | status: status, terminal: terminal, event: terminal, event_published: false}
  end

  # ── Durable storage and event outbox ────────────────────────────────────────

  defp persist_record(state, command_id, record) do
    case state.dets.insert(state.table, {command_id, record}) do
      :ok ->
        case state.dets.sync(state.table) do
          :ok -> {:ok, state}
          {:error, reason} -> {:error, {:sync_failed, reason}}
          other -> {:error, {:sync_failed, other}}
        end

      {:error, reason} ->
        {:error, {:write_failed, reason}}

      other ->
        {:error, {:write_failed, other}}
    end
  rescue
    error -> {:error, {:write_failed, Exception.message(error)}}
  catch
    kind, reason -> {:error, {:write_failed, {kind, reason}}}
  end

  defp publish_record_event(state, command_id, record) do
    event = event_map(record.event)

    if MapSet.member?(state.event_ids, event["event_id"]) do
      updated = %{record | event_published: true}

      case persist_record(state, command_id, updated) do
        {:ok, state} -> {:ok, state}
        {:error, reason} -> {:error, reason, state}
      end
    else
      line = [Jason.encode!(event), ?\n]

      with :ok <- append_event(state.event_path, line),
           updated = %{record | event_published: true},
           {:ok, state} <- persist_record(state, command_id, updated) do
        {:ok,
         %{
           state
           | events: state.events ++ [event],
             event_ids: MapSet.put(state.event_ids, event["event_id"])
         }}
      else
        {:error, reason} -> {:error, reason, state}
      end
    end
  rescue
    error -> {:error, {:event_encode_failed, Exception.message(error)}, state}
  end

  defp append_event(path, line) do
    with {:ok, io} <- File.open(path, [:append, :binary]),
         :ok <- IO.binwrite(io, line),
         :ok <- :file.sync(io),
         :ok <- File.close(io) do
      :ok
    else
      {:error, reason} -> {:error, {:event_write_failed, reason}}
      other -> {:error, {:event_write_failed, other}}
    end
  end

  defp repair_records(state) do
    records = state.dets.foldl(fn record, acc -> [record | acc] end, [], state.table)

    Enum.reduce_while(records, {:ok, state}, fn
      {command_id, %{status: :pending} = record}, {:ok, state} ->
        repaired =
          terminal_record(record, :failed, nil, :coordinator_restarted, state)

        with {:ok, state} <- persist_record(state, command_id, repaired),
             {:ok, state} <- publish_record_event(state, command_id, repaired) do
          {:cont, {:ok, state}}
        else
          {:error, reason} -> {:halt, {:error, reason}}
          {:error, reason, _state} -> {:halt, {:error, reason}}
        end

      {command_id, %{status: status, event_published: false} = record}, {:ok, state}
      when status in @terminal_states ->
        case publish_record_event(state, command_id, record) do
          {:ok, state} -> {:cont, {:ok, state}}
          {:error, reason, _state} -> {:halt, {:error, reason}}
        end

      _record, acc ->
        {:cont, acc}
    end)
  rescue
    error -> {:error, {:repair_failed, Exception.message(error)}}
  catch
    kind, reason -> {:error, {:repair_failed, {kind, reason}}}
  end

  defp lookup(state, command_id) do
    case state.dets.lookup(state.table, command_id) do
      [{^command_id, record}] when is_map(record) -> {:ok, record}
      [] -> :not_found
      _other -> :not_found
    end
  rescue
    _error -> :not_found
  end

  defp load_events(path) do
    if File.exists?(path) do
      path
      |> File.stream!([], :line)
      |> Enum.reduce_while({:ok, []}, fn line, {:ok, events} ->
        case Jason.decode(line) do
          {:ok, %{"event_id" => _} = event} -> {:cont, {:ok, events ++ [event]}}
          _other -> {:cont, {:ok, events}}
        end
      end)
    else
      {:ok, []}
    end
  rescue
    error -> {:error, {:event_read_failed, Exception.message(error)}}
  end

  defp close_and_stop(state, reason) do
    state.dets.close(state.table)
    {:stop, reason}
  end

  # ── Validation and handler invocation ───────────────────────────────────────

  defp validate_command(command, state) do
    allowed =
      MapSet.new(~w(schema_version command_id kind issued_at expires_at payload correlation_id))

    unknown =
      command
      |> Map.keys()
      |> Enum.map(&to_string/1)
      |> Enum.reject(&MapSet.member?(allowed, &1))

    with :ok <- if(unknown == [], do: :ok, else: {:error, {:unknown_fields, unknown}}),
         {:ok, schema_version} <- fetch_optional(command, "schema_version", @schema_version),
         :ok <- validate_schema_version(schema_version),
         {:ok, command_id} <- required_string(command, "command_id"),
         {:ok, kind} <- required_string(command, "kind"),
         {:ok, issued_at} <- required_timestamp(command, "issued_at"),
         {:ok, expires_at} <- required_timestamp(command, "expires_at"),
         :ok <- validate_expiry_order(issued_at, expires_at),
         {:ok, payload} <- required_map(command, "payload"),
         :ok <- validate_payload_size(payload, state.max_payload_bytes),
         {:ok, correlation_id} <- correlation_id(command, command_id) do
      {:ok,
       %{
         schema_version: schema_version,
         command_id: command_id,
         kind: kind,
         issued_at: issued_at,
         expires_at: expires_at,
         payload: payload,
         correlation_id: correlation_id
       }}
    end
  end

  defp validate_schema_version(@schema_version), do: :ok
  defp validate_schema_version(value), do: {:error, {:unsupported_schema_version, value}}

  defp validate_expiry_order(issued_at, expires_at) do
    if DateTime.compare(issued_at, expires_at) == :lt,
      do: :ok,
      else: {:error, :invalid_expiry}
  end

  defp validate_payload_size(payload, max_bytes) do
    with {:ok, encoded} <- Jason.encode(json_safe(payload)) do
      if byte_size(encoded) <= max_bytes,
        do: :ok,
        else: {:error, :payload_too_large}
    else
      _error -> {:error, :invalid_payload}
    end
  end

  defp required_string(map, key) do
    case fetch(map, key) do
      {:ok, value} when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _other -> {:error, {:invalid_field, key}}
    end
  end

  defp required_map(map, key) do
    case fetch(map, key) do
      {:ok, value} when is_map(value) -> {:ok, value}
      _other -> {:error, {:invalid_field, key}}
    end
  end

  defp required_timestamp(map, key) do
    case fetch(map, key) do
      {:ok, %DateTime{} = value} -> {:ok, DateTime.shift_zone!(value, "Etc/UTC")}
      {:ok, value} when is_binary(value) -> parse_timestamp(value, key)
      _other -> {:error, {:invalid_field, key}}
    end
  end

  defp parse_timestamp(value, key) do
    case DateTime.from_iso8601(value) do
      {:ok, timestamp, _offset} -> {:ok, DateTime.shift_zone!(timestamp, "Etc/UTC")}
      _error -> {:error, {:invalid_field, key}}
    end
  end

  defp correlation_id(map, command_id) do
    case fetch(map, "correlation_id") do
      :error -> {:ok, "corr_" <> command_id}
      {:ok, value} when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _other -> {:error, {:invalid_field, "correlation_id"}}
    end
  end

  defp fetch_optional(map, key, default) do
    case fetch(map, key) do
      :error -> {:ok, default}
      {:ok, value} -> {:ok, value}
    end
  end

  defp fetch(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error -> Map.fetch(map, String.to_existing_atom(key))
    end
  end

  defp normalize_handlers(handlers) when is_map(handlers),
    do: Map.new(handlers, fn {kind, handler} -> {to_string(kind), handler} end)

  defp normalize_handlers(handlers) when is_list(handlers),
    do: Map.new(handlers, fn {kind, handler} -> {to_string(kind), handler} end)

  defp normalize_handlers(_handlers), do: %{}

  defp invoke_handler(nil, _command), do: {:error, :unsupported_kind}

  defp invoke_handler(handler, command) do
    context = %{
      command_id: command.command_id,
      correlation_id: command.correlation_id,
      kind: command.kind,
      issued_at: command.issued_at,
      expires_at: command.expires_at
    }

    value =
      cond do
        is_function(handler, 2) ->
          handler.(command.payload, context)

        is_function(handler, 1) ->
          handler.(command.payload)

        is_tuple(handler) and tuple_size(handler) == 2 ->
          apply(elem(handler, 0), elem(handler, 1), [command.payload, context])

        is_atom(handler) and function_exported?(handler, :handle, 2) ->
          handler.handle(command.payload, context)

        is_atom(handler) and function_exported?(handler, :handle, 1) ->
          handler.handle(command.payload)

        true ->
          raise ArgumentError, "invalid command handler"
      end

    case value do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
      result -> {:ok, result}
    end
  rescue
    error -> {:error, {:handler_crash, Exception.message(error)}}
  catch
    kind, reason -> {:error, {:handler_crash, {kind, inspect(reason)}}}
  end

  # ── Representation helpers ──────────────────────────────────────────────────

  defp result_struct(terminal) do
    struct!(CommandResult, terminal)
  end

  defp receipt_struct(receipt, duplicate \\ nil) do
    duplicate = if is_nil(duplicate), do: Map.get(receipt, :duplicate, false), else: duplicate
    struct!(CommandReceipt, Map.put(receipt, :duplicate, duplicate))
  end

  defp event_map(terminal) do
    payload = %{
      "command_id" => terminal.command_id,
      "command_kind" => terminal.command_kind,
      "status" => Atom.to_string(terminal.status),
      "result" => json_safe(terminal.result),
      "error" => json_safe(terminal.error)
    }

    %{
      "schema_version" => @schema_version,
      "event_id" => terminal.event_id,
      "kind" => "command.result",
      "occurred_at" => terminal.occurred_at,
      "correlation_id" => terminal.correlation_id,
      "command_id" => terminal.command_id,
      "payload" => payload
    }
  end

  defp json_safe(%_{} = struct), do: struct |> Map.from_struct() |> json_safe()

  defp json_safe(map) when is_map(map),
    do: Map.new(map, fn {key, value} -> {to_string(key), json_safe(value)} end)

  defp json_safe(list) when is_list(list), do: Enum.map(list, &json_safe/1)
  defp json_safe(tuple) when is_tuple(tuple), do: tuple |> Tuple.to_list() |> json_safe()
  defp json_safe(value) when is_atom(value), do: Atom.to_string(value)
  defp json_safe(value) when is_binary(value) or is_number(value) or is_nil(value), do: value
  defp json_safe(value), do: inspect(value)

  defp fingerprint(command), do: :crypto.hash(:sha256, :erlang.term_to_binary(command))

  defp event_id(command_id),
    do:
      "evt_" <>
        Base.url_encode64(:crypto.hash(:sha256, "command.result:" <> command_id), padding: false)

  defp remove_worker_for_command(state, command_id) do
    {matching, remaining} =
      Enum.split_with(state.workers, fn {_ref, {id, _pid}} -> id == command_id end)

    Enum.each(matching, fn {ref, {_id, _pid}} -> Process.demonitor(ref, [:flush]) end)
    %{state | workers: Map.new(remaining)}
  end

  defp now(state), do: state.now_fn.()
  defp timestamp(state), do: now(state) |> DateTime.to_iso8601()

  defp ledger_path(opts),
    do:
      Keyword.get(
        opts,
        :path,
        Application.get_env(:exocomp_coordinator, :command_ledger_path, @default_ledger_path)
      )

  defp event_path(opts),
    do:
      Keyword.get(
        opts,
        :event_path,
        Application.get_env(:exocomp_coordinator, :command_event_path, @default_event_path)
      )
end
