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

  alias Exocomp.MissionControl.Incidents.{Fingerprint, Grouping, Incident, IncidentEvent}

  @type evidence :: map()

  defstruct incidents: %{},
            events: %{},
            fingerprints: %{},
            sequence: 0,
            now_fn: nil,
            incident_id_fn: nil,
            event_id_fn: nil,
            pubsub: nil

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

  @doc "Returns active incidents in an organization, oldest first."
  @spec list_open(String.t(), GenServer.server()) :: [Incident.t()]
  def list_open(organization_id, server \\ __MODULE__) when is_binary(organization_id) do
    GenServer.call(server, {:list_open, organization_id})
  end

  @doc "Alias for `list_open/2` for callers using the state name."
  @spec open_incidents(String.t(), GenServer.server()) :: [Incident.t()]
  def open_incidents(organization_id, server \\ __MODULE__),
    do: list_open(organization_id, server)

  @doc "Returns incidents updated at or after a timestamp, oldest first."
  @spec recent(String.t(), DateTime.t() | non_neg_integer(), GenServer.server()) ::
          [Incident.t()]
  def recent(organization_id, since_or_seconds, server \\ __MODULE__)

  def recent(organization_id, since_or_seconds, server) when is_binary(organization_id) do
    GenServer.call(server, {:recent, organization_id, since_or_seconds})
  end

  @doc "Alias for `recent/3` for callers using list terminology."
  @spec list_recent(String.t(), DateTime.t() | non_neg_integer(), GenServer.server()) ::
          [Incident.t()]
  def list_recent(organization_id, since_or_seconds, server \\ __MODULE__),
    do: recent(organization_id, since_or_seconds, server)

  @doc "Returns active or recent incidents related to a target incident."
  @spec related(String.t(), String.t() | Incident.t(), keyword(), GenServer.server()) ::
          {:ok, [Incident.t()]} | {:error, :not_found | :organization_mismatch}
  def related(organization_id, %Incident{} = incident)
      when is_binary(organization_id) do
    related(organization_id, incident, [], __MODULE__)
  end

  def related(organization_id, incident_id)
      when is_binary(organization_id) and is_binary(incident_id) do
    related(organization_id, incident_id, [], __MODULE__)
  end

  def related(organization_id, %Incident{} = incident, server)
      when is_binary(organization_id) and (is_atom(server) or is_pid(server)) do
    related(organization_id, incident, [], server)
  end

  def related(organization_id, incident_id, server)
      when is_binary(organization_id) and is_binary(incident_id) and
             (is_atom(server) or is_pid(server)) do
    related(organization_id, incident_id, [], server)
  end

  def related(organization_id, %Incident{} = incident, opts)
      when is_binary(organization_id) and is_list(opts) do
    related(organization_id, incident, opts, __MODULE__)
  end

  def related(organization_id, incident_id, opts)
      when is_binary(organization_id) and is_binary(incident_id) and is_list(opts) do
    related(organization_id, incident_id, opts, __MODULE__)
  end

  def related(organization_id, %Incident{} = incident, opts, server)
      when is_binary(organization_id) and is_list(opts) do
    case incident.organization_id do
      ^organization_id -> {:ok, related_for(organization_id, incident, opts, server)}
      _other -> {:error, :organization_mismatch}
    end
  end

  def related(organization_id, incident_id, opts, server)
      when is_binary(organization_id) and is_binary(incident_id) and is_list(opts) do
    case get(organization_id, incident_id, server) do
      {:ok, incident} ->
        {:ok, related_for(organization_id, incident, opts, server)}

      error ->
        error
    end
  end

  @doc "Alias for `related/4` for database-backed query callers."
  @spec related_incidents(String.t(), String.t(), keyword(), GenServer.server()) ::
          {:ok, [Incident.t()]} | {:error, :not_found | :organization_mismatch}
  def related_incidents(organization_id, incident_id, opts \\ [], server \\ __MODULE__),
    do: related(organization_id, incident_id, opts, server)

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

  @doc """
  Acknowledges an incident by an operator.

  Requires operator_role to be :operator or :admin (viewers are denied).
  Records the operator subject, organization, timestamp, and correlation ID.
  """
  @spec acknowledge(
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          atom(),
          GenServer.server()
        ) ::
          {:ok, Incident.t()}
          | {:error, :not_found | :organization_mismatch | :access_denied | :invalid_state}
  def acknowledge(
        organization_id,
        incident_id,
        operator_subject,
        operator_org,
        operator_role,
        server \\ __MODULE__
      )
      when is_binary(organization_id) and is_binary(incident_id) and is_binary(operator_subject) and
             is_binary(operator_org) and is_atom(operator_role) do
    GenServer.call(
      server,
      {:acknowledge, organization_id, incident_id, operator_subject, operator_org, operator_role}
    )
  end

  @doc """
  Assigns an incident to an operator.

  Requires operator_role to be :operator or :admin.
  """
  @spec assign(
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          atom(),
          GenServer.server()
        ) ::
          {:ok, Incident.t()} | {:error, :not_found | :organization_mismatch | :access_denied}
  def assign(
        organization_id,
        incident_id,
        assigned_to,
        operator_subject,
        operator_org,
        operator_role,
        server \\ __MODULE__
      )
      when is_binary(organization_id) and is_binary(incident_id) and is_binary(assigned_to) and
             is_binary(operator_subject) and is_binary(operator_org) and is_atom(operator_role) do
    GenServer.call(
      server,
      {:assign, organization_id, incident_id, assigned_to, operator_subject, operator_org,
       operator_role}
    )
  end

  @doc """
  Unassigns an incident from its current assignee.

  Requires operator_role to be :operator or :admin.
  """
  @spec unassign(
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          atom(),
          GenServer.server()
        ) ::
          {:ok, Incident.t()} | {:error, :not_found | :organization_mismatch | :access_denied}
  def unassign(
        organization_id,
        incident_id,
        operator_subject,
        operator_org,
        operator_role,
        server \\ __MODULE__
      )
      when is_binary(organization_id) and is_binary(incident_id) and is_binary(operator_subject) and
             is_binary(operator_org) and is_atom(operator_role) do
    GenServer.call(
      server,
      {:unassign, organization_id, incident_id, operator_subject, operator_org, operator_role}
    )
  end

  @doc """
  Snoozes an incident until the given time.

  Requires operator_role to be :operator or :admin.
  """
  @spec snooze(
          String.t(),
          String.t(),
          DateTime.t(),
          String.t(),
          String.t(),
          atom(),
          GenServer.server()
        ) ::
          {:ok, Incident.t()}
          | {:error, :not_found | :organization_mismatch | :access_denied | :invalid_snooze_time}
  def snooze(
        organization_id,
        incident_id,
        snooze_until,
        operator_subject,
        operator_org,
        operator_role,
        server \\ __MODULE__
      )
      when is_binary(organization_id) and is_binary(incident_id) and is_atom(operator_role) do
    GenServer.call(
      server,
      {:snooze, organization_id, incident_id, snooze_until, operator_subject, operator_org,
       operator_role}
    )
  end

  @doc """
  Unsnozes an incident.

  Requires operator_role to be :operator or :admin.
  """
  @spec unsnooze(
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          atom(),
          GenServer.server()
        ) ::
          {:ok, Incident.t()} | {:error, :not_found | :organization_mismatch | :access_denied}
  def unsnooze(
        organization_id,
        incident_id,
        operator_subject,
        operator_org,
        operator_role,
        server \\ __MODULE__
      )
      when is_binary(organization_id) and is_binary(incident_id) and is_binary(operator_subject) and
             is_binary(operator_org) and is_atom(operator_role) do
    GenServer.call(
      server,
      {:unsnooze, organization_id, incident_id, operator_subject, operator_org, operator_role}
    )
  end

  @doc """
  Manually resolves an incident with a required reason.

  Requires operator_role to be :operator or :admin.
  New unhealthy evidence will reopen the incident.
  """
  @spec resolve(
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          atom(),
          GenServer.server()
        ) ::
          {:ok, Incident.t()}
          | {:error, :not_found | :organization_mismatch | :access_denied | :missing_reason}
  def resolve(
        organization_id,
        incident_id,
        reason,
        operator_subject,
        operator_org,
        operator_role,
        server \\ __MODULE__
      )
      when is_binary(organization_id) and is_binary(incident_id) and is_binary(reason) and
             is_binary(operator_subject) and is_binary(operator_org) and is_atom(operator_role) do
    if String.trim(reason) == "" do
      {:error, :missing_reason}
    else
      GenServer.call(
        server,
        {:resolve, organization_id, incident_id, reason, operator_subject, operator_org,
         operator_role}
      )
    end
  end

  @impl true
  def init(opts) do
    {:ok,
     %__MODULE__{
       now_fn: Keyword.get(opts, :now_fn, &DateTime.utc_now/0),
       incident_id_fn: Keyword.get(opts, :incident_id_fn, &Incident.generate_id/0),
       event_id_fn: Keyword.get(opts, :event_id_fn, &IncidentEvent.generate_id/0),
       pubsub: Keyword.get(opts, :pubsub)
     }}
  end

  @impl true
  def handle_call({:record, evidence}, _from, state) do
    case normalize_evidence(evidence, state.now_fn.()) do
      {:ok, normalized} ->
        {incident, event, updated_state} = reduce_evidence(normalized, state)
        new_state = put_event(updated_state, incident, event)
        {:reply, {:ok, incident}, broadcast(new_state, incident)}

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

  def handle_call({:list_open, organization_id}, _from, state) do
    incidents =
      state.incidents
      |> Map.values()
      |> Enum.filter(fn incident ->
        incident.organization_id == organization_id and active?(incident)
      end)
      |> sort_incidents()

    {:reply, incidents, state}
  end

  def handle_call({:recent, organization_id, since_or_seconds}, _from, state) do
    reply = recent_incidents(state, organization_id, since_or_seconds)
    {:reply, reply, state}
  end

  def handle_call(:list, _from, state),
    do: {:reply, sort_incidents(Map.values(state.incidents)), state}

  def handle_call({:events, incident_id}, _from, state) do
    {:reply, state.events |> Map.get(incident_id, []) |> sort_events(), state}
  end

  def handle_call(:reset, _from, state) do
    {:reply, :ok,
     %__MODULE__{
       now_fn: &DateTime.utc_now/0,
       incident_id_fn: &Incident.generate_id/0,
       event_id_fn: &IncidentEvent.generate_id/0,
       pubsub: state.pubsub
     }}
  end

  def handle_call(
        {:acknowledge, organization_id, incident_id, operator_subject, operator_org,
         operator_role},
        _from,
        state
      ) do
    now = state.now_fn.()

    case check_authorization(
           state.incidents,
           incident_id,
           organization_id,
           operator_org,
           operator_role
         ) do
      {:ok, incident} ->
        if incident.state == :open do
          event = %IncidentEvent{
            id: state.event_id_fn.(),
            incident_id: incident.id,
            organization_id: organization_id,
            fingerprint: incident.fingerprint,
            event_type: :acknowledged_by_operator,
            kind: :acknowledged_by_operator,
            occurred_at: now,
            received_at: now,
            correlation_id: Incident.generate_correlation_id(),
            sequence: state.sequence + 1,
            payload: %{
              "operator_subject" => operator_subject,
              "operator_organization" => operator_org,
              "operator_role" => Atom.to_string(operator_role)
            }
          }

          timeline = [event | Map.get(state.events, incident.id, [])] |> sort_events()
          updated_incident = replay(incident, timeline)

          new_state = %{
            state
            | sequence: state.sequence + 1,
              incidents: Map.put(state.incidents, incident.id, updated_incident),
              events: Map.update(state.events, incident.id, [event], &[event | &1])
          }

          {:reply, {:ok, updated_incident}, broadcast(new_state, updated_incident)}
        else
          {:reply, {:error, :invalid_state}, state}
        end

      error ->
        {:reply, error, state}
    end
  end

  def handle_call(
        {:assign, organization_id, incident_id, assigned_to, operator_subject, operator_org,
         operator_role},
        _from,
        state
      ) do
    now = state.now_fn.()

    case check_authorization(
           state.incidents,
           incident_id,
           organization_id,
           operator_org,
           operator_role
         ) do
      {:ok, incident} ->
        event = %IncidentEvent{
          id: state.event_id_fn.(),
          incident_id: incident.id,
          organization_id: organization_id,
          fingerprint: incident.fingerprint,
          event_type: :assigned,
          kind: :assigned,
          occurred_at: now,
          received_at: now,
          correlation_id: Incident.generate_correlation_id(),
          sequence: state.sequence + 1,
          payload: %{
            "assigned_to" => assigned_to,
            "operator_subject" => operator_subject,
            "operator_organization" => operator_org,
            "operator_role" => Atom.to_string(operator_role)
          }
        }

        timeline = [event | Map.get(state.events, incident.id, [])] |> sort_events()
        updated_incident = replay(incident, timeline)

        new_state = %{
          state
          | sequence: state.sequence + 1,
            incidents: Map.put(state.incidents, incident.id, updated_incident),
            events: Map.update(state.events, incident.id, [event], &[event | &1])
        }

        {:reply, {:ok, updated_incident}, broadcast(new_state, updated_incident)}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call(
        {:unassign, organization_id, incident_id, operator_subject, operator_org, operator_role},
        _from,
        state
      ) do
    now = state.now_fn.()

    case check_authorization(
           state.incidents,
           incident_id,
           organization_id,
           operator_org,
           operator_role
         ) do
      {:ok, incident} ->
        event = %IncidentEvent{
          id: state.event_id_fn.(),
          incident_id: incident.id,
          organization_id: organization_id,
          fingerprint: incident.fingerprint,
          event_type: :assigned,
          kind: :assigned,
          occurred_at: now,
          received_at: now,
          correlation_id: Incident.generate_correlation_id(),
          sequence: state.sequence + 1,
          payload: %{
            "assigned_to" => nil,
            "operator_subject" => operator_subject,
            "operator_organization" => operator_org,
            "operator_role" => Atom.to_string(operator_role)
          }
        }

        timeline = [event | Map.get(state.events, incident.id, [])] |> sort_events()
        updated_incident = replay(incident, timeline)

        new_state = %{
          state
          | sequence: state.sequence + 1,
            incidents: Map.put(state.incidents, incident.id, updated_incident),
            events: Map.update(state.events, incident.id, [event], &[event | &1])
        }

        {:reply, {:ok, updated_incident}, broadcast(new_state, updated_incident)}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call(
        {:snooze, organization_id, incident_id, snooze_until, operator_subject, operator_org,
         operator_role},
        _from,
        state
      ) do
    now = state.now_fn.()

    case check_authorization(
           state.incidents,
           incident_id,
           organization_id,
           operator_org,
           operator_role
         ) do
      {:ok, incident} ->
        if is_valid_snooze_time(snooze_until, now) do
          event = %IncidentEvent{
            id: state.event_id_fn.(),
            incident_id: incident.id,
            organization_id: organization_id,
            fingerprint: incident.fingerprint,
            event_type: :snoozed,
            kind: :snoozed,
            occurred_at: now,
            received_at: now,
            correlation_id: Incident.generate_correlation_id(),
            sequence: state.sequence + 1,
            payload: %{
              "snoozed_until" => DateTime.to_iso8601(snooze_until),
              "operator_subject" => operator_subject,
              "operator_organization" => operator_org,
              "operator_role" => Atom.to_string(operator_role)
            }
          }

          timeline = [event | Map.get(state.events, incident.id, [])] |> sort_events()
          updated_incident = replay(incident, timeline)

          new_state = %{
            state
            | sequence: state.sequence + 1,
              incidents: Map.put(state.incidents, incident.id, updated_incident),
              events: Map.update(state.events, incident.id, [event], &[event | &1])
          }

          {:reply, {:ok, updated_incident}, broadcast(new_state, updated_incident)}
        else
          {:reply, {:error, :invalid_snooze_time}, state}
        end

      error ->
        {:reply, error, state}
    end
  end

  def handle_call(
        {:unsnooze, organization_id, incident_id, operator_subject, operator_org, operator_role},
        _from,
        state
      ) do
    now = state.now_fn.()

    case check_authorization(
           state.incidents,
           incident_id,
           organization_id,
           operator_org,
           operator_role
         ) do
      {:ok, incident} ->
        event = %IncidentEvent{
          id: state.event_id_fn.(),
          incident_id: incident.id,
          organization_id: organization_id,
          fingerprint: incident.fingerprint,
          event_type: :unsnoozed,
          kind: :unsnoozed,
          occurred_at: now,
          received_at: now,
          correlation_id: Incident.generate_correlation_id(),
          sequence: state.sequence + 1,
          payload: %{
            "operator_subject" => operator_subject,
            "operator_organization" => operator_org,
            "operator_role" => Atom.to_string(operator_role)
          }
        }

        timeline = [event | Map.get(state.events, incident.id, [])] |> sort_events()
        updated_incident = replay(incident, timeline)

        new_state = %{
          state
          | sequence: state.sequence + 1,
            incidents: Map.put(state.incidents, incident.id, updated_incident),
            events: Map.update(state.events, incident.id, [event], &[event | &1])
        }

        {:reply, {:ok, updated_incident}, broadcast(new_state, updated_incident)}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call(
        {:resolve, organization_id, incident_id, reason, operator_subject, operator_org,
         operator_role},
        _from,
        state
      ) do
    now = state.now_fn.()

    case check_authorization(
           state.incidents,
           incident_id,
           organization_id,
           operator_org,
           operator_role
         ) do
      {:ok, incident} ->
        event = %IncidentEvent{
          id: state.event_id_fn.(),
          incident_id: incident.id,
          organization_id: organization_id,
          fingerprint: incident.fingerprint,
          event_type: :manually_resolved,
          kind: :manually_resolved,
          occurred_at: now,
          received_at: now,
          correlation_id: Incident.generate_correlation_id(),
          sequence: state.sequence + 1,
          payload: %{
            "reason" => reason,
            "operator_subject" => operator_subject,
            "operator_organization" => operator_org,
            "operator_role" => Atom.to_string(operator_role)
          }
        }

        timeline = [event | Map.get(state.events, incident.id, [])] |> sort_events()
        updated_incident = replay(incident, timeline)

        new_state = %{
          state
          | sequence: state.sequence + 1,
            incidents: Map.put(state.incidents, incident.id, updated_incident),
            events: Map.update(state.events, incident.id, [event], &[event | &1])
        }

        {:reply, {:ok, updated_incident}, broadcast(new_state, updated_incident)}

      error ->
        {:reply, error, state}
    end
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
            service: evidence.service,
            software_version: evidence.software_version,
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

    # Check if this unhealthy evidence reopens a manually resolved incident
    should_reopen =
      existing != nil and existing.state == :resolved and existing.resolution_reason != nil and
        event_type in [:opened, :updated]

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

    events_list = [event | Map.get(state.events, incident.id, [])]

    # Add reopened event if needed
    events_list =
      if should_reopen do
        reopen_event = %IncidentEvent{
          id: state.event_id_fn.(),
          incident_id: incident.id,
          organization_id: evidence.organization_id,
          fingerprint: fingerprint,
          event_type: :reopened,
          kind: :reopened,
          occurred_at: evidence.occurred_at,
          received_at: evidence.received_at,
          correlation_id: evidence.correlation_id || incident.correlation_id,
          sequence: sequence + 1,
          payload: %{
            "reason" => "Manually resolved incident reopened due to new unhealthy evidence"
          }
        }

        [reopen_event | events_list]
      else
        events_list
      end

    timeline = events_list |> sort_events()
    new_sequence = if should_reopen, do: sequence + 1, else: sequence

    {replay(incident, timeline), event,
     %{state | sequence: new_sequence, events: Map.put(state.events, incident.id, events_list)}}
  end

  defp put_event(state, incident, event) do
    events = Map.get(state.events, incident.id, [])
    events = if Enum.any?(events, &(&1.id == event.id)), do: events, else: [event | events]

    %{
      state
      | incidents: Map.put(state.incidents, incident.id, incident),
        events: Map.put(state.events, incident.id, events),
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
        |> Enum.filter(&(&1.event_type in [:resolved, :manually_resolved]))
        |> List.last()
        |> then(& &1.occurred_at)
      end

    assigned_to =
      timeline
      |> Enum.filter(&(&1.event_type == :assigned))
      |> List.last()
      |> case do
        nil -> incident.assigned_to
        event -> Map.get(event.payload, "assigned_to")
      end

    snoozed_until =
      timeline
      |> Enum.filter(&(&1.event_type in [:snoozed, :unsnoozed]))
      |> List.last()
      |> case do
        nil ->
          incident.snoozed_until

        %{event_type: :unsnoozed} ->
          nil

        %{event_type: :snoozed, payload: payload} ->
          case DateTime.from_iso8601(Map.get(payload, "snoozed_until", "")) do
            {:ok, dt, _offset} -> dt
            _ -> nil
          end
      end

    resolution_reason =
      timeline
      |> Enum.filter(&(&1.event_type == :manually_resolved))
      |> List.last()
      |> case do
        nil -> incident.resolution_reason
        event -> Map.get(event.payload, "reason")
      end

    %{
      incident
      | opened_at: min_datetime(incident.opened_at || first.occurred_at, first.occurred_at),
        updated_at: last.occurred_at,
        state: state,
        acknowledged_at: acknowledged_at,
        resolved_at: resolved_at,
        assigned_to: assigned_to,
        snoozed_until: snoozed_until,
        resolution_reason: resolution_reason,
        event_count: length(timeline)
    }
  end

  defp transition(:acknowledged, :opened), do: :acknowledged
  defp transition(:acknowledged, :updated), do: :acknowledged
  defp transition(:acknowledged, :acknowledged_by_operator), do: :acknowledged
  defp transition(_state, :opened), do: :open
  defp transition(_state, :updated), do: :open
  defp transition(_state, :acknowledged), do: :acknowledged
  defp transition(_state, :acknowledged_by_operator), do: :acknowledged
  defp transition(_state, :resolved), do: :resolved
  defp transition(_state, :manually_resolved), do: :resolved
  defp transition(_state, :reopened), do: :open
  # Assignment, snooze, unsnooze don't change state
  defp transition(state, :assigned), do: state
  defp transition(state, :snoozed), do: state
  defp transition(state, :unsnoozed), do: state

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
         service: optional_string(fetch(evidence, :service)),
         software_version: optional_string(fetch(evidence, :software_version)),
         occurred_at: occurred_at,
         received_at: received_at,
         correlation_id: fetch(evidence, :correlation_id),
         event_type: event_type,
         explicit_event_type?: explicit_event_type?,
         payload: metadata_payload(payload, evidence)
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

  defp optional_string(value) when is_binary(value) and byte_size(value) > 0, do: value
  defp optional_string(_value), do: nil

  defp metadata_payload(payload, evidence) do
    payload
    |> put_optional_metadata("severity", optional_string(fetch(evidence, :severity)))
    |> put_optional_metadata("labels", normalize_labels(fetch(evidence, :labels)))
  end

  defp put_optional_metadata(payload, _key, nil), do: payload
  defp put_optional_metadata(payload, _key, []), do: payload
  defp put_optional_metadata(payload, key, value), do: Map.put(payload, key, value)

  defp normalize_labels(labels) when is_list(labels), do: Enum.filter(labels, &is_binary/1)
  defp normalize_labels(labels) when is_binary(labels), do: String.split(labels, ",", trim: true)
  defp normalize_labels(_labels), do: []

  defp broadcast(%{pubsub: nil} = state, _incident), do: state

  defp broadcast(state, incident) do
    Phoenix.PubSub.broadcast(
      state.pubsub,
      "incidents:#{incident.organization_id}",
      {:incident_changed, incident}
    )

    state
  end

  defp active?(%Incident{state: state}), do: state in [:open, :acknowledged]

  defp related_for(organization_id, incident, opts, server) do
    candidates =
      state_incidents(server)
      |> Enum.filter(&(&1.organization_id == organization_id))
      |> Enum.reject(&(&1.id == incident.id))
      |> Enum.filter(&related_candidate?(&1, opts, server))

    candidates
    |> Enum.filter(&Grouping.related?(incident, &1, opts))
    |> sort_incidents()
  end

  defp state_incidents(server) do
    GenServer.call(server, :list)
  end

  defp related_candidate?(incident, opts, server) do
    include_resolved = Keyword.get(opts, :include_resolved, false)

    active?(incident) or
      (include_resolved and recent?(incident, opts, server))
  end

  defp recent?(incident, opts, server) do
    case Keyword.get(opts, :recent_since) do
      %DateTime{} = since -> DateTime.compare(incident.updated_at, since) in [:eq, :gt]
      nil -> recent_seconds?(incident, Keyword.get(opts, :recent_seconds), server)
    end
  end

  defp recent_seconds?(_incident, nil, _server), do: false

  defp recent_seconds?(incident, seconds, server) when is_integer(seconds) and seconds >= 0 do
    case recent_now(server) do
      {:ok, now} ->
        cutoff = DateTime.add(now, -seconds, :second)
        DateTime.compare(incident.updated_at, cutoff) in [:eq, :gt]

      :error ->
        false
    end
  end

  defp recent_seconds?(_incident, _seconds, _server), do: false

  defp recent_now(server) do
    case :sys.get_state(server) do
      %{now_fn: now_fn} when is_function(now_fn, 0) -> {:ok, now_fn.()}
      _state -> :error
    end
  catch
    :exit, _reason -> :error
  end

  defp recent_incidents(state, organization_id, %DateTime{} = since) do
    state.incidents
    |> Map.values()
    |> Enum.filter(fn incident ->
      incident.organization_id == organization_id and
        DateTime.compare(incident.updated_at, since) in [:eq, :gt]
    end)
    |> sort_incidents()
  end

  defp recent_incidents(state, organization_id, seconds)
       when is_integer(seconds) and seconds >= 0 do
    cutoff = DateTime.add(state.now_fn.(), -seconds, :second)
    recent_incidents(state, organization_id, cutoff)
  end

  defp recent_incidents(_state, _organization_id, _since), do: []

  defp sort_events(events),
    do: Enum.sort_by(events, &{DateTime.to_unix(&1.occurred_at, :microsecond), &1.sequence})

  defp sort_incidents(incidents),
    do: Enum.sort_by(incidents, &{DateTime.to_unix(&1.opened_at, :microsecond), &1.id})

  defp min_datetime(nil, value), do: value

  defp min_datetime(left, right),
    do: if(DateTime.compare(left, right) == :gt, do: right, else: left)

  defp check_authorization(incidents, incident_id, organization_id, operator_org, operator_role) do
    case Map.fetch(incidents, incident_id) do
      {:ok, %{organization_id: ^organization_id} = incident} ->
        if operator_org == organization_id do
          if operator_role in [:operator, :admin] do
            {:ok, incident}
          else
            {:error, :access_denied}
          end
        else
          {:error, :organization_mismatch}
        end

      {:ok, _incident} ->
        {:error, :organization_mismatch}

      :error ->
        {:error, :not_found}
    end
  end

  defp is_valid_snooze_time(%DateTime{} = snooze_until, now) do
    DateTime.compare(snooze_until, now) == :gt
  end

  defp is_valid_snooze_time(_snooze_until, _now), do: false
end
