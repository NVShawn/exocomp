# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.StatusReducer do
  import Kernel, except: [apply: 2]

  @moduledoc """
  Deterministically reconstructs service state from one snapshot and deltas.

  Events are retained by ID and sequence.  A duplicate delivery is a no-op;
  an event ID or sequence reused for different content is rejected.  The
  materialized view is rebuilt from the newest snapshot and all later events
  in sequence order, so applying an out-of-order fixture produces the same
  view as applying it in delivery order.
  """

  alias Exocomp.MissionControl.StatusEvent

  @enforce_keys [:events, :sequence_index, :current]
  defstruct events: %{},
            sequence_index: %{},
            current: %{},
            snapshot_sequence: nil,
            last_sequence: 0,
            last_result: nil

  @type t :: %__MODULE__{
          events: %{optional(String.t()) => StatusEvent.t()},
          sequence_index: %{optional(non_neg_integer()) => String.t()},
          current: %{{String.t(), String.t()} => map()},
          snapshot_sequence: non_neg_integer() | nil,
          last_sequence: non_neg_integer(),
          last_result: :applied | :duplicate | nil
        }

  @doc "Starts an empty replay state."
  @spec new() :: t()
  def new, do: %__MODULE__{events: %{}, sequence_index: %{}, current: %{}}

  @doc "Applies one event, returning a state and a duplicate/applied marker."
  @spec apply_event(t(), StatusEvent.t() | map()) ::
          {:ok, t(), :applied | :duplicate} | {:error, term()}
  def apply_event(%__MODULE__{} = state, raw_event) do
    with {:ok, event} <- normalize_event(raw_event),
         :ok <- reject_conflicts(state, event) do
      event_key = event.event_id

      case Map.fetch(state.events, event_key) do
        {:ok, _existing} ->
          {:ok, %{state | last_result: :duplicate}, :duplicate}

        :error ->
          state = %{
            state
            | events: Map.put(state.events, event_key, event),
              sequence_index: Map.put(state.sequence_index, event.cluster_seq, event_key),
              last_result: :applied
          }

          {:ok, rebuild(state), :applied}
      end
    end
  end

  @doc "Applies one event and returns the conventional two-tuple result."
  @spec apply(t(), StatusEvent.t() | map()) :: {:ok, t()} | {:error, term()}
  def apply(state, event) do
    case apply_event(state, event) do
      {:ok, state, _result} -> {:ok, state}
      {:error, _} = error -> error
    end
  end

  @doc "Applies a batch in delivery order while retaining sequence ordering."
  @spec apply_all(t(), [StatusEvent.t() | map()]) :: {:ok, t()} | {:error, term()}
  def apply_all(state, events) when is_list(events) do
    Enum.reduce_while(events, {:ok, state}, fn event, {:ok, state} ->
      case apply(state, event) do
        {:ok, state} -> {:cont, {:ok, state}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  @doc "Returns the current reconstructed service view keyed by `{node, unit}`."
  @spec current(t()) :: %{{String.t(), String.t()} => map()}
  def current(%__MODULE__{current: current}), do: current

  @doc "Returns retained events in deterministic sequence order."
  @spec events(t()) :: [StatusEvent.t()]
  def events(%__MODULE__{events: events}),
    do: events |> Map.values() |> Enum.sort_by(&{&1.cluster_seq, &1.event_id})

  @doc "Returns the highest sequence observed, including buffered out-of-order events."
  @spec last_sequence(t()) :: non_neg_integer()
  def last_sequence(%__MODULE__{last_sequence: sequence}), do: sequence

  @doc "Returns the number of retained events."
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{events: events}), do: map_size(events)

  defp normalize_event(%StatusEvent{} = event), do: {:ok, event}
  defp normalize_event(event), do: StatusEvent.decode(event)

  defp reject_conflicts(state, event) do
    case Map.fetch(state.events, event.event_id) do
      {:ok, existing} ->
        if existing == event, do: :ok, else: {:error, :event_id_conflict}

      :error ->
        case Map.fetch(state.sequence_index, event.cluster_seq) do
          {:ok, existing_id} when existing_id != event.event_id -> {:error, :sequence_conflict}
          _ -> :ok
        end
    end
  end

  defp rebuild(state) do
    ordered = events(state)
    snapshot = ordered |> Enum.filter(&(&1.kind == "service_summary.snapshot")) |> List.last()
    {current, snapshot_sequence} = base_view(snapshot)

    current =
      if is_nil(snapshot) do
        current
      else
        ordered
        |> Enum.filter(&(&1.cluster_seq > snapshot_sequence))
        |> Enum.reduce(current, &apply_delta(&2, &1))
      end

    last_sequence =
      ordered
      |> List.last()
      |> case do
        nil -> 0
        event -> event.cluster_seq
      end

    %{
      state
      | current: current,
        snapshot_sequence: snapshot_sequence,
        last_sequence: last_sequence
    }
  end

  defp base_view(nil), do: {%{}, nil}

  defp base_view(%StatusEvent{cluster_seq: sequence, payload: %{"services" => services}}) do
    {Map.new(services, &{{&1["node_id"], &1["unit"]}, &1}), sequence}
  end

  defp apply_delta(current, %StatusEvent{kind: "desired_state.removed", payload: payload}) do
    Map.delete(current, {payload["node_id"], payload["unit"]})
  end

  defp apply_delta(current, %StatusEvent{kind: kind, payload: payload})
       when kind in ["desired_state.added", "desired_state.changed", "service_status.changed"] do
    key = {payload["node_id"], payload["unit"]}
    Map.update(current, key, payload, &Map.merge(&1, payload))
  end

  defp apply_delta(current, _event), do: current
end
