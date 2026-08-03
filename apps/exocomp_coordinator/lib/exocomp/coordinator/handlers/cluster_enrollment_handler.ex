# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Handlers.ClusterEnrollmentHandler do
  @moduledoc """
  HTTP handler for cluster enrollment from validated CSRs.

  Accepts a single-use cluster invitation issued by the coordinator operator,
  validates the presented CSR, issues a cluster leaf certificate bound to the
  invitation's organization and cluster identity, and returns the signed chain PEM.

  ## Endpoint

      POST /api/v1/clusters/enroll
      Content-Type: application/json
      {
        "organization_id": "<org-id>",
        "cluster_id": "<cluster-id>",
        "invitation": "<cinv_...>",
        "csr": "<PEM-encoded CSR>"
      }

  ## Response

      200 OK
      {
        "chain_pem": "<PEM-encoded leaf + intermediate chain>",
        "certificate": {"serial": "<serial>", "sha256": "<fingerprint>", ...}
      }

  ## Fail-closed behavior

  - Missing required body fields: 400
  - Invitation not found, expired, already consumed, or bound to different org/cluster: 401
  - Invalid CSR (bad format, wrong SPIFFE URI, prohibited key usage, etc.): 422
  - PKI or invitation service unavailable: 503
  - Certificate-metadata audit failure: 503

  The CSR is validated before the invitation is consumed. Consumption then atomically
  checks both organization and cluster binding. If signing fails after consumption,
  the invitation cannot be replayed; the cluster must obtain a new invitation.
  """

  @behaviour Plug

  import Plug.Conn

  require Logger

  alias Exocomp.Coordinator.{Audit, ClusterInvitationStore, Error}
  alias Exocomp.Coordinator.PKI.{ClusterIssuer, State}

  @max_body_bytes 65_536

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    with {:ok, conn, params} <- parse_json_body(conn),
         {:ok, organization_id} <- require_field(params, "organization_id"),
         {:ok, cluster_id} <- require_field(params, "cluster_id"),
         {:ok, invitation} <- require_field(params, "invitation"),
         {:ok, csr_pem} <- require_field(params, "csr"),
         {:ok, online_state} <- pki_online_state(opts),
         {:ok, csr} <- validate_csr(csr_pem, organization_id, cluster_id),
         {:ok, _consumed_invitation} <-
           consume_invitation(invitation, organization_id, cluster_id, opts),
         {:ok, chain_pem} <- issue_leaf(csr, organization_id, cluster_id, online_state),
         {:ok, certificate} <- ClusterIssuer.certificate_metadata(chain_pem),
         :ok <- persist_certificate_metadata(organization_id, cluster_id, certificate, opts) do
      json_response(conn, 200, %{"chain_pem" => chain_pem, "certificate" => certificate})
    else
      {:halt, conn} ->
        conn

      {:error, :field_missing, field} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, ~s({"error":"Missing required field: #{field}"}))

      {:error, :pki_unavailable} ->
        Logger.warning("[ClusterEnrollmentHandler] PKI.State not running")
        service_unavailable(conn, "PKI service unavailable")

      {:error, %Error{code: code}}
      when code in [
             :invalid_invitation_format,
             :invitation_not_found,
             :invitation_expired,
             :organization_mismatch,
             :cluster_mismatch,
             :invitation_already_consumed
           ] ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, ~s({"error":"Invitation invalid or not authorized for this cluster"}))

      {:error, %Error{code: :invitation_service_unavailable}} ->
        service_unavailable(conn, "invitation service unavailable")

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

  # ── Body parsing ─────────────────────────────────────────────────────────

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

  # ── PKI state lookup ──────────────────────────────────────────────────────

  defp pki_online_state(opts) do
    try do
      case State.status(Keyword.get(opts, :pki_state, State)) do
        %{healthy: true, online_state: path} when is_binary(path) -> {:ok, path}
        _other -> {:error, :pki_unavailable}
      end
    catch
      :exit, _reason -> {:error, :pki_unavailable}
    end
  end

  # ── Cluster invitation consumption ────────────────────────────────────────

  defp consume_invitation(invitation, organization_id, cluster_id, opts) do
    try do
      ClusterInvitationStore.consume(invitation, organization_id, cluster_id,
        server: Keyword.get(opts, :cluster_invitation_store, ClusterInvitationStore)
      )
    catch
      :exit, _reason ->
        {:error, Error.new(:invitation_service_unavailable, "invitation service is unavailable")}
    end
  end

  # ── Certificate issuance ─────────────────────────────────────────────────

  defp validate_csr(csr_pem, organization_id, cluster_id) do
    ClusterIssuer.validate_csr(csr_pem, organization_id, cluster_id)
  end

  defp issue_leaf(csr, organization_id, cluster_id, online_state) do
    ClusterIssuer.issue_leaf(csr, organization_id, cluster_id, online_state)
  end

  defp persist_certificate_metadata(organization_id, cluster_id, certificate, opts) do
    Audit.emit(
      :cluster_certificate_issued,
      %{
        organization_id: organization_id,
        cluster_id: cluster_id,
        certificate_serial: certificate.serial,
        certificate_sha256: certificate.sha256,
        certificate_not_after: certificate.not_after
      },
      server: Keyword.get(opts, :audit_server, Audit)
    )
  catch
    :exit, _reason ->
      {:error, Error.new(:audit_unavailable, "certificate metadata could not be persisted")}
  end

  # ── Response helpers ──────────────────────────────────────────────────────

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
