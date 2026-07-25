# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.EnrollmentClient do
  @moduledoc """
  Creates a node key and CSR locally, submits the CSR to the coordinator, and
  atomically installs the returned certificate chain.

  The private key is never included in the request. `:transport` is injectable
  for tests; the default transport requires HTTPS, verifies the configured CA
  and hostname, refuses redirects, and applies bounded timeouts.
  """

  alias Exocomp.Node.CredentialInstaller
  alias X509.Certificate.Extension

  @max_response_bytes 262_144

  @spec enroll(keyword()) :: {:ok, map()} | {:error, term()}
  def enroll(opts) when is_list(opts) do
    with {:ok, node_id} <- required(opts, :node_id),
         {:ok, token} <- required(opts, :token),
         {:ok, endpoint} <- required(opts, :endpoint),
         {:ok, directory} <- required(opts, :credential_dir),
         {:ok, ca_pem} <- ca_pem(opts),
         {key, key_pem, csr_pem} <- identity_request(node_id),
         request <- %{node_id: node_id, csr: csr_pem, token: token},
         {:ok, response} <- transport(opts).(endpoint, request, transport_opts(opts)),
         {:ok, chain_pem} <- response_chain(response),
         :ok <- response_size(chain_pem),
         :ok <- ensure_same_key(chain_pem, key),
         {:ok, paths} <-
           CredentialInstaller.install(chain_pem, key_pem, directory,
             node_id: node_id,
             ca_pem: ca_pem
           ) do
      {:ok, paths}
    end
  rescue
    _exception -> {:error, :enrollment_failed}
  end

  def enroll(_opts), do: {:error, :invalid_arguments}

  @doc "Builds an approved P-256 key and constrained PKCS#10 request."
  @spec identity_request(String.t()) :: {X509.PrivateKey.t(), binary(), binary()}
  def identity_request(node_id) when is_binary(node_id) and node_id != "" do
    key = X509.PrivateKey.new_ec(:secp256r1)

    extensions = [
      Extension.basic_constraints(false),
      Extension.key_usage([:digitalSignature]),
      Extension.ext_key_usage([:clientAuth, :serverAuth]),
      Extension.subject_alt_name([node_id])
    ]

    csr =
      key
      |> X509.CSR.new("/O=Exocomp/CN=#{node_id}", extension_request: extensions)
      |> X509.CSR.to_pem()

    {key, X509.PrivateKey.to_pem(key), csr}
  end

  defp required(opts, key) do
    case Keyword.get(opts, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _other -> {:error, {:missing_option, key}}
    end
  end

  defp ca_pem(opts) do
    case Keyword.get(opts, :ca_pem) do
      pem when is_binary(pem) and pem != "" -> {:ok, pem}
      _other -> {:error, {:missing_option, :ca_pem}}
    end
  end

  defp transport(opts), do: Keyword.get(opts, :transport, &__MODULE__.https_transport/3)

  defp transport_opts(opts) do
    Keyword.take(opts, [:ca_file, :connect_timeout_ms, :request_timeout_ms])
  end

  defp response_chain(%{"chain_pem" => pem}) when is_binary(pem), do: {:ok, pem}
  defp response_chain(%{chain_pem: pem}) when is_binary(pem), do: {:ok, pem}
  defp response_chain(_response), do: {:error, :invalid_enrollment_response}

  defp response_size(pem) when byte_size(pem) <= @max_response_bytes, do: :ok
  defp response_size(_pem), do: {:error, :enrollment_response_too_large}

  defp ensure_same_key(chain_pem, key) do
    with [{:Certificate, leaf_der, _} | _] <- :public_key.pem_decode(chain_pem),
         leaf <- X509.Certificate.from_der!(leaf_der),
         true <- X509.Certificate.public_key(leaf) == X509.PublicKey.derive(key) do
      :ok
    else
      _other -> {:error, :key_mismatch}
    end
  end

  @doc false
  def https_transport(endpoint, request, opts) do
    with {:ok, uri} <- require_https(endpoint),
         {:ok, ca_file} <- required(opts, :ca_file),
         {:ok, body} <-
           Jason.encode(%{"node_id" => request.node_id, "csr" => request.csr}),
         headers = [
           {~c"authorization", String.to_charlist("Bearer " <> request.token)},
           {~c"content-type", ~c"application/json"}
         ],
         http_options = http_options(uri, ca_file, opts),
         {:ok, {{_version, status, _reason}, response_headers, response_body}} <-
           :httpc.request(
             :post,
             {String.to_charlist(endpoint), headers, ~c"application/json", body},
             http_options,
             body_format: :binary
           ),
         :ok <- reject_redirect(status, response_headers),
         :ok <- successful_status(status),
         :ok <- response_size(response_body),
         {:ok, decoded} <- Jason.decode(response_body) do
      {:ok, decoded}
    else
      {:error, _reason} = error -> error
      _other -> {:error, :transport_failed}
    end
  end

  defp require_https(endpoint) do
    case URI.parse(endpoint) do
      %URI{scheme: "https", host: host} = uri when is_binary(host) and host != "" -> {:ok, uri}
      _other -> {:error, :https_required}
    end
  end

  defp http_options(uri, ca_file, opts) do
    connect_timeout = Keyword.get(opts, :connect_timeout_ms, 5_000)
    request_timeout = Keyword.get(opts, :request_timeout_ms, 15_000)

    [
      connect_timeout: connect_timeout,
      timeout: request_timeout,
      autoredirect: false,
      ssl: [
        verify: :verify_peer,
        cacertfile: String.to_charlist(ca_file),
        server_name_indication: String.to_charlist(uri.host),
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ],
        versions: [:"tlsv1.3", :"tlsv1.2"]
      ]
    ]
  end

  defp reject_redirect(status, _headers) when status in 300..399, do: {:error, :redirect_refused}
  defp reject_redirect(_status, _headers), do: :ok
  defp successful_status(status) when status in 200..299, do: :ok
  defp successful_status(status), do: {:error, {:http_error, status}}
end
