# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Handlers.EnrollmentHandler do
  @moduledoc """
  HTTP handler for node enrollment.

  Accepts a single-use enrollment token issued by the coordinator operator,
  validates the presented CSR, issues a node leaf certificate bound to the
  token's node identity, and returns the signed chain PEM.

  ## Endpoint

      POST /v1/enroll
      Authorization: Bearer <enrollment_token>
      Content-Type: application/json
      {"node_id": "<node_id>", "csr": "<PEM-encoded CSR>"}

  ## Response

      200 OK
      {"chain_pem": "<PEM-encoded leaf + intermediate chain>"}

  ## Fail-closed behavior

  - Missing or malformed Authorization header: 401
  - Missing required body fields: 400
  - Token not found, expired, already consumed, or bound to a different node: 401
  - Invalid CSR (bad format, wrong SAN, prohibited key usage, etc.): 422
  - PKI or enrollment service unavailable: 503
  - Audit write failure (enrollment token consumed but cert cannot be issued): 503

  The enrollment token is consumed atomically before certificate issuance.
  If issuance fails after consumption the token cannot be replayed; the node
  must obtain a new token.
  """

  @behaviour Plug

  import Plug.Conn

  require Logger

  alias Exocomp.Coordinator.{EnrollmentToken, Error}
  alias Exocomp.Coordinator.PKI.{Issuer, State}

  @max_body_bytes 65_536

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with {:ok, conn, token} <- extract_bearer(conn),
         {:ok, conn, params} <- parse_json_body(conn),
         {:ok, node_id} <- require_field(params, "node_id"),
         {:ok, csr_pem} <- require_field(params, "csr"),
         {:ok, online_state} <- pki_online_state(),
         :ok <- consume_token(token, node_id),
         {:ok, csr} <- validate_csr(csr_pem, node_id),
         {:ok, chain_pem} <- issue_leaf(csr, online_state) do
      json_response(conn, 200, %{"chain_pem" => chain_pem})
    else
      {:halt, conn} ->
        conn

      {:error, :bearer_missing} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, ~s({"error":"Authorization header with Bearer token required"}))

      {:error, :field_missing, field} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, ~s({"error":"Missing required field: #{field}"}))

      {:error, :pki_unavailable} ->
        Logger.warning("[EnrollmentHandler] PKI.State not running")
        service_unavailable(conn, "PKI service unavailable")

      {:error, %Error{code: code}}
      when code in [
             :token_not_found,
             :token_expired,
             :token_node_mismatch,
             :token_already_consumed
           ] ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, ~s({"error":"Token invalid or not authorized for this node"}))

      {:error, %Error{code: :enrollment_service_unavailable}} ->
        service_unavailable(conn, "enrollment service unavailable")

      {:error, %Error{code: code}} when code in [:invalid_csr] ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(422, ~s({"error":"CSR validation failed"}))

      {:error, %Error{}} ->
        service_unavailable(conn, "certificate issuance failed")

      {:error, _other} ->
        service_unavailable(conn, "internal error")
    end
  end

  # ── Auth ──────────────────────────────────────────────────────────────────────

  defp extract_bearer(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] when byte_size(token) > 0 ->
        {:ok, conn, token}

      _other ->
        {:error, :bearer_missing}
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

  # ── Enrollment token consumption ─────────────────────────────────────────────

  defp consume_token(token, node_id) do
    if Process.whereis(EnrollmentToken) do
      try do
        EnrollmentToken.consume(token, node_id)
      catch
        :exit, _reason ->
          {:error,
           Error.new(:enrollment_service_unavailable, "enrollment service is unavailable")}
      end
    else
      {:error, Error.new(:enrollment_service_unavailable, "enrollment service is unavailable")}
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
