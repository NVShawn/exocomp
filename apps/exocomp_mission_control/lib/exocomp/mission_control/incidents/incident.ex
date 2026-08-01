# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Incidents.Incident do
  @moduledoc "Organization-scoped materialized incident record."

  alias Exocomp.MissionControl.Incidents.Fingerprint

  @states [:open, :acknowledged, :resolved]

  defstruct [
    :id,
    :organization_id,
    :fingerprint,
    :cluster_id,
    :alert_type,
    :source,
    :target_type,
    :target_identity,
    :correlation_id,
    :opened_at,
    :acknowledged_at,
    :resolved_at,
    :updated_at,
    :assigned_to,
    :snoozed_until,
    :resolution_reason,
    state: :open,
    event_count: 0
  ]

  @type state :: :open | :acknowledged | :resolved

  @type t :: %__MODULE__{
          id: String.t(),
          organization_id: String.t(),
          fingerprint: String.t(),
          cluster_id: String.t(),
          alert_type: String.t(),
          source: String.t(),
          target_type: String.t(),
          target_identity: String.t(),
          correlation_id: String.t(),
          opened_at: DateTime.t(),
          acknowledged_at: DateTime.t() | nil,
          resolved_at: DateTime.t() | nil,
          updated_at: DateTime.t(),
          assigned_to: String.t() | nil,
          snoozed_until: DateTime.t() | nil,
          resolution_reason: String.t() | nil,
          state: state(),
          event_count: non_neg_integer()
        }

  @doc "Returns the supported incident states."
  @spec states() :: [state()]
  def states, do: @states

  @doc "Returns the deterministic fingerprint for incident identity attributes."
  @spec fingerprint(map() | keyword()) :: String.t()
  def fingerprint(attributes), do: Fingerprint.build(attributes)

  @doc "Builds an incident from already-normalized identity attributes."
  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attributes) when is_map(attributes) do
    with :ok <- validate_required(attributes),
         {:ok, occurred_at} <- timestamp(Map.get(attributes, :occurred_at)) do
      identity =
        Map.take(attributes, [
          :organization_id,
          :cluster_id,
          :alert_type,
          :source,
          :target_type,
          :target_identity
        ])

      {:ok,
       %__MODULE__{
         id: Map.get(attributes, :id, generate_id()),
         organization_id: identity.organization_id,
         fingerprint: Map.get(attributes, :fingerprint, Fingerprint.build(identity)),
         cluster_id: identity.cluster_id,
         alert_type: identity.alert_type,
         source: identity.source,
         target_type: identity.target_type,
         target_identity: identity.target_identity,
         correlation_id: Map.get(attributes, :correlation_id, generate_correlation_id()),
         opened_at: occurred_at,
         updated_at: occurred_at
       }}
    end
  end

  def new(_attributes), do: {:error, :invalid_attributes}

  @doc "Generates a UUIDv4 without introducing a dependency on a UUID package."
  @spec generate_id() :: String.t()
  def generate_id do
    <<a::32, b::16, _::4, c::12, _::2, d::62>> = :crypto.strong_rand_bytes(16)

    <<a::32, b::16, 4::4, c::12, 2::2, d::62>>
    |> Base.encode16(case: :lower)
    |> then(fn hex ->
      String.slice(hex, 0, 8) <>
        "-" <>
        String.slice(hex, 8, 4) <>
        "-" <>
        String.slice(hex, 12, 4) <>
        "-" <>
        String.slice(hex, 16, 4) <>
        "-" <>
        String.slice(hex, 20, 12)
    end)
  end

  @spec generate_correlation_id() :: String.t()
  def generate_correlation_id do
    "corr_" <> Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
  end

  defp validate_required(attributes) do
    required = [
      :organization_id,
      :cluster_id,
      :alert_type,
      :source,
      :target_type,
      :target_identity
    ]

    case Enum.find(required, fn field -> not nonempty_binary?(Map.get(attributes, field)) end) do
      nil -> :ok
      field -> {:error, {:invalid_field, field}}
    end
  end

  defp nonempty_binary?(value), do: is_binary(value) and byte_size(value) > 0

  defp timestamp(nil), do: {:ok, DateTime.utc_now()}
  defp timestamp(%DateTime{} = value), do: {:ok, value}

  defp timestamp(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, parsed, _offset} -> {:ok, parsed}
      {:error, _reason} -> {:error, {:invalid_field, :occurred_at}}
    end
  end

  defp timestamp(_value), do: {:error, {:invalid_field, :occurred_at}}
end
