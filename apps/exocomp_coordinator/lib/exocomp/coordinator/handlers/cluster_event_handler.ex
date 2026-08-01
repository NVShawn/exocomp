# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Handlers.ClusterEventHandler do
  @moduledoc "HTTP boundary for authenticated cluster event delivery."

  @behaviour Plug

  import Plug.Conn

  alias Exocomp.Coordinator.{ClusterEventIngestor, ClusterIdentity, Error}

  @max_body_bytes 262_144

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    with {:ok, identity} <- authenticated_identity(conn, opts),
         {:ok, conn, body} <- read_json_body(conn),
         {:ok, envelope} <- decode_envelope(body),
         {:ok, result} <- ingest(envelope, identity, opts) do
      json_response(conn, 200, %{
        "acknowledged_sequence" => result.acknowledgement,
        "highest_contiguous_sequence" => result.highest_contiguous_sequence,
        "duplicate" => result.duplicate?,
        "gap" => result.gap?
      })
    else
      {:halt, conn} ->
        conn

      {:error, :no_client_certificate} ->
        error_response(conn, 401, "client certificate required")

      {:error, %Error{code: :invalid_cluster_certificate}} ->
        error_response(conn, 401, "authenticated cluster identity is invalid")

      {:error, %Error{code: code} = error}
      when code in [:event_id_conflict, :sequence_conflict] ->
        error_response(conn, 409, error.message)

      {:error, %Error{code: :event_persistence_failed} = error} ->
        error_response(conn, 503, error.message)

      {:error, %Error{} = error} ->
        error_response(conn, 400, error.message)

      {:error, _reason} ->
        error_response(conn, 400, "invalid event request")
    end
  end

  defp authenticated_identity(conn, opts) do
    case Keyword.get(opts, :identity) do
      nil ->
        case get_peer_data(conn) do
          %{ssl_cert: certificate} when is_binary(certificate) and byte_size(certificate) > 0 ->
            resolver = Keyword.get(opts, :identity_resolver, &ClusterIdentity.from_certificate/1)
            resolve_identity(resolver, certificate)

          _peer_data ->
            {:error, :no_client_certificate}
        end

      identity ->
        ClusterIdentity.new(identity)
    end
  end

  defp resolve_identity(resolver, certificate) when is_function(resolver, 1),
    do: normalize_identity_result(resolver.(certificate))

  defp resolve_identity({module, function}, certificate),
    do: normalize_identity_result(apply(module, function, [certificate]))

  defp resolve_identity(_resolver, _certificate),
    do: {:error, Error.new(:invalid_cluster_certificate, "identity resolver is invalid")}

  defp normalize_identity_result({:ok, identity}), do: ClusterIdentity.new(identity)
  defp normalize_identity_result(%ClusterIdentity{} = identity), do: {:ok, identity}
  defp normalize_identity_result({:error, _} = error), do: error

  defp normalize_identity_result(_other),
    do: {:error, Error.new(:invalid_cluster_certificate, "identity resolver rejected peer")}

  defp read_json_body(conn) do
    case read_body(conn, length: @max_body_bytes) do
      {:ok, body, conn} ->
        {:ok, conn, body}

      {:more, _partial, conn} ->
        {:halt, error_response(conn, 413, "event request body too large")}

      {:error, _reason} ->
        {:halt, error_response(conn, 400, "failed to read event request")}
    end
  end

  defp decode_envelope(body) do
    case Jason.decode(body) do
      {:ok, envelope} when is_map(envelope) -> {:ok, envelope}
      _other -> {:error, Error.new(:invalid_event_schema, "event body must be valid JSON")}
    end
  end

  defp ingest(envelope, identity, opts) do
    server = Keyword.get(opts, :ingestor, ClusterEventIngestor)
    ClusterEventIngestor.ingest(envelope, identity, server)
  end

  defp error_response(conn, status, message) do
    json_response(conn, status, %{"error" => message})
  end

  defp json_response(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
