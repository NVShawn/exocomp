# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.EvidenceReference do
  @moduledoc """
  A bounded citation to sanitized evidence held by a cluster.

  This is deliberately a reference, not an evidence payload. Unknown fields
  are rejected, which prevents file attachments, raw-log blobs, and arbitrary
  model output from entering the conversation store.
  """

  @allowed_fields MapSet.new([
                    :id,
                    :organization_id,
                    :cluster_id,
                    :evidence_id,
                    :node_id,
                    :service,
                    :evidence_type,
                    :observed_at,
                    :evidence_hash
                  ])

  @type t :: %__MODULE__{
          id: String.t(),
          organization_id: String.t(),
          cluster_id: String.t(),
          evidence_id: String.t(),
          node_id: String.t(),
          service: String.t() | nil,
          evidence_type: String.t() | nil,
          observed_at: DateTime.t(),
          evidence_hash: String.t()
        }

  defstruct [
    :id,
    :organization_id,
    :cluster_id,
    :evidence_id,
    :node_id,
    :service,
    :evidence_type,
    :observed_at,
    :evidence_hash
  ]

  @doc "Build and validate a structured evidence reference."
  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_map(attrs) do
    case unsupported_field(attrs) do
      nil -> build(attrs)
      field -> {:error, {:unsupported_evidence_field, field}}
    end
  end

  def new(_attrs), do: {:error, :invalid_evidence_reference}

  @doc "Convert the reference to a JSON-friendly map without adding payload data."
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = reference) do
    Map.from_struct(reference)
    |> Map.update!(:observed_at, &DateTime.to_iso8601/1)
  end

  defp build(attrs) do
    fields = Map.new(@allowed_fields, fn field -> {field, value(attrs, field)} end)

    with :ok <- required_id(fields.organization_id, :organization_id),
         :ok <- required_id(fields.cluster_id, :cluster_id),
         :ok <- required_id(fields.evidence_id, :evidence_id),
         :ok <- required_id(fields.node_id, :node_id),
         :ok <- required_id(fields.evidence_hash, :evidence_hash),
         :ok <- optional_id(fields.service, :service),
         :ok <- optional_id(fields.evidence_type, :evidence_type),
         {:ok, observed_at} <- timestamp(fields.observed_at) do
      {:ok,
       %__MODULE__{
         id: fields.id || generate_id("eref_"),
         organization_id: fields.organization_id,
         cluster_id: fields.cluster_id,
         evidence_id: fields.evidence_id,
         node_id: fields.node_id,
         service: fields.service,
         evidence_type: fields.evidence_type,
         observed_at: observed_at,
         evidence_hash: fields.evidence_hash
       }}
    end
  end

  defp unsupported_field(attrs) do
    attrs
    |> Map.keys()
    |> Enum.map(&normalize_key/1)
    |> Enum.find(fn key -> key not in @allowed_fields end)
  end

  defp normalize_key(key) when is_atom(key), do: key

  defp normalize_key(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end

  defp normalize_key(key), do: key

  defp value(attrs, key), do: Map.get(attrs, key, Map.get(attrs, Atom.to_string(key)))

  defp required_id(value, _field) when is_binary(value) and byte_size(value) > 0, do: :ok
  defp required_id(_value, field), do: {:error, {:required, field}}

  defp optional_id(nil, _field), do: :ok
  defp optional_id(value, field), do: required_id(value, field)

  defp timestamp(%DateTime{} = value), do: {:ok, value}

  defp timestamp(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, timestamp, _offset} -> {:ok, timestamp}
      _ -> {:error, :invalid_timestamp}
    end
  end

  defp timestamp(_value), do: {:error, :invalid_timestamp}

  defp generate_id(prefix) do
    prefix <> Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
  end
end