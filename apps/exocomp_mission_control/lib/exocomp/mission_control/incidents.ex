# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Incidents do
  @moduledoc """
  Atomic incident reduction and correlated timeline storage.

  The current repository has no database adapter yet, so this context exposes
  the same organization-scoped record boundary through a GenServer. A single
  server call validates, fingerprints, inserts the event, and updates the
  materialized incident. The unique fingerprint map is therefore updated
  atomically even when many callers open the same incident concurrently.
  """

  use GenServer

  alias Exocomp.MissionControl.Incidents.{Fingerprint, Incident, IncidentEvent}

  @type evidence :: map()

  defstruct incidents: %{},
            events: %{},
            fingerprints: %{},
            sequence: 0,
            now_fn: nil,
            incident_id_fn: nil,
            event_id_fn: nil

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Records evidence, creating or updating the one incident for its fingerprint."
  @spec record(evidence(), GenServer.server()) :: {:ok, Incident.t()} | {:error, term()}
  def record(evidence, server \\ __MODULE__) when is_map(evidence) do
    GenServer.call(server, {:record, evidence})
  end

  @doc "Alias for `record/2`, named for event-ingestion callers."
  @spec ingest(evidence(), GenServer.server()) :: {:ok, Incident.t()} | {:error, term()}
  def ingest(evidence, server \\ __MODULE__), do: record(evidence, server)

  @doc "Alias for `record/2`, named for the initial incident transition."
  @spec open(evidence(), GenServer.server()) :: {:ok, Incident.t()} | {:error, term()}
  def open(evidence, server \\ __MODULE__), do: record(evidence, server)

  @doc "Alias for `record/2`, named for database-backed implementations."
  @spec upsert(evidence(), GenServer.server()) :: {:ok, Incident.t()} | {:error, term()}
  def upsert(evidence, server \\ __MODULE__), do: record(evidence, server)

  @doc "Alias for `record/2` for callers that receive one external event at a time."
  @spec record_event(evidence(), GenServer.server()) :: {:ok, Incident.t()} | {:error, term()}
  def record_event(evidence, server \\ __MODULE__), do: record(evidence, server)

  @doc "Returns an incident by ID, optionally scoped to an organization."
  @spec get(String.t(), GenServer.server()) :: {:ok, Incident.t()} | {:error, :not_found}
  def get(incident_id, server \\ __MODULE__)

  def get(organization_id, incident_id)
      when is_binary(organization_id) and is_binary(incident_id),
      do: get(organization_id, incident_id, __MODULE__)

  def get(incident_id, server) when is_binary(incident_id) do
    GenServer.call(server, {:get, incident_id})
  end

  @spec get(String.t(), String.t(), GenServer.server()) ::
          {:ok, Incident.t()} | {:error, :not_found | :organization_mismatch}
  def get(organization_id, incident_id, server)
      when is_binary(organization_id) and is_binary(incident_id) do
    case get(incident_id, server) do
      {:ok, %{organization_id: ^organization_id} = incident} -> {:ok, incident}
      {:ok, _incident} -> {:error, :organization_mismatch}
      error -> error
    end
  end

  @doc "Returns all incidents belonging to `organization_id`, oldest first."
  @spec list(String.t()) :: [Incident.t()]
  def list(organization_id) when is_binary(organization_id), do: list(organization_id, __MODULE__)

  @spec list(GenServer.server()) :: [Incident.t()]
  def list(server) when is_pid(server) or is_atom(server), do: GenServer.call(server, :list)

  @spec list() :: [Incident.t()]
  def list, do: list(__MODULE__)

  @spec list(String.t(), GenServer.server()) :: [Incident.t()]
  def list(organization_id, server) when is_binary(organization_id) do
    GenServer.call(server, {:list, organization_id})
  end

  @doc "Returns an incident by its organization-scoped fingerprint."
  @spec get_by_fingerprint(String.t(), GenServer.server()) ::
          {:ok, Incident.t()} | {:error, :not_found}
  def get_by_fingerprint(fingerprint, server \\ __MODULE__)

  def get_by_fingerprint(organization_id, fingerprint)
      when is_binary(organization_id) and is_binary(fingerprint),
      do: get_by_fingerprint(organization_id, fingerprint, __MODULE__)

  def get_by_fingerprint(fingerprint, server) when is_binary(fingerprint) do
    GenServer.call(server, {:get_by_fingerprint, fingerprint})
  end

  @spec get_by_fingerprint(String.t(), String.t(), GenServer.server()) ::
          {:ok, Incident.t()} | {:error, :not_found | :organization_mismatch}
  def get_by_fingerprint(organization_id, fingerprint, server)
      when is_binary(organization_id) and is_binary(fingerprint) do
    case get_by_fingerprint(fingerprint, server) do
      {:ok, %{organization_id: ^organization_id} = incident} -> {:ok, incident}
      {:ok, _incident} -> {:error, :organization_mismatch}
      error -> error
    end
  end

  @doc "Returns a timeline in occurred-at order, with ingestion sequence as tie-breaker."
  @spec events(String.t(), GenServer.server()) :: [IncidentEvent.t()]
  def events(incident_id, server \\ __MODULE__)

  def events(organization_id, incident_id)
      when is_binary(organization_id) and is_binary(incident_id),
      do: events(organization_id, incident_id, __MODULE__)

  def events(incident_id, server) when is_binary(incident_id) do
    GenServer.call(server, {:events, incident_id})
  end

  @spec events(String.t(), String.t(), GenServer.server()) ::
          {:ok, [IncidentEvent.t()]} | {:error, :not_found | :organization_mismatch}
  def events(organization_id, incident_id, server)
      when is_binary(organization_id) and is_binary(incident_id) do
    case get(organization_id, incident_id, server) do
      {:ok, _incident} -> {:ok, events(incident_id, server)}
      error -> error
    end
  end

  @doc "Drops all records in the named store; intended for isolated tests."
  @spec reset(GenServer.server()) :: :ok
  def reset(server \\ __MODULE__), do: GenServer.call(server, :reset)

  @impl true
  def init(opts) do
    {:ok,
     %__MODULE__{
       now_fn: Keyword.get(opts, :now_fn, &DateTime.utc_now/0),
       incident_id_fn: Keyword.get(opts, :incident_id_fn, &Incident.generate_id/0),
       event_id_fn: Keyword.get(opts, :event_id_fn, &IncidentEvent.generate_id/0)
     }}
  end

  @impl true
  def handle_call({:record, evidence}, _from, state) do
    case normalize_evidence(evidence, state.now_fn.()) do
      {:ok, normalized} ->
        {incident, event, updated_state} = reduce_evidence(normalized, state)
        {:reply, {:ok, incident}, put_event(updated_state, incident, event)}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:get, incident_id}, _from, state) do
    {:reply, Map.fetch(state.incidents, incident_id), state}
  end

  def handle_call({:get_by_fingerprint, fingerprint}, _from, state) do
    reply =
      case Map.get(state.fingerprints, fingerprint) do
        nil -> {:error, :not_found}
        incident_id -> Map.fetch(state.incidents, incident_id)
      end

    {:reply, reply, state}
  end

  def handle_call({:list, organization_id}, _from, state) do
    incidents =
      state.incidents
      |> Map.values()
      |> Enum.filter(&(&1.organization_id == organization_id))
      |> sort_incidents()

    {:reply, incidents, state}
  end

  def handle_call(:list, _from, state),
    do: {:reply, sort_incidents(Map.values(state.incidents)), state}

  def handle_call({:events, incident_id}, _from, state) do
    {:reply, state.events |> Map.get(incident_id, []) |> sort_events(), state}
  end

  def handle_call(:reset, _from, _state) do
    {:reply, :ok,
     %__MODULE__{
       now_fn: &DateTime.utc_now/0,
       incident_id_fn: &Incident.generate_id/0,
       event_id_fn: &IncidentEvent.generate_id/0
     }}
  end

  defp reduce_evidence(evidence, state) do
    fingerprint = Fingerprint.build(evidence)
    incident_id = Map.get(state.fingerprints, fingerprint)
    existing = Map.get(state.incidents, incident_id)
    sequence = state.sequence + 1

    incident =
      case existing do
        nil ->
          %Incident{
            id: state.incident_id_fn.(),
            organization_id: evidence.organization_id,
            fingerprint: fingerprint,
            cluster_id: evidence.cluster_id,
            alert_type: evidence.alert_type,
            source: evidence.source,
            target_type: evidence.target_type,
            target_identity: evidence.target_identity,
            correlation_id: evidence.correlation_id || Incident.generate_correlation_id(),
            opened_at: evidence.occurred_at,
            updated_at: evidence.occurred_at
          }

        incident ->
          incident
      end

    event_type =
      if existing != nil and not evidence.explicit_event_type? do
        :updated
      else
        evidence.event_type
      end

    event = %IncidentEvent{
      id: state.event_id_fn.(),
      incident_id: incident.id,
      organization_id: evidence.organization_id,
      fingerprint: fingerprint,
      event_type: event_type,
      kind: event_type,
      occurred_at: evidence.occurred_at,
      received_at: evidence.received_at,
      correlation_id: evidence.correlation_id || incident.correlation_id,
      sequence: sequence,
      payload: evidence.payload
    }

    timeline = [event | Map.get(state.events, incident.id, [])] |> sort_events()
    {replay(incident, timeline), event, %{state | sequence: sequence}}
  end

  defp put_event(state, incident, event) do
    %{
      state
      | incidents: Map.put(state.incidents, incident.id, incident),
        events: Map.update(state.events, incident.id, [event], &[event | &1]),
        fingerprints: Map.put(state.fingerprints, incident.fingerprint, incident.id)
    }
  end

  defp replay(incident, timeline) do
    first = hd(timeline)
    last = List.last(timeline)

    state =
      Enum.reduce(timeline, :open, fn event, current -> transition(current, event.event_type) end)

    acknowledged_at =
      timeline
      |> Enum.filter(&(&1.event_type == :acknowledged))
      |> List.last()
      |> case do
        nil -> incident.acknowledged_at
        event -> event.occurred_at
      end

    resolved_at =
      if state == :resolved do
        timeline
        |> Enum.filter(&(&1.event_type == :resolved))
        |> List.last()
        |> then(& &1.occurred_at)
      end

    %{
      incident
      | opened_at: min_datetime(incident.opened_at || first.occurred_at, first.occurred_at),
        updated_at: last.occurred_at,
        state: state,
        acknowledged_at: acknowledged_at,
        resolved_at: resolved_at,
        event_count: length(timeline)
    }
  end

  defp transition(:acknowledged, :opened), do: :acknowledged
  defp transition(:acknowledged, :updated), do: :acknowledged
  defp transition(_state, :opened), do: :open
  defp transition(_state, :updated), do: :open
  defp transition(_state, :acknowledged), do: :acknowledged
  defp transition(_state, :resolved), do: :resolved

  defp normalize_evidence(evidence, received_at) do
    with :ok <- validate_required(evidence),
         {:ok, occurred_at} <- parse_timestamp(fetch(evidence, :occurred_at, received_at)),
         {:ok, event_type, explicit_event_type?} <- normalize_event_type(evidence),
         {:ok, payload} <-
           normalize_payload(fetch(evidence, :payload, fetch(evidence, :evidence, %{}))) do
      {:ok,
       %{
         organization_id: fetch(evidence, :organization_id),
         cluster_id: fetch(evidence, :cluster_id),
         alert_type: fetch(evidence, :alert_type),
         source: fetch(evidence, :source),
         target_type: fetch(evidence, :target_type),
         target_identity: fetch(evidence, :target_identity),
         occurred_at: occurred_at,
         received_at: received_at,
         correlation_id: fetch(evidence, :correlation_id),
         event_type: event_type,
         explicit_event_type?: explicit_event_type?,
         payload: payload
       }}
    end
  end

  defp validate_required(evidence) do
    fields = [:organization_id, :cluster_id, :alert_type, :source, :target_type, :target_identity]

    case Enum.find(fields, fn field -> not nonempty_binary?(fetch(evidence, field)) end) do
      nil -> :ok
      field -> {:error, {:invalid_field, field}}
    end
  end

  defp normalize_event_type(evidence) do
    value =
      fetch(evidence, :event_type, fetch(evidence, :kind, nil)) || fetch(evidence, :state, nil)

    case value do
      nil -> {:ok, :opened, false}
      :open -> {:ok, :opened, true}
      :acknowledged -> {:ok, :acknowledged, true}
      :resolved -> {:ok, :resolved, true}
      :opened -> {:ok, :opened, true}
      :updated -> {:ok, :updated, true}
      "alert.opened" -> {:ok, :opened, true}
      "alert.updated" -> {:ok, :updated, true}
      "alert.resolved" -> {:ok, :resolved, true}
      "opened" -> {:ok, :opened, true}
      "updated" -> {:ok, :updated, true}
      "acknowledged" -> {:ok, :acknowledged, true}
      "resolved" -> {:ok, :resolved, true}
      _ -> {:error, {:invalid_field, :event_type}}
    end
  end

  defp normalize_payload(value) when is_map(value), do: {:ok, value}
  defp normalize_payload(nil), do: {:ok, %{}}
  defp normalize_payload(_value), do: {:error, {:invalid_field, :payload}}

  defp parse_timestamp(%DateTime{} = value), do: {:ok, value}

  defp parse_timestamp(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, parsed, _offset} -> {:ok, parsed}
      {:error, _reason} -> {:error, {:invalid_field, :occurred_at}}
    end
  end

  defp parse_timestamp(_value), do: {:error, {:invalid_field, :occurred_at}}

  defp fetch(map, key, default \\ nil) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, Atom.to_string(key), default)
    end
  end

  defp nonempty_binary?(value), do: is_binary(value) and byte_size(value) > 0

  defp sort_events(events),
    do: Enum.sort_by(events, &{DateTime.to_unix(&1.occurred_at, :microsecond), &1.sequence})

  defp sort_incidents(incidents),
    do: Enum.sort_by(incidents, &{DateTime.to_unix(&1.opened_at, :microsecond), &1.id})

  defp min_datetime(nil, value), do: value

  defp min_datetime(left, right),
    do: if(DateTime.compare(left, right) == :gt, do: right, else: left)
end
