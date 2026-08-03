# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Coordinator.Handlers.ClusterInvitationHandler do
  @moduledoc """
  Admin-only HTTP endpoint for issuing cluster invitations.

  Authentication is intentionally supplied by the host application's OIDC
  middleware. The middleware must assign a user context containing
  `organization_id` and `role`; this handler performs the authorization check
  itself so the endpoint cannot rely on UI visibility.

  ## Endpoint

      POST /api/v1/cluster-invitations
      Content-Type: application/json
      {"cluster_name":"production","labels":{"region":"us-east"}}

  The response contains the invitation plaintext once under `token`. It is
  never passed to the store's audit or logging paths.
  """

  @behaviour Plug

  import Plug.Conn

  alias Exocomp.Coordinator.{ClusterInvitation, ClusterInvitations, Error}

  @max_body_bytes 65_536

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    with {:ok, auth} <- authenticate(conn, opts),
         {:ok, conn, params} <- parse_json_body(conn),
         {:ok, attrs} <- invitation_attrs(params, auth.organization_id),
         {:ok, invitation, token} <- create(attrs, opts) do
      response =
        invitation
        |> ClusterInvitation.public()
        |> Map.put("token", token)

      json_response(conn, 201, response)
    else
      {:halt, conn} ->
        conn

      {:error, :unauthenticated} ->
        error_response(conn, 401, "authentication required")

      {:error, :forbidden} ->
        error_response(conn, 403, "admin role required")

      {:error, :organization_mismatch} ->
        error_response(conn, 403, "organization is not authorized")

      {:error, :invalid_body} ->
        error_response(conn, 400, "invalid JSON body")

      {:error, :body_too_large} ->
        error_response(conn, 413, "request body too large")

      {:error, :body_unreadable} ->
        error_response(conn, 400, "failed to read request body")

      {:error, %Error{code: :duplicate_cluster_name}} ->
        error_response(conn, 409, "cluster name already exists in organization")

      {:error, %Error{} = error}
      when error.code in [
             :invalid_organization_id,
             :invalid_cluster_name,
             :invalid_cluster_labels,
             :invalid_invitation_lifetime,
             :invalid_cluster,
             :invalid_cluster_invitation
           ] ->
        error_response(conn, 400, error.message)

      {:error, %Error{code: code}}
      when code in [
             :invitation_storage_error,
             :invitation_storage_unavailable,
             :invitation_storage_corrupt,
             :randomness_unavailable
           ] ->
        error_response(conn, 503, "invitation service unavailable")

      {:error, _other} ->
        error_response(conn, 503, "invitation service unavailable")
    end
  end

  defp create(attrs, opts) do
    try do
      ClusterInvitations.create(attrs, server_opts(opts))
    catch
      :exit, _reason ->
        {:error, Error.new(:invitation_storage_unavailable, "invitation service unavailable")}
    end
  end

  defp server_opts(opts) do
    [
      server:
        Keyword.get(
          opts,
          :server,
          Keyword.get(opts, :store, Keyword.get(opts, :cluster_invitation_store))
        )
    ]
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  end

  # ---------------------------------------------------------------------------
  # Authentication and authorization
  # ---------------------------------------------------------------------------

  defp authenticate(conn, opts) do
    case Keyword.get(opts, :authenticator) do
      authenticator when is_function(authenticator, 1) ->
        authenticator.(conn) |> normalize_authentication()

      _ ->
        opts
        |> Keyword.get(:auth_context)
        |> case do
          context when is_map(context) -> normalize_authentication({:ok, context})
          _ -> normalize_authentication({:ok, assigned_auth_context(conn)})
        end
    end
  rescue
    _error -> {:error, :unauthenticated}
  end

  defp normalize_authentication({:ok, context}) when is_map(context) do
    organization_id = value(context, :organization_id, :org_id)
    role = value(context, :role)

    cond do
      not valid_string?(organization_id) -> {:error, :unauthenticated}
      normalize_role(role) != :admin -> {:error, :forbidden}
      true -> {:ok, %{organization_id: String.trim(organization_id)}}
    end
  end

  defp normalize_authentication(context) when is_map(context),
    do: normalize_authentication({:ok, context})

  defp normalize_authentication(:ok), do: {:error, :unauthenticated}
  defp normalize_authentication({:error, :forbidden}), do: {:error, :forbidden}
  defp normalize_authentication(_), do: {:error, :unauthenticated}

  defp assigned_auth_context(conn) do
    assigns = conn.assigns
    private = conn.private

    Enum.find_value(
      [
        Map.get(assigns, :current_user),
        Map.get(assigns, :user),
        Map.get(assigns, :actor),
        Map.get(assigns, :auth),
        Map.get(private, :current_user),
        Map.get(private, :user),
        assigns
      ],
      %{},
      fn
        context when is_map(context) ->
          if value(context, :organization_id, :org_id) != nil and value(context, :role) != nil,
            do: context,
            else: nil

        _ ->
          nil
      end
    )
  end

  defp normalize_role(:admin), do: :admin
  defp normalize_role("admin"), do: :admin
  defp normalize_role(_role), do: :other

  defp value(map, key, alternate \\ nil) do
    Map.get(
      map,
      key,
      Map.get(
        map,
        Atom.to_string(key),
        Map.get(map, alternate, alternate && Atom.to_string(alternate))
      )
    )
  end

  defp valid_string?(value), do: is_binary(value) and String.trim(value) != ""

  # ---------------------------------------------------------------------------
  # Body and response helpers
  # ---------------------------------------------------------------------------

  defp parse_json_body(conn) do
    case read_body(conn, length: @max_body_bytes) do
      {:ok, body, conn} ->
        case Jason.decode(body) do
          {:ok, params} when is_map(params) -> {:ok, conn, params}
          _ -> {:error, :invalid_body}
        end

      {:more, _partial, _conn} ->
        {:error, :body_too_large}

      {:error, _reason} ->
        {:error, :body_unreadable}
    end
  end

  defp invitation_attrs(params, organization_id) do
    body_organization_id = Map.get(params, "organization_id")

    cond do
      is_binary(body_organization_id) and String.trim(body_organization_id) != organization_id ->
        {:error, :organization_mismatch}

      body_organization_id != nil and not is_binary(body_organization_id) ->
        {:error, :organization_mismatch}

      true ->
        {:ok,
         %{
           organization_id: organization_id,
           name: Map.get(params, "cluster_name", Map.get(params, "name")),
           labels: Map.get(params, "labels", %{}),
           expires_in: Map.get(params, "expires_in")
         }
         |> drop_nil(:expires_in)}
    end
  end

  defp drop_nil(map, key) do
    if is_nil(Map.get(map, key)), do: Map.delete(map, key), else: map
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
