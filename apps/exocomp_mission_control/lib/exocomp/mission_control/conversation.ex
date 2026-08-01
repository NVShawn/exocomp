# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Conversation do
  @moduledoc """
  Organization-owned conversation metadata.

  A conversation is always scoped to a cluster. An incident conversation has
  an `incident_id`; an ad hoc conversation has no incident attached. Messages
  and memberships are kept on the aggregate so the in-memory store has one
  clear organization boundary to enforce.
  """

  @type kind :: :cluster | :incident

  @type t :: %__MODULE__{
          id: String.t(),
          organization_id: String.t(),
          cluster_id: String.t(),
          incident_id: String.t() | nil,
          kind: kind(),
          scope: kind(),
          title: String.t() | nil,
          memberships: [Exocomp.MissionControl.Membership.t()],
          messages: [Exocomp.MissionControl.Message.t()],
          created_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  defstruct [
    :id,
    :organization_id,
    :cluster_id,
    :incident_id,
    :kind,
    :scope,
    :title,
    memberships: [],
    messages: [],
    created_at: nil,
    updated_at: nil
  ]

  @doc "Build and validate a conversation from an attribute map."
  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_map(attrs) do
    organization_id = value(attrs, :organization_id)
    cluster_id = value(attrs, :cluster_id)
    incident_id = value(attrs, :incident_id)
    kind = value(attrs, :kind) || value(attrs, :scope)

    with :ok <- required_id(organization_id, :organization_id),
         :ok <- required_id(cluster_id, :cluster_id),
         :ok <- optional_id(incident_id, :incident_id),
         {:ok, kind} <- normalize_kind(kind, incident_id),
         :ok <- validate_title(value(attrs, :title)),
         {:ok, created_at} <- timestamp(value(attrs, :created_at)) do
      id = value(attrs, :id) || generate_id("conv_")

      if valid_id?(id) do
        {:ok,
         %__MODULE__{
           id: id,
           organization_id: organization_id,
           cluster_id: cluster_id,
           incident_id: incident_id,
           kind: kind,
           scope: kind,
           title: value(attrs, :title),
           memberships: value(attrs, :memberships) || [],
           messages: value(attrs, :messages) || [],
           created_at: created_at,
           updated_at: value(attrs, :updated_at) || created_at
         }}
      else
        {:error, {:invalid_id, :id}}
      end
    end
  end

  def new(_attrs), do: {:error, :invalid_conversation}

  @doc "Returns whether this conversation is attached to an incident."
  @spec incident?(t()) :: boolean()
  def incident?(%__MODULE__{kind: :incident}), do: true
  def incident?(%__MODULE__{}), do: false

  @doc "Returns whether this conversation is an ad hoc cluster conversation."
  @spec cluster?(t()) :: boolean()
  def cluster?(%__MODULE__{kind: :cluster}), do: true
  def cluster?(%__MODULE__{}), do: false

  defp normalize_kind(nil, nil), do: {:ok, :cluster}
  defp normalize_kind(nil, _incident_id), do: {:ok, :incident}

  defp normalize_kind(kind, incident_id) when kind in [:cluster, :incident] do
    if kind == :incident == not is_nil(incident_id) do
      {:ok, kind}
    else
      {:error, {:invalid_scope, kind}}
    end
  end

  defp normalize_kind(kind, incident_id) when is_binary(kind) do
    case kind do
      "cluster" -> normalize_kind(:cluster, incident_id)
      "incident" -> normalize_kind(:incident, incident_id)
      _ -> {:error, {:invalid_scope, kind}}
    end
  end

  defp normalize_kind(kind, _incident_id), do: {:error, {:invalid_scope, kind}}

  defp validate_title(nil), do: :ok
  defp validate_title(title) when is_binary(title) and byte_size(title) <= 256, do: :ok
  defp validate_title(_title), do: {:error, :invalid_title}

  defp required_id(value, _field) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp required_id(_value, field), do: {:error, {:required, field}}

  defp optional_id(nil, _field), do: :ok
  defp optional_id(value, field), do: required_id(value, field)

  defp valid_id?(value), do: is_binary(value) and byte_size(value) > 0

  defp timestamp(nil), do: {:ok, DateTime.utc_now()}
  defp timestamp(%DateTime{} = value), do: {:ok, value}
  defp timestamp(_value), do: {:error, :invalid_timestamp}

  defp value(attrs, key), do: Map.get(attrs, key, Map.get(attrs, Atom.to_string(key)))

  defp generate_id(prefix) do
    prefix <> Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
  end
end