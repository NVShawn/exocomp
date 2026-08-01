# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.ClusterEventIngestor do
  @moduledoc """
  Transactionally commits, deduplicates, and acknowledges cluster events.

  Each successful transition contains the event, its identity-scoped event-ID
  index, its per-cluster sequence index, and the highest contiguous cursor.
  The complete snapshot is durably staged before the acknowledgement is
  returned, so an acknowledgement never describes an uncommitted event.
  """

  use GenServer

  alias Exocomp.MissionControl.{ClusterEvent, EventIngestionError}

  @type identity :: %{
          required(:organization_id) => String.t(),
          required(:cluster_id) => String.t(),
          optional(:spiffe_id) => String.t()
        }

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

  @doc "Validates, commits, and acknowledges an event from an authenticated identity."
  @spec ingest(map(), identity(), GenServer.server()) ::
          {:ok, result()} | {:error, EventIngestionError.t()}
  def ingest(envelope, identity, server \\ __MODULE__) do
    GenServer.call(server, {:ingest, envelope, identity})
  end

  @doc "Returns the highest contiguous committed sequence for an identity."
  @spec acknowledgement(identity(), GenServer.server()) ::
          non_neg_integer() | {:error, EventIngestionError.t()}
  def acknowledgement(identity, server \\ __MODULE__) do
    with {:ok, identity} <- normalize_identity(identity) do
      GenServer.call(server, {:acknowledgement, identity_key(identity)})
    end
  end

  @doc "Returns committed events for an identity in sequence order."
  @spec events(identity(), GenServer.server()) ::
          [ClusterEvent.t()] | {:error, EventIngestionError.t()}
  def events(identity, server \\ __MODULE__) do
    with {:ok, identity} <- normalize_identity(identity) do
      GenServer.call(server, {:events, identity_key(identity)})
    end
  end

  @doc "Returns non-secret ingestion counters and store configuration."
  @spec status(GenServer.server()) :: map()
  def status(server \\ __MODULE__), do: GenServer.call(server, :status)

  @impl true
  def init(opts) do
    path = Keyword.get(opts, :store_path)

    state = %{
      events: %{},
      sequence_events: %{},
      cursors: %{},
      store_path: path,
      schema_version: Keyword.get(opts, :schema_version, ClusterEvent.schema_version()),
      max_event_bytes: Keyword.get(opts, :max_event_bytes, 262_144),
      persist_fn: Keyword.get(opts, :persist_fn, &persist_snapshot(&1, path))
    }

    case load_snapshot(state) do
      {:ok, restored} -> {:ok, restored}
      {:error, reason} -> {:stop, {:storage_unavailable, reason}}
    end
  end

  @impl true
  def handle_call({:ingest, envelope, raw_identity}, _from, state) do
    with {:ok, identity} <- normalize_identity(raw_identity),
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

  def handle_call({:acknowledgement, key}, _from, state),
    do: {:reply, Map.get(state.cursors, key, 0), state}

  def handle_call({:events, key}, _from, state) do
    events =
      state.events
      |> Enum.filter(fn {{organization_id, cluster_id, _event_id}, _event} ->
        {organization_id, cluster_id} == key
      end)
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
    identity_key = identity_key(identity)
    event_key = {identity.organization_id, identity.cluster_id, event.event_id}
    sequence_key = {identity.organization_id, identity.cluster_id, event.cluster_seq}
    cursor = Map.get(state.cursors, identity_key, 0)

    case Map.fetch(state.events, event_key) do
      {:ok, existing} ->
        if same_event?(existing, event) do
          {:ok, duplicate_result(identity_key, state), state}
        else
          error(:event_id_conflict, "event_id was already committed with different data")
        end

      :error ->
        case Map.fetch(state.sequence_events, sequence_key) do
          {:ok, existing_event_id} when existing_event_id != event.event_id ->
            error(:sequence_conflict, "cluster sequence was already committed with another event")

          _other ->
            new_state = state |> put_event(identity, event) |> advance_cursor(identity_key)
            acknowledgement = Map.get(new_state.cursors, identity_key, 0)

            {:ok,
             %{
               acknowledgement: acknowledgement,
               highest_contiguous_sequence: acknowledgement,
               duplicate?: false,
               gap?: gap?(identity_key, new_state),
               sequence_status: if(event.cluster_seq > cursor + 1, do: :gap, else: :contiguous)
             }, new_state}
        end
    end
  end

  defp normalize_identity(identity) when is_map(identity) do
    organization_id = Map.get(identity, :organization_id, Map.get(identity, "organization_id"))
    cluster_id = Map.get(identity, :cluster_id, Map.get(identity, "cluster_id"))

    with :ok <- valid_identity_component(organization_id, :organization_id),
         :ok <- valid_identity_component(cluster_id, :cluster_id) do
      {:ok, %{organization_id: organization_id, cluster_id: cluster_id}}
    end
  end

  defp normalize_identity(_identity),
    do: error(:invalid_cluster_identity, "cluster identity must be a map")

  defp valid_identity_component(value, field)
       when is_binary(value) and byte_size(value) in 1..256 do
    if value == String.trim(value) do
      :ok
    else
      error(:invalid_cluster_identity, "#{field} must be a bounded non-empty string")
    end
  end

  defp valid_identity_component(_value, field),
    do: error(:invalid_cluster_identity, "#{field} must be a bounded non-empty string")

  defp same_event?(existing, event) do
    existing.schema_version == event.schema_version and
      existing.cluster_seq == event.cluster_seq and
      existing.kind == event.kind and
      existing.occurred_at == event.occurred_at and
      existing.correlation_id == event.correlation_id and
      existing.payload == event.payload
  end

  defp duplicate_result(identity_key, state) do
    acknowledgement = Map.get(state.cursors, identity_key, 0)

    %{
      acknowledgement: acknowledgement,
      highest_contiguous_sequence: acknowledgement,
      duplicate?: true,
      gap?: gap?(identity_key, state),
      sequence_status: :duplicate
    }
  end

  defp gap?(identity_key, state) do
    acknowledgement = Map.get(state.cursors, identity_key, 0)

    Enum.any?(state.sequence_events, fn {{organization_id, cluster_id, sequence}, _event_id} ->
      {organization_id, cluster_id} == identity_key and sequence > acknowledgement
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

  defp identity_key(%{organization_id: organization_id, cluster_id: cluster_id}),
    do: {organization_id, cluster_id}

  defp persist(state, new_state) do
    if state.events == new_state.events and state.cursors == new_state.cursors do
      :ok
    else
      try do
        new_state.persist_fn.(snapshot(new_state))
      rescue
        exception -> error(:event_persistence_failed, Exception.message(exception))
      catch
        kind, reason ->
          error(:event_persistence_failed, "event persistence failed", %{
            kind: kind,
            reason: reason
          })
      end
      |> normalize_persist_result()
    end
  end

  defp normalize_persist_result(:ok), do: :ok
  defp normalize_persist_result({:error, %EventIngestionError{} = error}), do: {:error, error}

  defp normalize_persist_result({:error, reason}),
    do: error(:event_persistence_failed, "event persistence failed", %{reason: reason})

  defp normalize_persist_result(_result),
    do: error(:event_persistence_failed, "event persistence failed")

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
    temporary_path = path <> ".tmp-#{System.unique_integer([:positive])}"

    with :ok <- File.mkdir_p(Path.dirname(path)),
         {:ok, io} <- File.open(temporary_path, [:write, :binary]),
         :ok <- IO.binwrite(io, :erlang.term_to_binary(snapshot)),
         :ok <- :file.sync(io),
         :ok <- File.close(io),
         :ok <- File.rename(temporary_path, path) do
      :ok
    else
      {:error, _reason} = error ->
        _ = File.rm(temporary_path)
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

  defp error(code, message, details \\ %{}),
    do: {:error, EventIngestionError.new(code, message, details)}
end
