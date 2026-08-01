# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Membership do
  @moduledoc "A participant's organization-scoped membership in a conversation."

  @type member_type :: :operator | :cluster

  @type t :: %__MODULE__{
          id: String.t(),
          organization_id: String.t(),
          conversation_id: String.t(),
          member_type: member_type(),
          member_id: String.t(),
          role: atom() | nil,
          joined_at: DateTime.t()
        }

  defstruct [:id, :organization_id, :conversation_id, :member_type, :member_id, :role, :joined_at]

  @doc "Build and validate a conversation membership."
  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_map(attrs) do
    organization_id = value(attrs, :organization_id)
    conversation_id = value(attrs, :conversation_id)
    member_type = normalize_type(value(attrs, :member_type) || value(attrs, :type))
    member_id = value(attrs, :member_id)

    with :ok <- required_id(organization_id, :organization_id),
         :ok <- required_id(conversation_id, :conversation_id),
         {:ok, member_type} <- member_type,
         :ok <- required_id(member_id, :member_id),
         {:ok, joined_at} <- timestamp(value(attrs, :joined_at)) do
      {:ok,
       %__MODULE__{
         id: value(attrs, :id) || generate_id("member_"),
         organization_id: organization_id,
         conversation_id: conversation_id,
         member_type: member_type,
         member_id: member_id,
         role: value(attrs, :role),
         joined_at: joined_at
       }}
    end
  end

  def new(_attrs), do: {:error, :invalid_membership}

  defp normalize_type(type) when type in [:operator, :cluster], do: {:ok, type}
  defp normalize_type("operator"), do: {:ok, :operator}
  defp normalize_type("cluster"), do: {:ok, :cluster}
  defp normalize_type(type), do: {:error, {:invalid_member_type, type}}

  defp required_id(value, _field) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp required_id(_value, field), do: {:error, {:required, field}}

  defp timestamp(nil), do: {:ok, DateTime.utc_now()}
  defp timestamp(%DateTime{} = value), do: {:ok, value}
  defp timestamp(_value), do: {:error, :invalid_timestamp}

  defp value(attrs, key), do: Map.get(attrs, key, Map.get(attrs, Atom.to_string(key)))

  defp generate_id(prefix) do
    prefix <> Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
  end
end
