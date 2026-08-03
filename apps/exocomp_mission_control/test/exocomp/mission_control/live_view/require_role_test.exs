# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.LiveView.RequireRoleTest do
  @moduledoc """
  Focused tests for the `RequireRole` LiveView on_mount hook.

  These tests exercise the hook's authentication and role-gating logic
  without booting the full Phoenix endpoint. They construct a
  `Phoenix.LiveView.Socket` in isolation and verify that:

  * `:authenticate` reads operator identity from the server-side session and
    refuses to accept an organization or role from client params.
  * `:read`, `:operate`, `:administer` role gates halt the mount with a
    redirect to `/forbidden` for unauthorized operators and cont for
    authorized ones.
  * The unauthenticated case redirects to `/auth/login`.
  * The organization identity is sourced from the operator assigned by
    `:authenticate`, and is NOT overridable by `params["organization_id"]`
    when the operator disagrees.
  """
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Identity.Operator
  alias Exocomp.MissionControl.LiveView.RequireRole
  alias Phoenix.LiveView.Socket

  # Construct a minimal, non-connected LiveView.Socket for hook testing.
  # The Phoenix.LiveView struct fields we depend on are `assigns`, `redirected`,
  # and `endpoint`. Endpoint is left as nil since we do not exercise any
  # transport paths.
  defp empty_socket do
    %Socket{
      endpoint: Exocomp.MissionControl.Endpoint,
      assigns: %{__changed__: %{}, flash: %{}}
    }
  end

  defp session_for(%Operator{} = op) do
    %{
      "operator_id" => op.sub,
      "operator_role" => Atom.to_string(op.role),
      "organization_id" => op.organization_id,
      "operator_name" => op.display_name
    }
  end

  describe ":authenticate" do
    test "halts and redirects to /auth/login when session lacks operator" do
      {:halt, socket} = RequireRole.on_mount(:authenticate, %{}, %{}, empty_socket())
      assert socket.redirected == {:redirect, %{to: "/auth/login", status: 302}}
    end

    test "halts and redirects when session has partial operator data" do
      partial = %{"operator_id" => "user-1"}
      {:halt, socket} = RequireRole.on_mount(:authenticate, %{}, partial, empty_socket())
      assert socket.redirected == {:redirect, %{to: "/auth/login", status: 302}}
    end

    test "conts with :current_operator assigned when session has full operator data" do
      op = %Operator{
        sub: "user-1",
        organization_id: "org-1",
        role: :viewer,
        display_name: "Test Viewer"
      }

      {:cont, socket} =
        RequireRole.on_mount(:authenticate, %{}, session_for(op), empty_socket())

      assert socket.assigns.current_operator == op
    end

    test "rejects unknown role strings and treats session as unauthenticated" do
      bad = %{
        "operator_id" => "user-1",
        "operator_role" => "impersonator",
        "organization_id" => "org-1"
      }

      {:halt, socket} = RequireRole.on_mount(:authenticate, %{}, bad, empty_socket())
      assert socket.redirected == {:redirect, %{to: "/auth/login", status: 302}}
    end
  end

  describe ":read gate" do
    test "conts for viewer in their own organization" do
      op = %Operator{sub: "u", organization_id: "org-1", role: :viewer}
      socket = %{empty_socket() | assigns: Map.put(empty_socket().assigns, :current_operator, op)}

      {:cont, ^socket} = RequireRole.on_mount(:read, %{}, %{}, socket)
    end

    test "conts for operator and admin" do
      for role <- [:operator, :admin] do
        op = %Operator{sub: "u", organization_id: "org-1", role: role}

        socket = %{
          empty_socket()
          | assigns: Map.put(empty_socket().assigns, :current_operator, op)
        }

        {:cont, _} = RequireRole.on_mount(:read, %{}, %{}, socket)
      end
    end

    test "halts and redirects unauthenticated to /auth/login" do
      {:halt, socket} = RequireRole.on_mount(:read, %{}, %{}, empty_socket())
      assert socket.redirected == {:redirect, %{to: "/auth/login", status: 302}}
    end
  end

  describe ":operate gate" do
    test "halts viewer with a /forbidden redirect" do
      op = %Operator{sub: "u", organization_id: "org-1", role: :viewer}
      socket = %{empty_socket() | assigns: Map.put(empty_socket().assigns, :current_operator, op)}

      {:halt, socket} = RequireRole.on_mount(:operate, %{}, %{}, socket)
      assert socket.redirected == {:redirect, %{to: "/forbidden", status: 302}}
    end

    test "conts for operator and admin" do
      for role <- [:operator, :admin] do
        op = %Operator{sub: "u", organization_id: "org-1", role: role}

        socket = %{
          empty_socket()
          | assigns: Map.put(empty_socket().assigns, :current_operator, op)
        }

        {:cont, _} = RequireRole.on_mount(:operate, %{}, %{}, socket)
      end
    end
  end

  describe ":administer gate" do
    test "halts viewer and operator with /forbidden" do
      for role <- [:viewer, :operator] do
        op = %Operator{sub: "u", organization_id: "org-1", role: role}

        socket = %{
          empty_socket()
          | assigns: Map.put(empty_socket().assigns, :current_operator, op)
        }

        {:halt, socket} = RequireRole.on_mount(:administer, %{}, %{}, socket)
        assert socket.redirected == {:redirect, %{to: "/forbidden", status: 302}}
      end
    end

    test "conts for admin" do
      op = %Operator{sub: "u", organization_id: "org-1", role: :admin}
      socket = %{empty_socket() | assigns: Map.put(empty_socket().assigns, :current_operator, op)}

      {:cont, _} = RequireRole.on_mount(:administer, %{}, %{}, socket)
    end
  end

  describe "client parameter isolation" do
    test "organization_id from params does not override operator identity" do
      # Operator belongs to org-a. A malicious client attempts to place org-b
      # in params. Authorization must still refuse cross-organization access.
      op = %Operator{sub: "u", organization_id: "org-a", role: :viewer}

      socket_no_org = %{
        empty_socket()
        | assigns: Map.put(empty_socket().assigns, :current_operator, op)
      }

      client_params = %{"organization_id" => "org-b"}

      # When socket assigns don't contain :organization_id, the params org is used,
      # so the guard exercises the cross_organization branch and denies.
      # Confirm this fails closed by hitting the params path directly.
      {:halt, halted} = RequireRole.on_mount(:read, client_params, %{}, socket_no_org)
      assert halted.redirected == {:redirect, %{to: "/forbidden", status: 302}}
    end
  end
end
