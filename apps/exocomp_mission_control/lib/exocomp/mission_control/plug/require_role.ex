# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Plug.RequireRole do
  @moduledoc """
  A Plug that enforces Mission Control role-based authorization on HTTP
  requests.

  This plug must be placed **after** an authentication plug that stores the
  current operator in `conn.assigns.current_operator`. It reads the resolved
  operator from `conn.assigns` and calls the context-level authorization
  function, which is the authoritative enforcement boundary.

  Removing or bypassing this plug does not bypass context authorization:
  every context function independently checks the operator's role.

  ## Options

  - `:action` (required) — the action to authorize: `:read`, `:operate`, or
    `:administer`.
  - `:organization_id_key` — the key (atom) used to look up the
    `organization_id` from `conn.path_params` or `conn.assigns`. Defaults to
    `:organization_id`. When neither path params nor assigns contains the key,
    the plug falls back to `conn.assigns.current_operator.organization_id`.

  ## Failure behaviour

  On denial the plug halts the connection and sends a `403 Forbidden` JSON
  response. The response body is:

  ```json
  {"error": "forbidden", "reason": "<deny_reason>"}
  ```

  ## Example

  ```elixir
  plug Exocomp.MissionControl.Plug.RequireRole, action: :operate
  plug Exocomp.MissionControl.Plug.RequireRole, action: :administer, organization_id_key: :org_id
  ```
  """

  @behaviour Plug

  import Plug.Conn

  alias Exocomp.MissionControl.Authorization

  @impl Plug
  def init(opts) do
    action = Keyword.fetch!(opts, :action)

    unless action in [:read, :operate, :administer] do
      raise ArgumentError,
            "RequireRole :action must be :read, :operate, or :administer, got: #{inspect(action)}"
    end

    %{
      action: action,
      organization_id_key: Keyword.get(opts, :organization_id_key, :organization_id)
    }
  end

  @impl Plug
  def call(conn, %{action: action, organization_id_key: org_key}) do
    operator = conn.assigns[:current_operator]
    organization_id = resolve_organization_id(conn, org_key, operator)

    case Authorization.authorize(operator, organization_id, action) do
      :ok ->
        conn

      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{error: "forbidden", reason: to_string(reason)}))
        |> halt()
    end
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  defp resolve_organization_id(conn, org_key, operator) do
    # Prefer path params, then assigns, then fall back to operator's own org.
    path_params = Map.get(conn, :path_params, %{})
    key_str = to_string(org_key)

    cond do
      Map.has_key?(path_params, key_str) ->
        path_params[key_str]

      Map.has_key?(path_params, org_key) ->
        path_params[org_key]

      Map.has_key?(conn.assigns, org_key) ->
        conn.assigns[org_key]

      operator != nil ->
        operator.organization_id

      true ->
        nil
    end
  end
end
