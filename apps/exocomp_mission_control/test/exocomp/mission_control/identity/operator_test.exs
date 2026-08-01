# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Identity.OperatorTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Identity.Operator

  defp operator(role) do
    %Operator{sub: "sub-test", organization_id: "org-001", role: role}
  end

  describe "roles/0" do
    test "returns all roles in ascending privilege order" do
      assert Operator.roles() == [:viewer, :operator, :admin]
    end
  end

  describe "valid_role?/1" do
    test "returns true for :viewer" do
      assert Operator.valid_role?(:viewer)
    end

    test "returns true for :operator" do
      assert Operator.valid_role?(:operator)
    end

    test "returns true for :admin" do
      assert Operator.valid_role?(:admin)
    end

    test "returns false for unknown atoms" do
      refute Operator.valid_role?(:superuser)
      refute Operator.valid_role?(:root)
    end

    test "returns false for non-atoms" do
      refute Operator.valid_role?("admin")
      refute Operator.valid_role?(nil)
    end
  end

  describe "has_role_at_least?/2" do
    test "viewer has at least :viewer" do
      assert Operator.has_role_at_least?(operator(:viewer), :viewer)
    end

    test "viewer does not have at least :operator" do
      refute Operator.has_role_at_least?(operator(:viewer), :operator)
    end

    test "viewer does not have at least :admin" do
      refute Operator.has_role_at_least?(operator(:viewer), :admin)
    end

    test "operator has at least :viewer" do
      assert Operator.has_role_at_least?(operator(:operator), :viewer)
    end

    test "operator has at least :operator" do
      assert Operator.has_role_at_least?(operator(:operator), :operator)
    end

    test "operator does not have at least :admin" do
      refute Operator.has_role_at_least?(operator(:operator), :admin)
    end

    test "admin has at least :viewer" do
      assert Operator.has_role_at_least?(operator(:admin), :viewer)
    end

    test "admin has at least :operator" do
      assert Operator.has_role_at_least?(operator(:admin), :operator)
    end

    test "admin has at least :admin" do
      assert Operator.has_role_at_least?(operator(:admin), :admin)
    end
  end
end
