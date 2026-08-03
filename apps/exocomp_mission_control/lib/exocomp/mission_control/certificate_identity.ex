# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.CertificateIdentity do
  @moduledoc """
  Extracts the organization and cluster identity from an authenticated peer
  certificate.

  The gateway calls this module before it upgrades the HTTP request.  A
  payload is intentionally not an input to this API: the certificate's
  single SPIFFE URI is the only source of tenant and cluster identity.
  """

  @spiffe_pattern ~r/\Aspiffe:\/\/exocomp\/organizations\/([^\/]+)\/clusters\/([^\/]+)\z/

  @type t :: %{
          required(:spiffe_id) => String.t(),
          required(:organization_id) => String.t(),
          required(:cluster_id) => String.t(),
          required(:certificate_der) => binary()
        }

  @doc "Extracts a cluster identity from `Plug.Conn.get_peer_data/1`."
  @spec from_conn(Plug.Conn.t(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_conn(conn, opts \\ []) do
    from_peer_data(Plug.Conn.get_peer_data(conn), opts)
  end

  @doc "Extracts and optionally path-validates a cluster certificate."
  @spec from_peer_data(map(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_peer_data(peer_data, opts \\ [])

  def from_peer_data(peer_data, opts) when is_map(peer_data) do
    with {:ok, der} <- peer_certificate(peer_data),
         :ok <- validate_chain(der, peer_data, opts),
         {:ok, certificate} <- parse_certificate(der),
         {:ok, spiffe_id} <- single_spiffe_uri(certificate),
         {:ok, organization_id, cluster_id} <- parse_spiffe_uri(spiffe_id) do
      {:ok,
       %{
         spiffe_id: spiffe_id,
         organization_id: organization_id,
         cluster_id: cluster_id,
         certificate_der: der
       }}
    end
  end

  def from_peer_data(_peer_data, _opts), do: {:error, :missing_client_certificate}

  defp peer_certificate(%{ssl_cert: der}) when is_binary(der) and byte_size(der) > 0,
    do: {:ok, der}

  defp peer_certificate(_peer_data), do: {:error, :missing_client_certificate}

  defp validate_chain(der, peer_data, opts) do
    case Keyword.get(opts, :trusted_root, Keyword.get(opts, :trust_root)) do
      nil ->
        :ok

      root ->
        with {:ok, root_der} <- root_der(root),
             chain <- peer_chain(peer_data, der),
             {:ok, _validation_state} <-
               :public_key.pkix_path_validation(root_der, Enum.reverse(chain), []) do
          :ok
        else
          {:error, {_certificate, reason}} -> {:error, {:invalid_certificate_chain, reason}}
          {:error, reason} -> {:error, {:invalid_certificate_chain, reason}}
          _other -> {:error, :invalid_certificate_chain}
        end
    end
  end

  defp root_der(der) when is_binary(der) do
    case File.read(der) do
      {:ok, pem} ->
        pem_root(pem)

      {:error, _reason} ->
        if String.starts_with?(der, "-----BEGIN"), do: pem_root(der), else: {:ok, der}
    end
  end

  defp root_der(path) when is_list(path), do: root_der(to_string(path))

  defp root_der(_root), do: {:error, :invalid_trusted_root}

  defp pem_root(pem) do
    case :public_key.pem_decode(pem) do
      [{:Certificate, der, _encoding} | _] -> {:ok, der}
      _other -> {:error, :invalid_trusted_root}
    end
  rescue
    _exception -> {:error, :invalid_trusted_root}
  end

  defp peer_chain(peer_data, der) do
    case Map.get(peer_data, :ssl_cert_chain, Map.get(peer_data, "ssl_cert_chain")) do
      chain when is_list(chain) and chain != [] -> [der | chain]
      _other -> [der]
    end
  end

  defp parse_certificate(der) do
    {:ok, X509.Certificate.from_der!(der)}
  rescue
    _exception -> {:error, :invalid_client_certificate}
  end

  defp single_spiffe_uri(certificate) do
    case X509.Certificate.extension(certificate, :subject_alt_name) do
      {:Extension, _oid, _critical, names} when is_list(names) ->
        uris = names |> Enum.flat_map(&spiffe_uri/1)

        case uris do
          [uri] -> {:ok, uri}
          [] -> {:error, :missing_cluster_identity}
          _many -> {:error, :ambiguous_cluster_identity}
        end

      _other ->
        {:error, :missing_cluster_identity}
    end
  rescue
    _exception -> {:error, :invalid_client_certificate}
  end

  defp spiffe_uri({:uniformResourceIdentifier, uri}), do: [to_string(uri)]
  defp spiffe_uri({:URI, uri}), do: [to_string(uri)]
  defp spiffe_uri(_other), do: []

  defp parse_spiffe_uri(uri) do
    case Regex.run(@spiffe_pattern, uri, capture: :all_but_first) do
      [organization_id, cluster_id] when organization_id != "" and cluster_id != "" ->
        {:ok, organization_id, cluster_id}

      _other ->
        {:error, :invalid_cluster_identity}
    end
  end
end
