# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Cluster do
  @moduledoc """
  Organization-scoped cluster identity.

  A cluster name is unique within an organization.  The organization ID is
  part of the record rather than being inferred from the name so every query
  and authorization decision has an explicit tenant boundary.
  """

  alias Exocomp.Coordinator.Error

  @enforce_keys [:id, :organization_id, :name, :labels, :inserted_at]
  defstruct [:id, :organization_id, :name, :labels, :inserted_at]

  @type t :: %__MODULE__{
          id: String.t(),
          organization_id: String.t(),
          name: String.t(),
          labels: %{optional(String.t()) => String.t()},
          inserted_at: integer()
        }

  @doc "Builds a validated organization-scoped cluster record."
  @spec new(map()) :: {:ok, t()} | {:error, Error.t()}
  def new(attrs) when is_map(attrs) do
    with {:ok, organization_id} <- required_string(attrs, :organization_id),
         {:ok, name} <- cluster_name(attrs),
         {:ok, labels} <- labels(attrs),
         {:ok, id} <- required_string(attrs, :id),
         {:ok, inserted_at} <- required_integer(attrs, :inserted_at) do
      {:ok,
       %__MODULE__{
         id: id,
         organization_id: organization_id,
         name: name,
         labels: labels,
         inserted_at: inserted_at
       }}
    end
  end

  def new(_attrs), do: {:error, Error.new(:invalid_cluster, "cluster attributes must be a map")}

  @doc "Returns a JSON-safe public representation without private store fields."
  @spec public(t()) :: map()
  def public(%__MODULE__{} = cluster) do
    %{
      "id" => cluster.id,
      "organization_id" => cluster.organization_id,
      "name" => cluster.name,
      "labels" => cluster.labels,
      "inserted_at" => cluster.inserted_at
    }
  end

  defp cluster_name(attrs) do
    case fetch(attrs, :name) do
      name when is_binary(name) ->
        normalized = String.trim(name)

        if normalized == "" do
          {:error, Error.new(:invalid_cluster_name, "cluster name must not be empty")}
        else
          {:ok, normalized}
        end

      _ ->
        {:error, Error.new(:invalid_cluster_name, "cluster name must be a non-empty string")}
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
      value when is_binary(value) ->
        value = String.trim(value)

        if value == "" do
          {:error, Error.new(:invalid_cluster, "#{key} must not be empty")}
        else
          {:ok, value}
        end

      _ ->
        {:error, Error.new(:invalid_cluster, "#{key} must be a non-empty string")}
    end
  end

  defp required_integer(attrs, key) do
    case fetch(attrs, key) do
      value when is_integer(value) -> {:ok, value}
      _ -> {:error, Error.new(:invalid_cluster, "#{key} must be an integer")}
    end
  end

  defp fetch(attrs, key, default \\ nil) do
    Map.get(attrs, key, Map.get(attrs, Atom.to_string(key), default))
  end
end
