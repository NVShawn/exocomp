# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ClusterEventIngestor do
  @moduledoc """
  Serializes, deduplicates, and durably commits cluster events.

  An accepted event, its event-ID index, its sequence index, and the advanced
  contiguous cursor are one state transition. Persistence happens before the
  GenServer replies, so a successful acknowledgement always describes a
  committed event. Out-of-order events are retained, but the acknowledgement
  remains at the highest contiguous committed sequence.
  """

  use GenServer

  alias Exocomp.Coordinator.{ClusterEvent, ClusterIdentity, Error}

  @type option ::
          {:name, GenServer.name()}
          | {:store_path, Path.t() | nil}
          | {:persist_fn, (map() -> :ok | {:error, term()})}
          | {:schema_version, pos_integer()}
          | {:max_event_bytes, pos_integer()}

  @type result :: %{
          acknowledgement: non_neg_integer(),
          highest_contiguous_sequence: non_neg_integer(),
          duplicate?: boolean(),
          gap?: boolean(),
          sequence_status: :contiguous | :gap | :duplicate
        }

  @doc "Starts the serialized ingestion boundary."
  @spec start_link([option()]) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Validates, commits, and acknowledges one event for an authenticated cluster."
  @spec ingest(map(), ClusterIdentity.t() | map(), GenServer.server()) ::
          {:ok, result()} | {:error, Error.t()}
  def ingest(envelope, identity, server \\ __MODULE__) do
    GenServer.call(server, {:ingest, envelope, identity})
  end

  @doc "Returns the highest contiguous committed sequence for an identity."
  @spec acknowledgement(ClusterIdentity.t() | map(), GenServer.server()) ::
          non_neg_integer() | {:error, Error.t()}
  def acknowledgement(identity, server \\ __MODULE__) do
    case ClusterIdentity.new(identity) do
      {:ok, identity} -> GenServer.call(server, {:acknowledgement, key(identity)})
      {:error, _} = error -> error
    end
  end

  @doc "Returns committed events for an identity in sequence order."
  @spec events(ClusterIdentity.t() | map(), GenServer.server()) ::
          [map()] | {:error, Error.t()}
  def events(identity, server \\ __MODULE__) do
    case ClusterIdentity.new(identity) do
      {:ok, identity} -> GenServer.call(server, {:events, key(identity)})
      {:error, _} = error -> error
    end
  end

  @doc "Returns non-secret ingestion counters and storage configuration."
  @spec status(GenServer.server()) :: map()
  def status(server \\ __MODULE__), do: GenServer.call(server, :status)

  @impl true
  def init(opts) do
    path = Keyword.get(opts, :store_path)

    base_state = %{
      events: %{},
      sequence_events: %{},
      cursors: %{},
      store_path: path,
      schema_version: Keyword.get(opts, :schema_version, ClusterEvent.schema_version()),
      max_event_bytes: Keyword.get(opts, :max_event_bytes, 262_144),
      persist_fn: Keyword.get(opts, :persist_fn, &persist_snapshot(&1, path))
    }

    case load_snapshot(base_state) do
      {:ok, state} -> {:ok, state}
      {:error, error} -> {:stop, {:storage_unavailable, error}}
    end
  end

  @impl true
  def handle_call({:ingest, envelope, raw_identity}, _from, state) do
    with {:ok, identity} <- ClusterIdentity.new(raw_identity),
         {:ok, event} <-
           ClusterEvent.validate(envelope,
             schema_version: state.schema_version,
             max_event_bytes: state.max_event_bytes
           ),
         {:ok, result, new_state} <- accept(event, identity, state),
         :ok <- persist(state, new_state) do
      {:reply, {:ok, result}, new_state}
    else
      {:error, _} = error -> {:reply, error, state}
    end
  end

  def handle_call({:acknowledgement, identity_key}, _from, state) do
    {:reply, Map.get(state.cursors, identity_key, 0), state}
  end

  def handle_call({:events, identity_key}, _from, state) do
    events =
      state.events
      |> Enum.filter(fn {{org, cluster, _event_id}, _event} -> {org, cluster} == identity_key end)
      |> Enum.map(fn {_key, event} -> event end)
      |> Enum.sort_by(& &1.cluster_seq)

    {:reply, events, state}
  end

  def handle_call(:status, _from, state) do
    {:reply,
     %{
       event_count: map_size(state.events),
       cluster_count: map_size(state.cursors),
       store_path: state.store_path
     }, state}
  end

  defp accept(event, identity, state) do
    identity_key = key(identity)
    event_key = {identity.organization_id, identity.cluster_id, event.event_id}
    sequence_key = {identity.organization_id, identity.cluster_id, event.cluster_seq}
    cursor = Map.get(state.cursors, identity_key, 0)

    case Map.fetch(state.events, event_key) do
      {:ok, existing} ->
        if same_event?(existing, event) do
          {:ok, duplicate_result(identity_key, state), state}
        else
          {:error,
           Error.new(:event_id_conflict, "event_id was already committed with different data")}
        end

      :error ->
        case Map.fetch(state.sequence_events, sequence_key) do
          {:ok, existing_event_id} when existing_event_id != event.event_id ->
            {:error,
             Error.new(
               :sequence_conflict,
               "cluster sequence was already committed with another event"
             )}

          _ ->
            new_state =
              state
              |> put_event(identity, event)
              |> advance_cursor(identity_key)

            new_cursor = Map.get(new_state.cursors, identity_key, 0)
            gap? = gap?(identity_key, new_state)

            result = %{
              acknowledgement: new_cursor,
              highest_contiguous_sequence: new_cursor,
              duplicate?: false,
              gap?: gap?,
              sequence_status: if(event.cluster_seq > cursor + 1, do: :gap, else: :contiguous)
            }

            {:ok, result, new_state}
        end
    end
  end

  defp same_event?(existing, event) do
    existing.schema_version == event.schema_version and
      existing.cluster_seq == event.cluster_seq and
      existing.kind == event.kind and
      existing.occurred_at == event.occurred_at and
      existing.correlation_id == event.correlation_id and
      existing.payload == event.payload
  end

  defp duplicate_result(identity_key, state) do
    cursor = Map.get(state.cursors, identity_key, 0)

    %{
      acknowledgement: cursor,
      highest_contiguous_sequence: cursor,
      duplicate?: true,
      gap?: gap?(identity_key, state),
      sequence_status: :duplicate
    }
  end

  defp gap?(identity_key, state) do
    cursor = Map.get(state.cursors, identity_key, 0)

    Enum.any?(state.sequence_events, fn {{organization_id, cluster_id, sequence}, _event_id} ->
      {organization_id, cluster_id} == identity_key and sequence > cursor
    end)
  end

  defp put_event(state, identity, event) do
    event_key = {identity.organization_id, identity.cluster_id, event.event_id}
    sequence_key = {identity.organization_id, identity.cluster_id, event.cluster_seq}

    %{
      state
      | events: Map.put(state.events, event_key, event),
        sequence_events: Map.put(state.sequence_events, sequence_key, event.event_id)
    }
  end

  defp advance_cursor(state, identity_key) do
    cursor = Map.get(state.cursors, identity_key, 0)
    next_cursor = advance(cursor, identity_key, state.sequence_events)
    %{state | cursors: Map.put(state.cursors, identity_key, next_cursor)}
  end

  defp advance(cursor, identity_key, sequence_events) do
    sequence_key = Tuple.insert_at(identity_key, tuple_size(identity_key), cursor + 1)

    if Map.has_key?(sequence_events, sequence_key) do
      advance(cursor + 1, identity_key, sequence_events)
    else
      cursor
    end
  end

  defp key(%ClusterIdentity{organization_id: organization_id, cluster_id: cluster_id}),
    do: {organization_id, cluster_id}

  defp persist(state, new_state) do
    if state.events == new_state.events and state.cursors == new_state.cursors do
      :ok
    else
      try do
        new_state.persist_fn.(snapshot(new_state))
      rescue
        exception -> {:error, Error.new(:event_persistence_failed, Exception.message(exception))}
      catch
        kind, reason ->
          {:error,
           Error.new(:event_persistence_failed, "event persistence failed", %{
             kind: kind,
             reason: reason
           })}
      end
      |> normalize_persist_result()
    end
  end

  defp normalize_persist_result(:ok), do: :ok

  defp normalize_persist_result({:error, %Error{} = error}), do: {:error, error}

  defp normalize_persist_result({:error, reason}),
    do:
      {:error,
       Error.new(:event_persistence_failed, "event persistence failed", %{reason: reason})}

  defp normalize_persist_result(_other),
    do: {:error, Error.new(:event_persistence_failed, "event persistence failed")}

  defp snapshot(state) do
    %{
      version: 1,
      events: state.events,
      sequence_events: state.sequence_events,
      cursors: state.cursors
    }
  end

  defp persist_snapshot(_snapshot, nil), do: :ok

  defp persist_snapshot(snapshot, path) do
    temp_path = path <> ".tmp-#{System.unique_integer([:positive])}"

    with :ok <- File.mkdir_p(Path.dirname(path)),
         {:ok, io} <- File.open(temp_path, [:write, :binary]),
         :ok <- IO.binwrite(io, :erlang.term_to_binary(snapshot)),
         :ok <- :file.sync(io),
         :ok <- File.close(io),
         :ok <- File.rename(temp_path, path) do
      :ok
    else
      {:error, _reason} = error ->
        _ = File.rm(temp_path)
        error
    end
  end

  defp load_snapshot(%{store_path: nil} = state), do: {:ok, state}

  defp load_snapshot(%{store_path: path} = state) do
    case File.read(path) do
      {:ok, binary} ->
        try do
          case :erlang.binary_to_term(binary, [:safe]) do
            %{version: 1, events: events, sequence_events: sequence_events, cursors: cursors}
            when is_map(events) and is_map(sequence_events) and is_map(cursors) ->
              {:ok, %{state | events: events, sequence_events: sequence_events, cursors: cursors}}

            _other ->
              {:error, :invalid_snapshot}
          end
        rescue
          _exception -> {:error, :invalid_snapshot}
        end

      {:error, :enoent} ->
        {:ok, state}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
