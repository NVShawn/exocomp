# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Incidents.IncidentEvent do
  @moduledoc "An immutable, organization-scoped entry in an incident timeline."

  @event_types [:opened, :updated, :acknowledged, :resolved]

  defstruct [
    :id,
    :incident_id,
    :organization_id,
    :fingerprint,
    :event_type,
    :kind,
    :occurred_at,
    :received_at,
    :correlation_id,
    :sequence,
    payload: %{}
  ]

  @type event_type :: :opened | :updated | :acknowledged | :resolved

  @type t :: %__MODULE__{
          id: String.t(),
          incident_id: String.t(),
          organization_id: String.t(),
          fingerprint: String.t(),
          event_type: event_type(),
          kind: event_type(),
          occurred_at: DateTime.t(),
          received_at: DateTime.t(),
          correlation_id: String.t(),
          sequence: pos_integer(),
          payload: map()
        }

  @doc "Returns the event kinds accepted by the incident reducer."
  @spec event_types() :: [event_type()]
  def event_types, do: @event_types

  @doc "Builds an immutable incident event record from validated attributes."
  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attributes) when is_map(attributes) do
    with :ok <- validate_required(attributes),
         {:ok, event_type} <-
           event_type(Map.get(attributes, :event_type, Map.get(attributes, :kind))),
         {:ok, occurred_at} <- timestamp(Map.get(attributes, :occurred_at)),
         {:ok, received_at} <- timestamp(Map.get(attributes, :received_at, occurred_at)),
         :ok <- validate_sequence(Map.get(attributes, :sequence, 1)),
         :ok <- validate_payload(Map.get(attributes, :payload, %{})) do
      {:ok,
       %__MODULE__{
         id: Map.get(attributes, :id, generate_id()),
         incident_id: attributes.incident_id,
         organization_id: attributes.organization_id,
         fingerprint: attributes.fingerprint,
         event_type: event_type,
         kind: event_type,
         occurred_at: occurred_at,
         received_at: received_at,
         correlation_id: attributes.correlation_id,
         sequence: Map.get(attributes, :sequence, 1),
         payload: Map.get(attributes, :payload, %{})
       }}
    end
  end

  def new(_attributes), do: {:error, :invalid_attributes}

  @doc "Generates an event identifier."
  @spec generate_id() :: String.t()
  def generate_id, do: Exocomp.MissionControl.Incidents.Incident.generate_id()

  defp validate_required(attributes) do
    fields = [:incident_id, :organization_id, :fingerprint, :correlation_id]

    case Enum.find(fields, fn field -> not nonempty_binary?(Map.get(attributes, field)) end) do
      nil -> :ok
      field -> {:error, {:invalid_field, field}}
    end
  end

  defp event_type(value) when value in @event_types, do: {:ok, value}
  defp event_type("opened"), do: {:ok, :opened}
  defp event_type("updated"), do: {:ok, :updated}
  defp event_type("acknowledged"), do: {:ok, :acknowledged}
  defp event_type("resolved"), do: {:ok, :resolved}
  defp event_type("alert.opened"), do: {:ok, :opened}
  defp event_type("alert.updated"), do: {:ok, :updated}
  defp event_type("alert.resolved"), do: {:ok, :resolved}
  defp event_type(_value), do: {:error, {:invalid_field, :event_type}}

  defp timestamp(%DateTime{} = value), do: {:ok, value}

  defp timestamp(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, parsed, _offset} -> {:ok, parsed}
      {:error, _reason} -> {:error, {:invalid_field, :timestamp}}
    end
  end

  defp timestamp(_value), do: {:error, {:invalid_field, :timestamp}}

  defp validate_sequence(value) when is_integer(value) and value > 0, do: :ok
  defp validate_sequence(_value), do: {:error, {:invalid_field, :sequence}}

  defp validate_payload(value) when is_map(value), do: :ok
  defp validate_payload(_value), do: {:error, {:invalid_field, :payload}}

  defp nonempty_binary?(value), do: is_binary(value) and byte_size(value) > 0
end
