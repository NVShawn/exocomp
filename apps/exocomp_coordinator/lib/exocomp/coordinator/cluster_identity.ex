# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.ClusterIdentity do
  @moduledoc """
  The authenticated organization and cluster identity for a delivery session.

  Event envelopes never carry authoritative identity. The HTTP handler derives
  this value from the already authenticated peer certificate and passes it to
  the ingestion boundary.
  """

  alias Exocomp.Coordinator.Error

  @enforce_keys [:organization_id, :cluster_id]
  defstruct [:organization_id, :cluster_id]

  @type t :: %__MODULE__{
          organization_id: String.t(),
          cluster_id: String.t()
        }

  @doc "Builds a validated identity from atom- or string-keyed attributes."
  @spec new(map() | t()) :: {:ok, t()} | {:error, Error.t()}
  def new(%__MODULE__{} = identity) do
    new(%{
      organization_id: identity.organization_id,
      cluster_id: identity.cluster_id
    })
  end

  def new(attrs) when is_map(attrs) do
    with {:ok, organization_id} <- required_string(attrs, :organization_id),
         {:ok, cluster_id} <- required_string(attrs, :cluster_id) do
      {:ok, %__MODULE__{organization_id: organization_id, cluster_id: cluster_id}}
    end
  end

  def new(_attrs),
    do: {:error, Error.new(:invalid_cluster_identity, "cluster identity must be a map")}

  @doc "Extracts the Mission Control SPIFFE identity from a peer certificate DER."
  @spec from_certificate(binary()) :: {:ok, t()} | {:error, Error.t()}
  def from_certificate(der) when is_binary(der) do
    with {:ok, certificate} <- parse_certificate(der),
         {:ok, sans} <- subject_alt_names(certificate),
         {:ok, uri} <- find_spiffe_uri(sans),
         {:ok, identity} <- from_spiffe_uri(uri) do
      {:ok, identity}
    end
  end

  def from_certificate(_der),
    do: {:error, Error.new(:invalid_cluster_certificate, "peer certificate is invalid")}

  @doc "Parses `spiffe://exocomp/organizations/{org}/clusters/{cluster}`."
  @spec from_spiffe_uri(String.t()) :: {:ok, t()} | {:error, Error.t()}
  def from_spiffe_uri(uri) when is_binary(uri) do
    parsed = URI.parse(uri)
    segments = path_segments(parsed.path)

    case segments do
      ["organizations", organization_id, "clusters", cluster_id]
      when parsed.scheme == "spiffe" and parsed.host == "exocomp" and
             parsed.query == nil and parsed.fragment == nil ->
        new(%{organization_id: organization_id, cluster_id: cluster_id})

      _other ->
        {:error,
         Error.new(:invalid_cluster_certificate, "peer certificate has no valid cluster identity")}
    end
  end

  def from_spiffe_uri(_uri),
    do: {:error, Error.new(:invalid_cluster_certificate, "peer certificate identity is invalid")}

  defp parse_certificate(der) do
    try do
      {:ok, X509.Certificate.from_der!(der)}
    rescue
      _exception ->
        {:error, Error.new(:invalid_cluster_certificate, "peer certificate is invalid")}
    end
  end

  defp subject_alt_names(certificate) do
    case X509.Certificate.extension(certificate, :subject_alt_name) do
      {:Extension, _oid, _critical, names} when is_list(names) -> {:ok, names}
      _other -> {:error, Error.new(:invalid_cluster_certificate, "peer certificate has no SAN")}
    end
  end

  defp find_spiffe_uri(names) do
    case Enum.find_value(names, fn
           {:uniformResourceIdentifier, uri} -> to_string(uri)
           _other -> nil
         end) do
      uri when is_binary(uri) ->
        {:ok, uri}

      nil ->
        {:error, Error.new(:invalid_cluster_certificate, "peer certificate has no SPIFFE SAN")}
    end
  end

  defp path_segments(path) when is_binary(path) do
    path
    |> String.split("/", trim: true)
    |> Enum.reject(&(&1 == ""))
  end

  defp path_segments(_path), do: []

  defp required_string(attrs, key) do
    value = Map.get(attrs, key, Map.get(attrs, Atom.to_string(key)))

    if is_binary(value) and String.trim(value) != "" do
      {:ok, String.trim(value)}
    else
      {:error, Error.new(:invalid_cluster_identity, "#{key} must be a non-empty string")}
    end
  end
end
