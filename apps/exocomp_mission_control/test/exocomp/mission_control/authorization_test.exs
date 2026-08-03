# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AuthorizationTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Authorization
  alias Exocomp.MissionControl.Authorization.ForbiddenError
  alias Exocomp.MissionControl.Identity.Operator

  @org_a "org-alpha"
  @org_b "org-beta"

  defp operator(org_id, role) do
    %Operator{sub: "sub-#{role}", organization_id: org_id, display_name: "Test", role: role}
  end

  # ── Role matrix: authorize/3 ─────────────────────────────────────────────────

  describe "authorize/3 — role matrix for :read" do
    test "viewer in same org can read" do
      assert :ok = Authorization.authorize(operator(@org_a, :viewer), @org_a, :read)
    end

    test "operator in same org can read" do
      assert :ok = Authorization.authorize(operator(@org_a, :operator), @org_a, :read)
    end

    test "admin in same org can read" do
      assert :ok = Authorization.authorize(operator(@org_a, :admin), @org_a, :read)
    end
  end

  describe "authorize/3 — role matrix for :operate" do
    test "viewer in same org cannot operate" do
      assert {:error, :insufficient_role} =
               Authorization.authorize(operator(@org_a, :viewer), @org_a, :operate)
    end

    test "operator in same org can operate" do
      assert :ok = Authorization.authorize(operator(@org_a, :operator), @org_a, :operate)
    end

    test "admin in same org can operate" do
      assert :ok = Authorization.authorize(operator(@org_a, :admin), @org_a, :operate)
    end
  end

  describe "authorize/3 — role matrix for :administer" do
    test "viewer in same org cannot administer" do
      assert {:error, :insufficient_role} =
               Authorization.authorize(operator(@org_a, :viewer), @org_a, :administer)
    end

    test "operator in same org cannot administer" do
      assert {:error, :insufficient_role} =
               Authorization.authorize(operator(@org_a, :operator), @org_a, :administer)
    end

    test "admin in same org can administer" do
      assert :ok = Authorization.authorize(operator(@org_a, :admin), @org_a, :administer)
    end
  end

  # ── Cross-organization: fail closed ─────────────────────────────────────────

  describe "authorize/3 — cross-organization isolation" do
    test "viewer from org_a cannot read org_b resources" do
      assert {:error, :cross_organization} =
               Authorization.authorize(operator(@org_a, :viewer), @org_b, :read)
    end

    test "operator from org_a cannot operate on org_b resources" do
      assert {:error, :cross_organization} =
               Authorization.authorize(operator(@org_a, :operator), @org_b, :operate)
    end

    test "admin from org_a cannot administer org_b" do
      assert {:error, :cross_organization} =
               Authorization.authorize(operator(@org_a, :admin), @org_b, :administer)
    end

    test "admin from org_a cannot even read org_b resources" do
      assert {:error, :cross_organization} =
               Authorization.authorize(operator(@org_a, :admin), @org_b, :read)
    end

    test "cross_organization is returned before insufficient_role is checked" do
      # viewer cross-org: the cross_organization error takes precedence.
      assert {:error, :cross_organization} =
               Authorization.authorize(operator(@org_a, :viewer), @org_b, :administer)
    end
  end

  # ── Unauthenticated ──────────────────────────────────────────────────────────

  describe "authorize/3 — unauthenticated" do
    test "nil operator is rejected with :unauthenticated" do
      assert {:error, :unauthenticated} =
               Authorization.authorize(nil, @org_a, :read)
    end

    test "non-operator value is rejected with :unauthenticated" do
      assert {:error, :unauthenticated} =
               Authorization.authorize("not-an-operator", @org_a, :read)
    end

    test "unauthenticated is returned for all actions" do
      for action <- [:read, :operate, :administer] do
        assert {:error, :unauthenticated} =
                 Authorization.authorize(nil, @org_a, action),
               "Expected :unauthenticated for action #{inspect(action)}"
      end
    end
  end

  # ── authorize!/3 ─────────────────────────────────────────────────────────────

  describe "authorize!/3" do
    test "returns :ok when authorized" do
      assert :ok = Authorization.authorize!(operator(@org_a, :admin), @org_a, :administer)
    end

    test "raises ForbiddenError on insufficient_role" do
      assert_raise ForbiddenError, fn ->
        Authorization.authorize!(operator(@org_a, :viewer), @org_a, :operate)
      end
    end

    test "ForbiddenError carries the reason and action" do
      error =
        assert_raise ForbiddenError, fn ->
          Authorization.authorize!(operator(@org_a, :operator), @org_a, :administer)
        end

      assert error.reason == :insufficient_role
      assert error.action == :administer
      assert error.message =~ "administer"
    end

    test "raises ForbiddenError on cross_organization" do
      error =
        assert_raise ForbiddenError, fn ->
          Authorization.authorize!(operator(@org_a, :admin), @org_b, :read)
        end

      assert error.reason == :cross_organization
    end

    test "raises ForbiddenError on unauthenticated" do
      error =
        assert_raise ForbiddenError, fn ->
          Authorization.authorize!(nil, @org_a, :read)
        end

      assert error.reason == :unauthenticated
    end
  end

  # ── Convenience predicates ───────────────────────────────────────────────────

  describe "can_read?/2" do
    test "returns true for viewer in same org" do
      assert Authorization.can_read?(operator(@org_a, :viewer), @org_a)
    end

    test "returns true for admin in same org" do
      assert Authorization.can_read?(operator(@org_a, :admin), @org_a)
    end

    test "returns false for nil operator" do
      refute Authorization.can_read?(nil, @org_a)
    end

    test "returns false for viewer in different org" do
      refute Authorization.can_read?(operator(@org_a, :viewer), @org_b)
    end
  end

  describe "can_operate?/2" do
    test "returns false for viewer" do
      refute Authorization.can_operate?(operator(@org_a, :viewer), @org_a)
    end

    test "returns true for operator" do
      assert Authorization.can_operate?(operator(@org_a, :operator), @org_a)
    end

    test "returns true for admin" do
      assert Authorization.can_operate?(operator(@org_a, :admin), @org_a)
    end

    test "returns false for cross-org operator" do
      refute Authorization.can_operate?(operator(@org_a, :operator), @org_b)
    end
  end

  describe "can_administer?/2" do
    test "returns false for viewer" do
      refute Authorization.can_administer?(operator(@org_a, :viewer), @org_a)
    end

    test "returns false for operator" do
      refute Authorization.can_administer?(operator(@org_a, :operator), @org_a)
    end

    test "returns true for admin" do
      assert Authorization.can_administer?(operator(@org_a, :admin), @org_a)
    end

    test "returns false for cross-org admin" do
      refute Authorization.can_administer?(operator(@org_a, :admin), @org_b)
    end
  end

  # ── Complete role × action × org matrix ─────────────────────────────────────

  describe "full role × action × organization matrix" do
    @matrix [
      # {role, action, same_org?, expected}
      # Same organization
      {:viewer, :read, true, :ok},
      {:viewer, :operate, true, {:error, :insufficient_role}},
      {:viewer, :administer, true, {:error, :insufficient_role}},
      {:operator, :read, true, :ok},
      {:operator, :operate, true, :ok},
      {:operator, :administer, true, {:error, :insufficient_role}},
      {:admin, :read, true, :ok},
      {:admin, :operate, true, :ok},
      {:admin, :administer, true, :ok},
      # Cross organization (all should fail closed with :cross_organization)
      {:viewer, :read, false, {:error, :cross_organization}},
      {:viewer, :operate, false, {:error, :cross_organization}},
      {:viewer, :administer, false, {:error, :cross_organization}},
      {:operator, :read, false, {:error, :cross_organization}},
      {:operator, :operate, false, {:error, :cross_organization}},
      {:operator, :administer, false, {:error, :cross_organization}},
      {:admin, :read, false, {:error, :cross_organization}},
      {:admin, :operate, false, {:error, :cross_organization}},
      {:admin, :administer, false, {:error, :cross_organization}}
    ]

    for {role, action, same_org?, expected} <- @matrix do
      test "#{role} #{action} same_org=#{same_org?} → #{inspect(expected)}" do
        op = operator(@org_a, unquote(role))
        target_org = if unquote(same_org?), do: @org_a, else: @org_b
        assert unquote(expected) == Authorization.authorize(op, target_org, unquote(action))
      end
    end
  end
end
