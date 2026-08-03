# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.LiveView.NavigationTest do
  @moduledoc """
  End-to-end LiveView navigation tests exercising the authenticated shell for
  every role tier plus the unauthenticated case.

  The tests build a session cookie the same way the OIDC callback does, mount
  each protected LiveView, and verify:

  * unauthenticated requests are redirected to /auth/login,
  * viewers see Fleet and Incidents but not Conversations or Admin,
  * operators additionally see Conversations,
  * admins see the entire menu,
  * organization identity survives across page loads and is never sourced
    from the client params.
  """
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Plug.Conn

  @endpoint Exocomp.MissionControl.Endpoint

  alias Exocomp.MissionControl.Identity.Operator

  defp build_session_conn(%Operator{} = op) do
    build_conn()
    |> Plug.Test.init_test_session(%{
      "operator_id" => op.sub,
      "operator_role" => Atom.to_string(op.role),
      "organization_id" => op.organization_id,
      "operator_name" => op.display_name
    })
  end

  defp mint_operator(role, opts \\ []) do
    %Operator{
      sub: Keyword.get(opts, :sub, "user-#{System.unique_integer([:positive])}"),
      organization_id: Keyword.get(opts, :organization_id, "org-nav-test"),
      role: role,
      display_name: Keyword.get(opts, :display_name, "Nav Test Operator")
    }
  end

  describe "unauthenticated navigation" do
    test "GET / redirects to /auth/login" do
      conn = build_conn()
      assert {:error, {:redirect, %{to: "/auth/login"}}} = live(conn, "/")
    end

    test "GET /incidents redirects to /auth/login" do
      conn = build_conn()
      assert {:error, {:redirect, %{to: "/auth/login"}}} = live(conn, "/incidents")
    end

    test "GET /conversations redirects to /auth/login" do
      conn = build_conn()
      assert {:error, {:redirect, %{to: "/auth/login"}}} = live(conn, "/conversations")
    end

    test "GET /admin redirects to /auth/login" do
      conn = build_conn()
      assert {:error, {:redirect, %{to: "/auth/login"}}} = live(conn, "/admin")
    end
  end

  describe "viewer navigation" do
    setup do
      %{conn: build_session_conn(mint_operator(:viewer))}
    end

    test "sees Fleet and Incidents but not Conversations or Admin", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Fleet"
      assert html =~ "Incidents"
      refute html =~ ">Conversations<"
      refute html =~ ">Admin<"
    end

    test "can reach /incidents", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/incidents")
      assert html =~ "Incidents"
    end

    test "is redirected away from /conversations to /forbidden", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/forbidden"}}} = live(conn, "/conversations")
    end

    test "is redirected away from /admin to /forbidden", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/forbidden"}}} = live(conn, "/admin")
    end
  end

  describe "operator navigation" do
    setup do
      %{conn: build_session_conn(mint_operator(:operator))}
    end

    test "sees Fleet, Incidents, and Conversations but not Admin", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Fleet"
      assert html =~ "Incidents"
      assert html =~ "Conversations"
      refute html =~ ">Admin<"
    end

    test "can reach /conversations", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/conversations")
      assert html =~ "Conversations"
    end

    test "is redirected away from /admin", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/forbidden"}}} = live(conn, "/admin")
    end
  end

  describe "admin navigation" do
    setup do
      %{conn: build_session_conn(mint_operator(:admin))}
    end

    test "sees the full menu", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Fleet"
      assert html =~ "Incidents"
      assert html =~ "Conversations"
      assert html =~ "Admin"
    end

    test "can reach /admin", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/admin")
      assert html =~ "Administration"
    end
  end

  describe "organization context" do
    test "operator identity and organization ID are surfaced in the layout" do
      op = mint_operator(:operator, display_name: "Jane Op", organization_id: "org-alpha")
      conn = build_session_conn(op)

      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Jane Op"
      assert html =~ "org-alph"
    end

    test "role badge reflects the operator role" do
      for role <- [:viewer, :operator, :admin] do
        conn = build_session_conn(mint_operator(role))
        {:ok, _view, html} = live(conn, "/")
        assert html =~ Phoenix.Naming.humanize(Atom.to_string(role))
      end
    end

    test "organization identity is preserved across navigation" do
      op = mint_operator(:viewer, organization_id: "org-persist")
      conn = build_session_conn(op)

      {:ok, _view, html_dashboard} = live(conn, "/")
      {:ok, _view, html_incidents} = live(conn, "/incidents")

      assert html_dashboard =~ "org-pers"
      assert html_incidents =~ "org-pers"
    end

    test "an organization_id query param cannot override the trusted session identity" do
      op = mint_operator(:viewer, organization_id: "org-secure")
      conn = build_session_conn(op)

      {:ok, _view, html} = live(conn, "/?organization_id=org-evil")

      assert html =~ "org-secu"
      refute html =~ "org-evil"
    end
  end

  describe "accessibility landmarks" do
    setup do
      %{conn: build_session_conn(mint_operator(:viewer))}
    end

    test "renders main, banner, and contentinfo landmarks", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ ~s(role="main")
      assert html =~ ~s(role="banner")
      assert html =~ ~s(role="contentinfo")
      assert html =~ ~s(role="navigation")
    end

    test "renders the Skip to main content link for keyboard users", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Skip to main content"
      assert html =~ ~s(href="#main-content")
    end

    test "navigation and role badges expose aria-label attributes", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "aria-label"
    end
  end

  describe "layout content" do
    test "authenticated shell renders the Mission Control title and footer" do
      conn = build_session_conn(mint_operator(:viewer))
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Mission Control"
      assert html =~ "Logout"
      assert html =~ ~s(href="/auth/logout")
    end
  end
end
