# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ClusterInvitation do
  @moduledoc """
  Organization-scoped, single-use cluster invitation schema.

  `token_digest` is deliberately the only token representation in this
  record. The plaintext token exists only in the return value from issuance
  and is never put in a record, audit event, or persisted document.
  """

  alias Exocomp.Coordinator.Error

  @enforce_keys [
    :id,
    :organization_id,
    :cluster_id,
    :cluster_name,
    :labels,
    :token_digest,
    :expires_at,
    :inserted_at
  ]
  defstruct [
    :id,
    :organization_id,
    :cluster_id,
    :cluster_name,
    :labels,
    :token_digest,
    :expires_at,
    :consumed_at,
    :inserted_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          organization_id: String.t(),
          cluster_id: String.t(),
          cluster_name: String.t(),
          labels: %{optional(String.t()) => String.t()},
          token_digest: binary(),
          expires_at: integer(),
          consumed_at: integer() | nil,
          inserted_at: integer()
        }

  @doc "Builds a validated invitation record."
  @spec new(map()) :: {:ok, t()} | {:error, Error.t()}
  def new(attrs) when is_map(attrs) do
    with {:ok, id} <- required_string(attrs, :id),
         {:ok, organization_id} <- required_string(attrs, :organization_id),
         {:ok, cluster_id} <- required_string(attrs, :cluster_id),
         {:ok, cluster_name} <- required_string(attrs, :cluster_name),
         {:ok, labels} <- labels(attrs),
         {:ok, token_digest} <- digest(attrs),
         {:ok, expires_at} <- required_integer(attrs, :expires_at),
         {:ok, inserted_at} <- required_integer(attrs, :inserted_at),
         :ok <- valid_consumed_at(attrs) do
      {:ok,
       %__MODULE__{
         id: id,
         organization_id: organization_id,
         cluster_id: cluster_id,
         cluster_name: cluster_name,
         labels: labels,
         token_digest: token_digest,
         expires_at: expires_at,
         consumed_at: fetch(attrs, :consumed_at),
         inserted_at: inserted_at
       }}
    end
  end

  def new(_attrs),
    do: {:error, Error.new(:invalid_cluster_invitation, "invitation attributes must be a map")}

  @doc "Returns the non-secret fields suitable for an API response."
  @spec public(t()) :: map()
  def public(%__MODULE__{} = invitation) do
    %{
      "id" => invitation.id,
      "organization_id" => invitation.organization_id,
      "cluster_id" => invitation.cluster_id,
      "cluster_name" => invitation.cluster_name,
      "labels" => invitation.labels,
      "expires_at" => invitation.expires_at,
      "inserted_at" => invitation.inserted_at,
      "consumed_at" => invitation.consumed_at
    }
  end

  @doc "Returns whether the invitation is expired at `now`."
  @spec expired?(t(), integer()) :: boolean()
  def expired?(%__MODULE__{expires_at: expires_at}, now) when is_integer(now),
    do: now >= expires_at

  @doc "Returns whether the invitation has already been consumed."
  @spec consumed?(t()) :: boolean()
  def consumed?(%__MODULE__{consumed_at: consumed_at}), do: not is_nil(consumed_at)

  defp digest(attrs) do
    case fetch(attrs, :token_digest) do
      digest when is_binary(digest) and byte_size(digest) == 32 -> {:ok, digest}
      _ -> {:error, Error.new(:invalid_cluster_invitation, "token digest must be 32 bytes")}
    end
  end

  defp labels(attrs) do
    case fetch(attrs, :labels, %{}) do
      labels when is_map(labels) ->
        if Enum.all?(labels, fn {key, value} -> is_binary(key) and is_binary(value) end) do
          {:ok, labels}
        else
          {:error,
           Error.new(:invalid_cluster_labels, "cluster labels must be string key/value pairs")}
        end

      _ ->
        {:error, Error.new(:invalid_cluster_labels, "cluster labels must be a map")}
    end
  end

  defp required_string(attrs, key) do
    case fetch(attrs, key) do
      value when is_binary(value) and byte_size(value) > 0 ->
        value = String.trim(value)

        if value == "" do
          {:error, Error.new(:invalid_cluster_invitation, "#{key} must not be empty")}
        else
          {:ok, value}
        end

      _ ->
        {:error, Error.new(:invalid_cluster_invitation, "#{key} must be a non-empty string")}
    end
  end

  defp required_integer(attrs, key) do
    case fetch(attrs, key) do
      value when is_integer(value) -> {:ok, value}
      _ -> {:error, Error.new(:invalid_cluster_invitation, "#{key} must be an integer")}
    end
  end

  defp valid_consumed_at(attrs) do
    case fetch(attrs, :consumed_at) do
      nil ->
        :ok

      value when is_integer(value) ->
        :ok

      _ ->
        {:error, Error.new(:invalid_cluster_invitation, "consumed_at must be an integer or nil")}
    end
  end

  defp fetch(attrs, key, default \\ nil) do
    Map.get(attrs, key, Map.get(attrs, Atom.to_string(key), default))
  end
end
