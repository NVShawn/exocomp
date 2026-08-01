# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.LiveView.RequireRole do
  @moduledoc """
  A Phoenix LiveView `on_mount` hook that enforces Mission Control role-based
  authorization on LiveView sessions.

  Attach this hook in the LiveView `use` block or at the router level:

  ```elixir
  # In the LiveView module
  on_mount {Exocomp.MissionControl.LiveView.RequireRole, :operate}

  # Or in the router using live_session
  live_session :operator_required,
    on_mount: [{Exocomp.MissionControl.LiveView.RequireRole, :operate}] do
    live "/clusters/:organization_id", ClusterLive
  end
  ```

  The hook reads `socket.assigns.current_operator` and the `organization_id`
  from `socket.assigns` or `params`. If authorization fails, the socket is
  redirected to `/` with a flash error and the mount is halted.

  This is a **presentation guard** that gives users a clean error rather than
  a crash. Context functions enforce authorization independently; removing or
  bypassing this hook does not bypass context-level checks.

  ## Arguments

  The second element of the `{module, arg}` on_mount tuple must be one of:
  - `:read` — requires viewer or higher.
  - `:operate` — requires operator or higher.
  - `:administer` — requires admin.

  ## Socket assigns

  The hook expects the following assigns to be set by the authentication hook
  that runs before it:

  - `:current_operator` — an `%Operator{}` struct, or `nil` if unauthenticated.
  - `:organization_id` — optionally pre-assigned from the parent live_session
    or set by a preceding `on_mount` hook.

  The `organization_id` is also sourced from `params["organization_id"]` when
  not present in assigns.
  """

  alias Exocomp.MissionControl.Authorization

  @doc """
  LiveView on_mount/4 callback.

  Returns `{:cont, socket}` when authorized or `{:halt, redirected_socket}`
  when denied.

  This function signature matches the Phoenix.LiveView `on_mount` contract.
  The `socket` type is left as `any()` to avoid a hard dependency on
  `Phoenix.LiveView` at compile time; callers running inside a Phoenix
  application will receive a `Phoenix.LiveView.Socket` struct.
  """
  @spec on_mount(
          action :: :read | :operate | :administer,
          params :: map(),
          session :: map(),
          socket :: any()
        ) :: {:cont, any()} | {:halt, any()}
  def on_mount(action, params, _session, socket) when action in [:read, :operate, :administer] do
    operator = get_in(socket.assigns, [:current_operator])
    organization_id = resolve_organization_id(socket.assigns, params)

    case Authorization.authorize(operator, organization_id, action) do
      :ok ->
        {:cont, socket}

      {:error, reason} ->
        # Redirect to root with an error flash. The put_flash/redirect calls
        # use the Phoenix.LiveView API which must be available at runtime.
        halted_socket =
          socket
          |> phoenix_put_flash(:error, forbidden_message(reason))
          |> phoenix_redirect(to: "/")

        {:halt, halted_socket}
    end
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  defp resolve_organization_id(assigns, params) do
    assigns[:organization_id] || params["organization_id"]
  end

  defp forbidden_message(:unauthenticated), do: "You must be signed in."
  defp forbidden_message(:cross_organization), do: "Access denied: organization mismatch."

  defp forbidden_message(:insufficient_role),
    do: "You do not have permission to perform this action."

  # Deferred dispatch to Phoenix.LiveView to avoid a hard compile-time dep.
  defp phoenix_put_flash(socket, kind, message) do
    apply(Phoenix.LiveView, :put_flash, [socket, kind, message])
  end

  defp phoenix_redirect(socket, opts) do
    apply(Phoenix.LiveView, :redirect, [socket, opts])
  end
end
