# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Plug.RequireRoleTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  alias Exocomp.MissionControl.Plug.RequireRole
  alias Exocomp.MissionControl.Identity.Operator

  @org_a "org-alpha"
  @org_b "org-beta"

  defp operator(org_id, role) do
    %Operator{sub: "sub-#{role}", organization_id: org_id, role: role}
  end

  defp base_conn do
    conn(:get, "/")
  end

  defp conn_with_operator(op, org_id \\ nil) do
    conn = base_conn() |> assign(:current_operator, op)

    if org_id do
      assign(conn, :organization_id, org_id)
    else
      conn
    end
  end

  # ── init/1 ───────────────────────────────────────────────────────────────────

  describe "init/1" do
    test "accepts valid actions" do
      for action <- [:read, :operate, :administer] do
        assert %{action: ^action} = RequireRole.init(action: action)
      end
    end

    test "raises on invalid action" do
      assert_raise ArgumentError, fn -> RequireRole.init(action: :unknown) end
    end

    test "raises when :action is missing" do
      assert_raise KeyError, fn -> RequireRole.init([]) end
    end

    test "defaults organization_id_key to :organization_id" do
      opts = RequireRole.init(action: :read)
      assert opts.organization_id_key == :organization_id
    end

    test "accepts custom organization_id_key" do
      opts = RequireRole.init(action: :read, organization_id_key: :org_id)
      assert opts.organization_id_key == :org_id
    end
  end

  # ── Allowed requests ─────────────────────────────────────────────────────────

  describe "call/2 — allowed" do
    test "viewer can read in same org (org_id from assigns)" do
      conn = conn_with_operator(operator(@org_a, :viewer), @org_a)
      opts = RequireRole.init(action: :read)
      result = RequireRole.call(conn, opts)

      refute result.halted
    end

    test "operator can operate in same org" do
      conn = conn_with_operator(operator(@org_a, :operator), @org_a)
      opts = RequireRole.init(action: :operate)
      result = RequireRole.call(conn, opts)

      refute result.halted
    end

    test "admin can administer in same org" do
      conn = conn_with_operator(operator(@org_a, :admin), @org_a)
      opts = RequireRole.init(action: :administer)
      result = RequireRole.call(conn, opts)

      refute result.halted
    end

    test "resolves org_id from operator when assigns and path_params are absent" do
      conn = conn_with_operator(operator(@org_a, :admin))
      opts = RequireRole.init(action: :administer)
      result = RequireRole.call(conn, opts)

      refute result.halted
    end

    test "resolves org_id from path_params (string key)" do
      op = operator(@org_a, :operator)

      conn =
        base_conn()
        |> assign(:current_operator, op)
        |> Map.put(:path_params, %{"organization_id" => @org_a})

      opts = RequireRole.init(action: :operate)
      result = RequireRole.call(conn, opts)

      refute result.halted
    end
  end

  # ── Denied requests ──────────────────────────────────────────────────────────

  describe "call/2 — denied" do
    test "viewer is denied :operate" do
      conn = conn_with_operator(operator(@org_a, :viewer), @org_a)
      opts = RequireRole.init(action: :operate)
      result = RequireRole.call(conn, opts)

      assert result.halted
      assert result.status == 403
    end

    test "operator is denied :administer" do
      conn = conn_with_operator(operator(@org_a, :operator), @org_a)
      opts = RequireRole.init(action: :administer)
      result = RequireRole.call(conn, opts)

      assert result.halted
      assert result.status == 403
    end

    test "response body contains JSON error" do
      conn = conn_with_operator(operator(@org_a, :viewer), @org_a)
      opts = RequireRole.init(action: :operate)
      result = RequireRole.call(conn, opts)

      decoded = Jason.decode!(result.resp_body)
      assert decoded["error"] == "forbidden"
      assert decoded["reason"] == "insufficient_role"
    end

    test "unauthenticated (nil operator) is denied" do
      conn = conn_with_operator(nil, @org_a)
      opts = RequireRole.init(action: :read)
      result = RequireRole.call(conn, opts)

      assert result.halted
      assert result.status == 403

      decoded = Jason.decode!(result.resp_body)
      assert decoded["reason"] == "unauthenticated"
    end

    test "cross-org admin is denied" do
      conn = conn_with_operator(operator(@org_a, :admin), @org_b)
      opts = RequireRole.init(action: :read)
      result = RequireRole.call(conn, opts)

      assert result.halted
      assert result.status == 403

      decoded = Jason.decode!(result.resp_body)
      assert decoded["reason"] == "cross_organization"
    end
  end
end
