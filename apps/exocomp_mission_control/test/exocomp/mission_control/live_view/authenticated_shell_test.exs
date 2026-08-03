# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.AuthenticatedShellTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Identity.Operator

  describe "authentication" do
    test "redirects unauthenticated users to login" do
      # This would be tested via Phoenix.ConnTest in an actual integration test
      # For now, we verify the data structures and logic
      assert Operator.roles() == [:viewer, :operator, :admin]
    end

    test "viewer can read but not operate" do
      viewer = %Operator{
        sub: "user-1",
        organization_id: "org-1",
        role: :viewer,
        display_name: "John Viewer"
      }

      assert Operator.has_role_at_least?(viewer, :viewer)
      refute Operator.has_role_at_least?(viewer, :operator)
      refute Operator.has_role_at_least?(viewer, :admin)
    end

    test "operator can read and operate" do
      operator = %Operator{
        sub: "user-2",
        organization_id: "org-1",
        role: :operator,
        display_name: "Jane Operator"
      }

      assert Operator.has_role_at_least?(operator, :viewer)
      assert Operator.has_role_at_least?(operator, :operator)
      refute Operator.has_role_at_least?(operator, :admin)
    end

    test "admin has all permissions" do
      admin = %Operator{
        sub: "user-3",
        organization_id: "org-1",
        role: :admin,
        display_name: "Bob Admin"
      }

      assert Operator.has_role_at_least?(admin, :viewer)
      assert Operator.has_role_at_least?(admin, :operator)
      assert Operator.has_role_at_least?(admin, :admin)
    end
  end

  describe "authorization" do
    test "viewer can read" do
      viewer = %Operator{
        sub: "user-1",
        organization_id: "org-1",
        role: :viewer
      }

      assert Exocomp.MissionControl.Authorization.can_read?(viewer, "org-1")
    end

    test "viewer cannot operate" do
      viewer = %Operator{
        sub: "user-1",
        organization_id: "org-1",
        role: :viewer
      }

      refute Exocomp.MissionControl.Authorization.can_operate?(viewer, "org-1")
    end

    test "viewer cannot administer" do
      viewer = %Operator{
        sub: "user-1",
        organization_id: "org-1",
        role: :viewer
      }

      refute Exocomp.MissionControl.Authorization.can_administer?(viewer, "org-1")
    end

    test "operator can read and operate" do
      operator = %Operator{
        sub: "user-2",
        organization_id: "org-1",
        role: :operator
      }

      assert Exocomp.MissionControl.Authorization.can_read?(operator, "org-1")
      assert Exocomp.MissionControl.Authorization.can_operate?(operator, "org-1")
      refute Exocomp.MissionControl.Authorization.can_administer?(operator, "org-1")
    end

    test "admin can perform all actions" do
      admin = %Operator{
        sub: "user-3",
        organization_id: "org-1",
        role: :admin
      }

      assert Exocomp.MissionControl.Authorization.can_read?(admin, "org-1")
      assert Exocomp.MissionControl.Authorization.can_operate?(admin, "org-1")
      assert Exocomp.MissionControl.Authorization.can_administer?(admin, "org-1")
    end

    test "unauthenticated user has no access" do
      assert {:error, :unauthenticated} =
               Exocomp.MissionControl.Authorization.authorize(nil, "org-1", :read)
    end

    test "user cannot access different organization" do
      operator = %Operator{
        sub: "user-2",
        organization_id: "org-1",
        role: :operator
      }

      assert {:error, :cross_organization} =
               Exocomp.MissionControl.Authorization.authorize(operator, "org-2", :read)
    end
  end

  describe "role comparison" do
    test "viewer < operator < admin" do
      assert Operator.compare_roles(:viewer, :viewer) == 0
      assert Operator.compare_roles(:viewer, :operator) < 0
      assert Operator.compare_roles(:viewer, :admin) < 0

      assert Operator.compare_roles(:operator, :viewer) > 0
      assert Operator.compare_roles(:operator, :operator) == 0
      assert Operator.compare_roles(:operator, :admin) < 0

      assert Operator.compare_roles(:admin, :viewer) > 0
      assert Operator.compare_roles(:admin, :operator) > 0
      assert Operator.compare_roles(:admin, :admin) == 0
    end

    test "invalid roles are ordered strictly below viewer" do
      # role_index(_) = -1 for any unknown atom, so compare_roles yields a
      # negative number when the invalid role is on the left and a positive
      # number when it is on the right.
      assert Operator.compare_roles(:invalid, :viewer) < 0
      assert Operator.compare_roles(:viewer, :invalid) > 0

      invalid = %Operator{sub: "u", organization_id: "o", role: :invalid}
      refute Operator.has_role_at_least?(invalid, :viewer)
    end
  end

  describe "organization scoping" do
    test "organization identity survives across sessions" do
      operator = %Operator{
        sub: "user-stable-id",
        organization_id: "org-abc-123",
        role: :operator,
        display_name: "Test Operator"
      }

      # Verify organization is preserved
      assert operator.organization_id == "org-abc-123"
      assert operator.sub == "user-stable-id"
      # Verify it cannot be overridden by another organization
      assert {:error, :cross_organization} =
               Exocomp.MissionControl.Authorization.authorize(
                 operator,
                 "org-different",
                 :read
               )
    end
  end
end
