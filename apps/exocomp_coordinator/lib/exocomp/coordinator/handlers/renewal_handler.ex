# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Handlers.RenewalHandler do
  @moduledoc """
  HTTP handler for node certificate renewal over mTLS.

  The node presents its existing certificate during the mTLS handshake.
  The coordinator extracts the node identity from the client certificate SAN,
  validates the submitted CSR against that identity, and issues a new leaf
  certificate.

  ## Endpoint

      POST /v1/renew
      (mTLS — node presents its existing coordinator-issued certificate)
      Content-Type: application/json
      {"csr": "<PEM-encoded CSR>"}

  ## Response

      200 OK
      {"chain_pem": "<PEM-encoded leaf + intermediate chain>"}

  ## Fail-closed behavior

  - Missing client certificate (not mTLS): 401
  - Client certificate has no DNS SAN: 401
  - Missing required body fields: 400
  - Invalid CSR (bad format, SAN mismatch, prohibited key usage, etc.): 422
  - PKI service unavailable: 503
  """

  @behaviour Plug

  import Plug.Conn

  require Logger

  alias Exocomp.Coordinator.Error
  alias Exocomp.Coordinator.PKI.{Issuer, State}

  @max_body_bytes 65_536

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with {:ok, node_id} <- extract_node_id_from_cert(conn),
         {:ok, conn, params} <- parse_json_body(conn),
         {:ok, csr_pem} <- require_field(params, "csr"),
         {:ok, online_state} <- pki_online_state(),
         {:ok, csr} <- validate_csr(csr_pem, node_id),
         {:ok, chain_pem} <- issue_leaf(csr, online_state) do
      json_response(conn, 200, %{"chain_pem" => chain_pem})
    else
      {:halt, conn} ->
        conn

      {:error, :no_client_cert} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, ~s({"error":"Client certificate required for renewal"}))

      {:error, :no_node_identity} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, ~s({"error":"Client certificate does not contain a node identity"}))

      {:error, :field_missing, field} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, ~s({"error":"Missing required field: #{field}"}))

      {:error, :pki_unavailable} ->
        Logger.warning("[RenewalHandler] PKI.State not running")
        service_unavailable(conn, "PKI service unavailable")

      {:error, %Error{code: :invalid_csr}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(422, ~s({"error":"CSR validation failed"}))

      {:error, %Error{}} ->
        service_unavailable(conn, "certificate issuance failed")

      {:error, _other} ->
        service_unavailable(conn, "internal error")
    end
  end

  # ── mTLS identity extraction ──────────────────────────────────────────────────

  # Extracts the node identity (DNS SAN) from the client certificate presented
  # during the mTLS handshake. The node must have been previously enrolled and
  # hold a coordinator-issued certificate containing a single DNS SAN.
  defp extract_node_id_from_cert(conn) do
    case get_peer_data(conn) do
      %{ssl_cert: ssl_cert} when is_binary(ssl_cert) and byte_size(ssl_cert) > 0 ->
        node_id_from_der(ssl_cert)

      _peer_data ->
        {:error, :no_client_cert}
    end
  end

  defp node_id_from_der(der_cert) do
    try do
      cert = X509.Certificate.from_der!(der_cert)

      case X509.Certificate.extension(cert, :subject_alt_name) do
        {:Extension, _oid, _critical, [{:dNSName, dns_name}]} ->
          {:ok, to_string(dns_name)}

        _other ->
          {:error, :no_node_identity}
      end
    rescue
      _exception -> {:error, :no_node_identity}
    end
  end

  # ── Body parsing ─────────────────────────────────────────────────────────────

  defp parse_json_body(conn) do
    case read_body(conn, length: @max_body_bytes) do
      {:ok, body, conn} ->
        case Jason.decode(body) do
          {:ok, params} when is_map(params) ->
            {:ok, conn, params}

          _other ->
            halt_response = send_error(conn, 400, "invalid JSON body")
            {:halt, halt_response}
        end

      {:more, _partial, conn} ->
        halt_response = send_error(conn, 413, "request body too large")
        {:halt, halt_response}

      {:error, _reason} ->
        halt_response = send_error(conn, 400, "failed to read request body")
        {:halt, halt_response}
    end
  end

  defp require_field(params, field) do
    case Map.get(params, field) do
      value when is_binary(value) and byte_size(value) > 0 ->
        {:ok, value}

      _other ->
        {:error, :field_missing, field}
    end
  end

  # ── PKI state lookup ──────────────────────────────────────────────────────────

  defp pki_online_state do
    if Process.whereis(State) do
      try do
        case State.status() do
          %{healthy: true, online_state: path} when is_binary(path) -> {:ok, path}
          _other -> {:error, :pki_unavailable}
        end
      catch
        :exit, _reason -> {:error, :pki_unavailable}
      end
    else
      {:error, :pki_unavailable}
    end
  end

  # ── Certificate issuance ─────────────────────────────────────────────────────

  defp validate_csr(csr_pem, node_id) do
    Issuer.validate_csr(csr_pem, node_id)
  end

  defp issue_leaf(csr, online_state) do
    Issuer.issue_leaf(csr, online_state)
  end

  # ── Response helpers ──────────────────────────────────────────────────────────

  defp json_response(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end

  defp send_error(conn, status, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(%{"error" => message}))
  end

  defp service_unavailable(conn, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(503, Jason.encode!(%{"error" => message}))
  end
end
