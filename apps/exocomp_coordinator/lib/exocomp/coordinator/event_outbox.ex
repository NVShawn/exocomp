# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.EventOutbox do
  @moduledoc """
  Durable, at-least-once Mission Control event outbox.

  The outbox is intentionally independent of the Mission Control transport.
  A caller enqueues an event, marks it as sent when it has handed the event to
  the transport, and acknowledges only the highest sequence committed by the
  server.  Events are written before `enqueue/2` returns and acknowledgement
  removes them only when the persisted sequence range is contiguous.

  The on-disk format is a versioned JSON document.  Updates are written to a
  synced temporary file and atomically renamed into place, which makes a
  process or host restart reopen the last complete state rather than a partial
  write.
  """

  use GenServer

  alias Exocomp.Coordinator.Audit

  @schema_version 1
  @storage_version 1
  @default_store_path "/var/lib/exocomp-coordinator"
  @default_file_name "event_outbox.json"
  @default_max_storage_bytes 10 * 1_024 * 1_024
  @default_max_event_bytes 256 * 1_024
  @max_cluster_id_bytes 256
  @max_event_id_bytes 256
  @max_correlation_id_bytes 256

  @event_kinds [
    "cluster.hello",
    "cluster.heartbeat",
    "status.snapshot",
    "alert.opened",
    "alert.updated",
    "alert.resolved",
    "conversation.reply",
    "proposal.created",
    "approval.result",
    "action.status",
    "audit.event"
  ]

  @type event :: %{
          required(:schema_version) => pos_integer(),
          required(:event_id) => String.t(),
          required(:cluster_seq) => pos_integer(),
          required(:kind) => String.t(),
          required(:occurred_at) => String.t(),
          required(:correlation_id) => String.t(),
          required(:payload) => map(),
          optional(:cluster_id) => String.t(),
          optional(:sent) => boolean()
        }

  @type enqueue_result :: {:ok, event()} | {:error, term()}

  @doc "Starts the durable outbox. `:path` is a file; `:store_path` is a directory."
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Enqueues an event whose `cluster_id` is in the event or in `opts`."
  @spec enqueue(map()) :: enqueue_result()
  def enqueue(event) when is_map(event), do: enqueue(event, [])

  @spec enqueue(map(), keyword()) :: enqueue_result()
  def enqueue(event, opts) when is_map(event) and is_list(opts) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:enqueue, Keyword.get(opts, :cluster_id), event})
  end

  @doc "Enqueues an event for `cluster_id`."
  @spec enqueue(String.t(), map()) :: enqueue_result()
  def enqueue(cluster_id, event) when is_binary(cluster_id) and is_map(event),
    do: enqueue(cluster_id, event, [])

  @spec enqueue(String.t(), map(), keyword()) :: enqueue_result()
  def enqueue(cluster_id, event, opts)
      when is_binary(cluster_id) and is_map(event) and is_list(opts) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:enqueue, cluster_id, event})
  end

  @doc "Returns all currently retained events in per-cluster sequence order."
  @spec events(keyword()) :: [event()]
  def events(opts \\ []) when is_list(opts) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, :events)
  end

  @doc "Returns retained events for one cluster."
  @spec events(String.t(), keyword()) :: [event()]
  def events(cluster_id, opts) when is_binary(cluster_id) and is_list(opts) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:events, cluster_id})
  end

  @doc "Alias for `events/0` commonly used by delivery workers."
  @spec pending(keyword()) :: [event()]
  def pending(opts \\ []) when is_list(opts), do: events(opts)

  @doc "Alias for `events/1` commonly used by delivery workers."
  @spec pending(String.t(), keyword()) :: [event()]
  def pending(cluster_id, opts) when is_binary(cluster_id) and is_list(opts),
    do: events(cluster_id, opts)

  @doc "Marks an event as handed to the transport, preventing snapshot coalescing."
  @spec mark_sent(String.t(), keyword()) :: :ok | {:error, term()}
  def mark_sent(event_id, opts \\ []) when is_binary(event_id) and is_list(opts) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:mark_sent, event_id})
  end

  @doc "Acknowledges a committed, contiguous sequence for a cluster."
  @spec acknowledge(String.t(), pos_integer()) :: {:ok, [event()]} | {:error, term()}
  def acknowledge(cluster_id, sequence) when is_binary(cluster_id) and is_integer(sequence),
    do: acknowledge(cluster_id, sequence, [])

  @spec acknowledge(String.t(), pos_integer(), keyword()) :: {:ok, [event()]} | {:error, term()}
  def acknowledge(cluster_id, sequence, opts)
      when is_binary(cluster_id) and is_integer(sequence) and is_list(opts) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, {:acknowledge, cluster_id, sequence})
  end

  @doc "Alias for `acknowledge/3`."
  @spec ack(String.t(), pos_integer()) :: {:ok, [event()]} | {:error, term()}
  def ack(cluster_id, sequence), do: acknowledge(cluster_id, sequence)

  @spec ack(String.t(), pos_integer(), keyword()) :: {:ok, [event()]} | {:error, term()}
  def ack(cluster_id, sequence, opts), do: acknowledge(cluster_id, sequence, opts)

  @doc "Returns safe storage and queue metadata."
  @spec status(keyword()) :: map()
  def status(opts \\ []) when is_list(opts) do
    server = Keyword.get(opts, :server, __MODULE__)
    GenServer.call(server, :status)
  end

  @doc "Returns the supported protocol event kinds."
  @spec event_kinds() :: [String.t()]
  def event_kinds, do: @event_kinds

  @impl true
  def init(opts) do
    path = storage_file(opts)

    max_storage_bytes =
      Keyword.get(
        opts,
        :max_storage_bytes,
        Keyword.get(opts, :max_bytes, @default_max_storage_bytes)
      )

    max_event_bytes = Keyword.get(opts, :max_event_bytes, @default_max_event_bytes)
    default_cluster_id = Keyword.get(opts, :cluster_id)

    with :ok <- validate_limit(max_storage_bytes, :max_storage_bytes),
         :ok <- validate_limit(max_event_bytes, :max_event_bytes),
         :ok <- validate_cluster_id(default_cluster_id, true),
         {:ok, state} <- open_storage(path, max_storage_bytes) do
      {:ok,
       %{
         path: path,
         directory: Path.dirname(path),
         max_storage_bytes: max_storage_bytes,
         max_event_bytes: max_event_bytes,
         default_cluster_id: default_cluster_id,
         state: state,
         last_error: nil
       }}
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call({:enqueue, requested_cluster_id, raw_event}, _from, state) do
    cluster_id =
      requested_cluster_id || map_get(raw_event, :cluster_id) || state.default_cluster_id

    case find_event_by_id(state.state.events, map_get(raw_event, :event_id)) do
      {:ok, existing} ->
        if same_event_request?(existing, raw_event, cluster_id) do
          {:reply, {:ok, public_event(existing)}, state}
        else
          {:reply, {:error, {:duplicate_event_id, map_get(raw_event, :event_id)}}, state}
        end

      :not_found ->
        case build_event(raw_event, cluster_id, state) do
          {:ok, event} -> persist_enqueue(event, state)
          {:error, reason} -> {:reply, {:error, reason}, state}
        end
    end
  end

  def handle_call(:events, _from, state) do
    {:reply, Enum.map(sorted_events(state.state.events), &public_event/1), state}
  end

  def handle_call({:events, cluster_id}, _from, state) do
    events =
      state.state.events
      |> Enum.filter(&(&1.cluster_id == cluster_id))
      |> sorted_events()
      |> Enum.map(&public_event/1)

    {:reply, events, state}
  end

  def handle_call({:mark_sent, event_id}, _from, state) do
    case find_event_by_id(state.state.events, event_id) do
      :not_found ->
        {:reply, {:error, :event_not_found}, state}

      {:ok, %{sent: true}} ->
        {:reply, :ok, state}

      {:ok, event} ->
        new_events = replace_event(state.state.events, event, %{event | sent: true})

        case persist_state(%{state.state | events: new_events}, state) do
          {:ok, new_store} -> {:reply, :ok, %{state | state: new_store, last_error: nil}}
          {:error, reason} -> storage_failure(reason, state)
        end
    end
  end

  def handle_call({:acknowledge, cluster_id, sequence}, _from, state) do
    case acknowledge_state(state.state, cluster_id, sequence) do
      {:ok, deleted, new_store} ->
        case persist_state(new_store, state) do
          {:ok, persisted} ->
            {:reply, {:ok, Enum.map(deleted, &public_event/1)},
             %{state | state: persisted, last_error: nil}}

          {:error, reason} ->
            storage_failure(reason, state)
        end

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:status, _from, state) do
    stat =
      case File.stat(state.path) do
        {:ok, file_stat} -> %{bytes: file_stat.size}
        {:error, _} -> %{bytes: nil}
      end

    clusters =
      Map.new(state.state.clusters, fn {cluster_id, cluster} ->
        {cluster_id,
         %{
           next_sequence: cluster.next_sequence,
           acknowledged_sequence: cluster.acknowledged_sequence
         }}
      end)

    {:reply,
     Map.merge(stat, %{
       path: state.path,
       event_count: length(state.state.events),
       clusters: clusters,
       healthy: is_nil(state.last_error),
       last_error: state.last_error
     }), state}
  end

  # ── Event construction and queue policy ──────────────────────────────────────

  defp build_event(raw_event, requested_cluster_id, state) do
    cluster_id = requested_cluster_id || state.default_cluster_id
    schema_version = map_get(raw_event, :schema_version, @schema_version)
    kind = raw_event |> map_get(:kind) |> normalize_kind()
    payload = map_get(raw_event, :payload)

    with :ok <- validate_cluster_id(cluster_id, false),
         :ok <- validate_schema_version(schema_version),
         :ok <- validate_kind(kind),
         :ok <- validate_payload(payload),
         {:ok, normalized_payload} <- normalize_and_redact(payload),
         {:ok, event_id} <- event_id(raw_event),
         {:ok, occurred_at} <- occurred_at(raw_event),
         {:ok, correlation_id} <- correlation_id(raw_event),
         :ok <- validate_known_fields(raw_event),
         {:ok, sequence} <- next_sequence(state.state, cluster_id) do
      event = %{
        schema_version: @schema_version,
        event_id: event_id,
        cluster_id: cluster_id,
        cluster_seq: sequence,
        kind: kind,
        occurred_at: occurred_at,
        correlation_id: correlation_id,
        payload: normalized_payload,
        sent: false
      }

      case validate_event_size(event, state.max_event_bytes) do
        :ok -> {:ok, event}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp persist_enqueue(event, state) do
    {events, replaced?, persisted_event} = coalesce_snapshot(state.state.events, event)

    cluster =
      Map.get(state.state.clusters, event.cluster_id, %{
        next_sequence: 1,
        acknowledged_sequence: 0
      })

    new_store = %{
      state.state
      | events: events,
        clusters:
          Map.put(
            state.state.clusters,
            event.cluster_id,
            %{
              cluster
              | next_sequence:
                  if(replaced?, do: cluster.next_sequence, else: cluster.next_sequence + 1)
            }
          )
    }

    case persist_state(new_store, state) do
      {:ok, persisted} ->
        {:reply, {:ok, public_event(persisted_event)},
         %{state | state: persisted, last_error: nil}}

      {:error, reason} ->
        storage_failure(reason, state)
    end
  end

  defp coalesce_snapshot(events, %{kind: "status.snapshot", cluster_id: cluster_id} = event) do
    case Enum.find(events, fn existing ->
           existing.cluster_id == cluster_id and existing.kind == "status.snapshot" and
             existing.sent == false
         end) do
      nil ->
        {[event | events], false, event}

      old ->
        replacement = %{event | cluster_seq: old.cluster_seq}
        {replace_event(events, old, replacement), true, replacement}
    end
  end

  defp coalesce_snapshot(events, event), do: {[event | events], false, event}

  defp acknowledge_state(store, cluster_id, sequence) do
    with :ok <- validate_cluster_id(cluster_id, false),
         :ok <- validate_sequence(sequence),
         {:ok, cluster} <- fetch_cluster(store, cluster_id),
         :ok <- validate_ack_range(cluster, sequence),
         :ok <-
           validate_contiguous(store.events, cluster_id, cluster.acknowledged_sequence, sequence) do
      if sequence <= cluster.acknowledged_sequence do
        {:ok, [], store}
      else
        delete_acknowledged(store, cluster_id, sequence, cluster)
      end
    end
  end

  defp delete_acknowledged(store, cluster_id, sequence, cluster) do
    deleted =
      Enum.filter(store.events, fn event ->
        event.cluster_id == cluster_id and event.cluster_seq <= sequence
      end)

    retained =
      Enum.reject(store.events, &(&1.cluster_id == cluster_id and &1.cluster_seq <= sequence))

    new_store = %{
      store
      | events: retained,
        clusters:
          Map.put(store.clusters, cluster_id, %{cluster | acknowledged_sequence: sequence})
    }

    {:ok, Enum.sort_by(deleted, & &1.cluster_seq), new_store}
  end

  defp validate_ack_range(
         %{next_sequence: next_sequence, acknowledged_sequence: acknowledged},
         sequence
       ) do
    cond do
      sequence < acknowledged -> :ok
      sequence == acknowledged -> :ok
      sequence >= next_sequence -> {:error, :ack_out_of_range}
      true -> :ok
    end
  end

  defp validate_contiguous(_events, _cluster_id, acknowledged, sequence)
       when sequence <= acknowledged,
       do: :ok

  defp validate_contiguous(events, cluster_id, acknowledged, sequence) do
    actual =
      events
      |> Enum.filter(fn event ->
        event.cluster_id == cluster_id and event.cluster_seq > acknowledged and
          event.cluster_seq <= sequence
      end)
      |> Enum.map(& &1.cluster_seq)
      |> MapSet.new()

    expected = MapSet.new((acknowledged + 1)..sequence)

    if actual == expected, do: :ok, else: {:error, :non_contiguous_ack}
  end

  defp next_sequence(store, cluster_id) do
    case Map.get(store.clusters, cluster_id) do
      nil -> {:ok, 1}
      %{next_sequence: next_sequence} -> {:ok, next_sequence}
    end
  end

  defp fetch_cluster(store, cluster_id) do
    case Map.fetch(store.clusters, cluster_id) do
      {:ok, cluster} -> {:ok, cluster}
      :error -> {:error, :cluster_not_found}
    end
  end

  # ── Storage ──────────────────────────────────────────────────────────────────

  defp storage_file(opts) do
    cond do
      is_binary(Keyword.get(opts, :path)) -> Keyword.fetch!(opts, :path)
      is_binary(Keyword.get(opts, :file)) -> Keyword.fetch!(opts, :file)
      true -> Path.join(Keyword.get(opts, :store_path, @default_store_path), @default_file_name)
    end
  end

  defp open_storage(path, max_storage_bytes) do
    directory = Path.dirname(path)

    with :ok <- File.mkdir_p(directory),
         :ok <- File.chmod(directory, 0o700) do
      case File.read(path) do
        {:ok, encoded} ->
          with :ok <- File.chmod(path, 0o600) do
            if byte_size(encoded) > max_storage_bytes do
              {:error, {:storage_unavailable, :storage_full}}
            else
              decode_storage(encoded)
            end
          else
            {:error, reason} -> {:error, {:storage_unavailable, reason}}
          end

        {:error, :enoent} ->
          state = empty_store()

          case persist_disk(state, path, max_storage_bytes) do
            :ok -> {:ok, state}
            {:error, reason} -> {:error, {:storage_unavailable, reason}}
          end

        {:error, reason} ->
          {:error, {:storage_unavailable, reason}}
      end
    else
      {:error, reason} -> {:error, {:storage_unavailable, reason}}
    end
  end

  defp decode_storage(<<>>), do: {:error, {:storage_unavailable, :event_outbox_corrupt}}

  defp decode_storage(encoded) do
    with {:ok, decoded} <- Jason.decode(encoded),
         {:ok, store} <- from_disk(decoded) do
      {:ok, store}
    else
      _ -> {:error, {:storage_unavailable, :event_outbox_corrupt}}
    end
  rescue
    _ -> {:error, {:storage_unavailable, :event_outbox_corrupt}}
  end

  defp empty_store, do: %{version: @storage_version, clusters: %{}, events: []}

  defp from_disk(%{"version" => @storage_version, "clusters" => clusters, "events" => events})
       when is_map(clusters) and is_list(events) do
    with {:ok, normalized_clusters} <- decode_clusters(clusters),
         {:ok, normalized_events} <- decode_events(events),
         :ok <- validate_store_sequences(normalized_clusters, normalized_events) do
      {:ok,
       %{version: @storage_version, clusters: normalized_clusters, events: normalized_events}}
    else
      _ -> {:error, :invalid_storage}
    end
  end

  defp from_disk(_), do: {:error, :invalid_storage}

  defp decode_clusters(clusters) do
    Enum.reduce_while(clusters, {:ok, %{}}, fn
      {cluster_id, %{"next_sequence" => next, "acknowledged_sequence" => acknowledged}},
      {:ok, acc}
      when is_binary(cluster_id) and is_integer(next) and next >= 1 and is_integer(acknowledged) and
             acknowledged >= 0 and acknowledged < next ->
        {:cont,
         {:ok,
          Map.put(acc, cluster_id, %{next_sequence: next, acknowledged_sequence: acknowledged})}}

      _entry, _acc ->
        {:halt, {:error, :invalid_cluster}}
    end)
  end

  defp decode_events(events) do
    Enum.reduce_while(events, {:ok, []}, fn event, {:ok, acc} ->
      case decode_event(event) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, _} -> {:halt, {:error, :invalid_event}}
      end
    end)
    |> case do
      {:ok, decoded} -> {:ok, Enum.reverse(decoded)}
      error -> error
    end
  end

  defp decode_event(%{
         "schema_version" => @schema_version,
         "event_id" => event_id,
         "cluster_id" => cluster_id,
         "cluster_seq" => sequence,
         "kind" => kind,
         "occurred_at" => occurred_at,
         "correlation_id" => correlation_id,
         "payload" => payload,
         "sent" => sent
       })
       when is_binary(event_id) and is_binary(cluster_id) and is_integer(sequence) and
              sequence >= 1 and
              is_binary(kind) and is_binary(occurred_at) and is_binary(correlation_id) and
              is_map(payload) and is_boolean(sent) do
    event = %{
      schema_version: @schema_version,
      event_id: event_id,
      cluster_id: cluster_id,
      cluster_seq: sequence,
      kind: kind,
      occurred_at: occurred_at,
      correlation_id: correlation_id,
      payload: payload,
      sent: sent
    }

    with :ok <- validate_cluster_id(cluster_id, false),
         :ok <- validate_kind(kind),
         :ok <- validate_payload(payload),
         {:ok, redacted_payload} <- normalize_and_redact(payload),
         :ok <- validate_event_size(event, @default_max_event_bytes) do
      {:ok, %{event | payload: redacted_payload}}
    end
  end

  defp decode_event(_), do: {:error, :invalid_event}

  defp validate_store_sequences(clusters, events) do
    grouped = Enum.group_by(events, & &1.cluster_id)

    valid_cluster_ids? = Map.keys(grouped) |> Enum.all?(&Map.has_key?(clusters, &1))

    if not valid_cluster_ids? do
      {:error, :invalid_sequence_state}
    else
      Enum.reduce_while(clusters, :ok, fn {cluster_id, cluster}, :ok ->
        cluster_events = Map.get(grouped, cluster_id, [])
        sequences = Enum.map(cluster_events, & &1.cluster_seq)

        valid? =
          Enum.all?(
            sequences,
            &(&1 > cluster.acknowledged_sequence and &1 < cluster.next_sequence)
          ) and
            length(sequences) == length(Enum.uniq(sequences))

        if valid?, do: {:cont, :ok}, else: {:halt, {:error, :invalid_sequence_state}}
      end)
    end
  end

  defp persist_state(store, state) do
    if Enum.count(store.events) > 0 and
         Enum.any?(store.events, &(not is_map(&1.payload))) do
      {:error, :invalid_event}
    else
      case persist_disk(store, state.path, state.max_storage_bytes) do
        :ok -> {:ok, store}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp persist_disk(store, path, max_storage_bytes) do
    disk = %{
      "version" => @storage_version,
      "clusters" =>
        Map.new(store.clusters, fn {cluster_id, cluster} ->
          {cluster_id,
           %{
             "next_sequence" => cluster.next_sequence,
             "acknowledged_sequence" => cluster.acknowledged_sequence
           }}
        end),
      "events" => Enum.map(sorted_events(store.events), &disk_event/1)
    }

    with {:ok, encoded} <- Jason.encode(disk),
         :ok <- validate_storage_size(encoded, max_storage_bytes),
         :ok <- atomic_write(path, encoded) do
      :ok
    end
  end

  defp atomic_write(path, encoded) do
    temporary = path <> ".tmp-" <> Integer.to_string(System.unique_integer([:positive]))

    result =
      with {:ok, io} <- File.open(temporary, [:write, :binary, :exclusive]),
           :ok <- IO.binwrite(io, encoded),
           :ok <- :file.sync(io),
           :ok <- File.close(io),
           :ok <- File.chmod(temporary, 0o600),
           :ok <- File.rename(temporary, path),
           :ok <- sync_directory(Path.dirname(path)) do
        :ok
      end

    case result do
      :ok ->
        :ok

      {:error, reason} ->
        _ = File.rm(temporary)
        normalize_storage_error(reason)
    end
  end

  defp sync_directory(directory) do
    case File.open(directory, [:read]) do
      {:ok, io} ->
        result = :file.sync(io)
        _ = File.close(io)
        result

      {:error, :einval} ->
        :ok

      {:error, :eisdir} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp normalize_storage_error(reason) when reason in [:enospc, :edquot, :storage_full],
    do: :storage_full

  defp normalize_storage_error(reason), do: {:storage_unavailable, reason}

  defp storage_failure(reason, state) do
    normalized = normalize_storage_error(reason)
    {:reply, {:error, normalized}, %{state | last_error: normalized}}
  end

  # ── Validation ───────────────────────────────────────────────────────────────

  defp validate_limit(value, _name) when is_integer(value) and value > 0, do: :ok
  defp validate_limit(_value, name), do: {:error, {:invalid_option, name}}

  defp validate_cluster_id(nil, true), do: :ok

  defp validate_cluster_id(value, _allow_nil)
       when is_binary(value) and byte_size(value) > 0 and
              byte_size(value) <= @max_cluster_id_bytes,
       do: :ok

  defp validate_cluster_id(_value, true), do: {:error, {:invalid_option, :cluster_id}}
  defp validate_cluster_id(_value, false), do: {:error, {:invalid_event, :cluster_id}}

  defp validate_schema_version(@schema_version), do: :ok
  defp validate_schema_version(_), do: {:error, {:invalid_event, :schema_version}}

  defp validate_kind(kind) when kind in @event_kinds, do: :ok
  defp validate_kind(_), do: {:error, {:invalid_event, :kind}}

  defp validate_payload(payload) when is_map(payload), do: :ok
  defp validate_payload(_), do: {:error, {:invalid_event, :payload}}

  defp normalize_kind(kind) when is_atom(kind), do: Atom.to_string(kind)
  defp normalize_kind(kind) when is_binary(kind), do: kind
  defp normalize_kind(_), do: nil

  defp normalize_and_redact(payload) do
    payload
    |> Audit.redact()
    |> json_safe()
    |> then(fn normalized ->
      case Jason.encode(normalized) do
        {:ok, _} -> {:ok, normalized}
        {:error, _} -> {:error, {:invalid_event, :payload_schema}}
      end
    end)
  rescue
    _ -> {:error, {:invalid_event, :payload_schema}}
  end

  defp json_safe(%_{} = struct), do: struct |> Map.from_struct() |> json_safe()

  defp json_safe(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), json_safe(value)} end)
  end

  defp json_safe(list) when is_list(list), do: Enum.map(list, &json_safe/1)
  defp json_safe(value) when is_atom(value), do: Atom.to_string(value)
  defp json_safe(value) when is_binary(value) or is_number(value) or is_nil(value), do: value
  defp json_safe(value), do: value

  defp event_id(event) do
    case map_get(event, :event_id) do
      nil ->
        entropy = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
        {:ok, "evt_" <> entropy}

      value
      when is_binary(value) and byte_size(value) > 0 and byte_size(value) <= @max_event_id_bytes ->
        {:ok, value}

      _ ->
        {:error, {:invalid_event, :event_id}}
    end
  end

  defp occurred_at(event) do
    case map_get(event, :occurred_at) do
      nil -> {:ok, DateTime.utc_now() |> DateTime.to_iso8601()}
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, {:invalid_event, :occurred_at}}
    end
  end

  defp correlation_id(event) do
    case map_get(event, :correlation_id) do
      nil ->
        {:ok, Audit.correlation_id()}

      value
      when is_binary(value) and byte_size(value) > 0 and
             byte_size(value) <= @max_correlation_id_bytes ->
        {:ok, value}

      _ ->
        {:error, {:invalid_event, :correlation_id}}
    end
  end

  defp validate_known_fields(event) do
    allowed =
      MapSet.new([
        :schema_version,
        "schema_version",
        :event_id,
        "event_id",
        :cluster_id,
        "cluster_id",
        :cluster_seq,
        "cluster_seq",
        :kind,
        "kind",
        :occurred_at,
        "occurred_at",
        :correlation_id,
        "correlation_id",
        :payload,
        "payload",
        :sent,
        "sent"
      ])

    if Enum.all?(Map.keys(event), &MapSet.member?(allowed, &1)),
      do: :ok,
      else: {:error, {:invalid_event, :unknown_fields}}
  end

  defp validate_sequence(value) when is_integer(value) and value >= 0, do: :ok
  defp validate_sequence(_), do: {:error, :invalid_acknowledgement}

  defp validate_event_size(event, max_event_bytes) do
    case Jason.encode(event) do
      {:ok, encoded} when byte_size(encoded) <= max_event_bytes -> :ok
      {:ok, _encoded} -> {:error, :event_too_large}
      {:error, _} -> {:error, {:invalid_event, :schema}}
    end
  end

  defp validate_storage_size(encoded, max_storage_bytes)
       when byte_size(encoded) <= max_storage_bytes,
       do: :ok

  defp validate_storage_size(_encoded, _max_storage_bytes), do: {:error, :storage_full}

  # ── Helpers ──────────────────────────────────────────────────────────────────

  defp map_get(map, key, default \\ nil) do
    Map.get(map, key, Map.get(map, Atom.to_string(key), default))
  end

  defp find_event_by_id(_events, nil), do: :not_found

  defp find_event_by_id(events, event_id) do
    case Enum.find(events, &(&1.event_id == event_id)) do
      nil -> :not_found
      event -> {:ok, event}
    end
  end

  defp same_event_request?(existing, raw_event, cluster_id) do
    existing.cluster_id == cluster_id and
      (is_nil(map_get(raw_event, :kind)) or
         existing.kind == normalize_kind(map_get(raw_event, :kind))) and
      (is_nil(map_get(raw_event, :payload)) or
         existing.payload == normalize_and_redact!(map_get(raw_event, :payload)))
  end

  defp normalize_and_redact!(payload) do
    case normalize_and_redact(payload) do
      {:ok, normalized} -> normalized
      {:error, _} -> :invalid
    end
  end

  defp replace_event(events, old, replacement) do
    Enum.map(events, fn event ->
      if event.event_id == old.event_id, do: replacement, else: event
    end)
  end

  defp sorted_events(events), do: Enum.sort_by(events, &{&1.cluster_id, &1.cluster_seq})

  defp public_event(event), do: event

  defp disk_event(event) do
    %{
      "schema_version" => event.schema_version,
      "event_id" => event.event_id,
      "cluster_id" => event.cluster_id,
      "cluster_seq" => event.cluster_seq,
      "kind" => event.kind,
      "occurred_at" => event.occurred_at,
      "correlation_id" => event.correlation_id,
      "payload" => event.payload,
      "sent" => event.sent
    }
  end
end
