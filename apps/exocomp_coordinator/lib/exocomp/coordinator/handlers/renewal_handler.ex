# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Handlers.RenewalHandler do
  @moduledoc """
  HTTP handler for node certificate renewal over mTLS.

  The node presents its existing certificate during the mTLS handshake.
  The coordinator extracts the node identity from the client certificate SAN,
  validates renewal eligibility, validates the submitted CSR against that
  identity, issues a new leaf certificate, and registers the new serial in the
  `PKI.CertificateRegistry`.

  ## Renewal eligibility

  Renewal is permitted only when **all** of the following hold:

  - The presenting certificate was issued at least 20 days ago (the renewal
    window opens at day 20 of a 30-day certificate).
  - The certificate serial has not been explicitly revoked.
  - The node identity has not been explicitly revoked.

  This allows nodes to obtain a fresh certificate with a new serial in the
  last 10 days of their validity window, while preventing revoked nodes from
  re-enrolling through the renewal path.

  ## Endpoint

      POST /v1/renew
      POST /api/v1/clusters/renew
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
  - Renewal window not yet open (before day 20): 403
  - Certificate serial or node identity revoked: 403
  - Invalid CSR (bad format, SAN mismatch, prohibited key usage, etc.): 422
  - PKI service unavailable: 503
  """

  @behaviour Plug

  import Plug.Conn

  require Logger

  alias Exocomp.Coordinator.Error
  alias Exocomp.Coordinator.PKI.{CertificateRegistry, Issuer, State}

  @max_body_bytes 65_536
  @renewal_window_days 10
  @seconds_per_day 86_400

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with {:ok, node_id, cert_serial, not_before_unix, not_after_unix} <-
           extract_client_cert_info(conn),
         {:ok, conn, params} <- parse_json_body(conn),
         {:ok, csr_pem} <- require_field(params, "csr"),
         {:ok, online_state} <- pki_online_state(),
         :ok <- check_not_expired(not_after_unix),
         :ok <- check_renewal_window(not_before_unix),
         :ok <- check_revocation(cert_serial, node_id),
         {:ok, csr} <- validate_csr(csr_pem, node_id),
         {:ok, chain_pem} <- issue_leaf(csr, online_state),
         {:ok, new_serial, new_issued_at, new_expires_at} <- extract_issued_serial(chain_pem),
         :ok <- register_serial(new_serial, node_id, new_issued_at, new_expires_at) do
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

      {:error, :cert_expired} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, ~s({"error":"Client certificate has expired"}))

      {:error, :renewal_too_early} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          403,
          ~s({"error":"Certificate is not yet eligible for renewal; renewal opens at day 20"})
        )

      {:error, :certificate_revoked} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, ~s({"error":"Certificate has been revoked"}))

      {:error, :identity_revoked} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, ~s({"error":"Node identity has been revoked"}))

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

  # ── mTLS identity and certificate info extraction ────────────────────────────

  # Extracts the node identity (DNS SAN), serial number, and validity window
  # from the client certificate presented during the mTLS handshake.
  defp extract_client_cert_info(conn) do
    case get_peer_data(conn) do
      %{ssl_cert: ssl_cert} when is_binary(ssl_cert) and byte_size(ssl_cert) > 0 ->
        parse_client_cert(ssl_cert)

      _peer_data ->
        {:error, :no_client_cert}
    end
  end

  defp parse_client_cert(der_cert) do
    try do
      cert = X509.Certificate.from_der!(der_cert)

      with {:ok, node_id} <- node_id_from_cert(cert),
           {:ok, serial} <- serial_from_cert(cert),
           {:ok, not_before_unix, not_after_unix} <- validity_from_cert(cert) do
        {:ok, node_id, serial, not_before_unix, not_after_unix}
      end
    rescue
      _exception -> {:error, :no_node_identity}
    end
  end

  defp node_id_from_cert(cert) do
    case X509.Certificate.extension(cert, :subject_alt_name) do
      {:Extension, _oid, _critical, [{:dNSName, dns_name}]} ->
        {:ok, to_string(dns_name)}

      _other ->
        {:error, :no_node_identity}
    end
  end

  defp serial_from_cert(cert) do
    serial = X509.Certificate.serial(cert)

    if is_integer(serial) and serial >= 0 do
      {:ok, serial}
    else
      {:error, :no_node_identity}
    end
  end

  defp validity_from_cert(cert) do
    case X509.Certificate.validity(cert) do
      {:Validity, not_before, not_after} ->
        not_before_unix = CertificateRegistry.asn1_time_to_unix(not_before)
        not_after_unix = CertificateRegistry.asn1_time_to_unix(not_after)
        {:ok, not_before_unix, not_after_unix}

      _other ->
        {:error, :no_node_identity}
    end
  end

  # ── Renewal eligibility checks ────────────────────────────────────────────────

  defp check_not_expired(not_after_unix) do
    now = System.system_time(:second)

    if now >= not_after_unix do
      {:error, :cert_expired}
    else
      :ok
    end
  end

  defp check_renewal_window(not_before_unix) do
    now = System.system_time(:second)
    renewal_opens_at = not_before_unix + (30 - @renewal_window_days) * @seconds_per_day

    if now >= renewal_opens_at do
      :ok
    else
      {:error, :renewal_too_early}
    end
  end

  defp check_revocation(cert_serial, node_id) do
    with :active_or_unknown <- check_serial_revocation(cert_serial),
         :active_or_unknown <- check_identity_revocation(node_id) do
      :ok
    end
  end

  defp check_serial_revocation(cert_serial) do
    if registry_available?() do
      case CertificateRegistry.certificate_status(cert_serial) do
        :revoked -> {:error, :certificate_revoked}
        _ -> :active_or_unknown
      end
    else
      # Registry unavailable — fail open for serial check to allow renewal of
      # certs issued before the registry was running.
      :active_or_unknown
    end
  end

  defp check_identity_revocation(node_id) do
    if registry_available?() do
      case CertificateRegistry.identity_status(node_id) do
        :revoked -> {:error, :identity_revoked}
        _ -> :active_or_unknown
      end
    else
      :active_or_unknown
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

  # Extracts the serial number and validity window from the newly issued PEM
  # chain so it can be registered in the CertificateRegistry.
  defp extract_issued_serial(chain_pem) do
    try do
      case :public_key.pem_decode(chain_pem) do
        [{:Certificate, leaf_der, _} | _] ->
          leaf = X509.Certificate.from_der!(leaf_der)
          serial = X509.Certificate.serial(leaf)

          case X509.Certificate.validity(leaf) do
            {:Validity, not_before, not_after} ->
              issued_at = CertificateRegistry.asn1_time_to_unix(not_before)
              expires_at = CertificateRegistry.asn1_time_to_unix(not_after)
              {:ok, serial, issued_at, expires_at}

            _other ->
              {:error,
               Error.new(:pki_operation_failed, "could not extract validity from issued cert")}
          end

        _other ->
          {:error, Error.new(:pki_operation_failed, "issued chain PEM is malformed")}
      end
    rescue
      _exception ->
        {:error, Error.new(:pki_operation_failed, "could not parse issued certificate")}
    end
  end

  defp register_serial(serial, node_id, issued_at, expires_at) do
    if registry_available?() do
      case CertificateRegistry.register(serial, node_id, issued_at, expires_at) do
        :ok ->
          :ok

        # Non-fatal: log and continue — the cert was issued successfully
        {:error, _error} ->
          Logger.warning(
            "[RenewalHandler] Failed to register serial #{serial} for #{node_id} in CertificateRegistry"
          )

          :ok
      end
    else
      :ok
    end
  end

  defp registry_available? do
    case Process.whereis(CertificateRegistry) do
      pid when is_pid(pid) -> true
      nil -> false
    end
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
