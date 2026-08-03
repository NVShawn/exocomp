# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Identity.RoleBindingTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Identity.RoleBinding

  @org_a "org-001"
  @org_b "org-002"
  @sub_a "sub-alice"
  @sub_b "sub-bob"

  defp binding(org_id, sub, role) do
    %RoleBinding{organization_id: org_id, sub: sub, role: role}
  end

  describe "matches?/3" do
    test "returns true when org and sub both match" do
      b = binding(@org_a, @sub_a, :operator)
      assert RoleBinding.matches?(b, @org_a, @sub_a)
    end

    test "returns false when organization_id differs" do
      b = binding(@org_a, @sub_a, :admin)
      refute RoleBinding.matches?(b, @org_b, @sub_a)
    end

    test "returns false when sub differs" do
      b = binding(@org_a, @sub_a, :viewer)
      refute RoleBinding.matches?(b, @org_a, @sub_b)
    end

    test "returns false when both org and sub differ" do
      b = binding(@org_a, @sub_a, :admin)
      refute RoleBinding.matches?(b, @org_b, @sub_b)
    end

    test "cross-organization binding is never valid for the other org" do
      # A binding in org_a must NOT match a check for org_b, even with the same sub.
      b = binding(@org_a, @sub_a, :admin)
      refute RoleBinding.matches?(b, @org_b, @sub_a)
    end
  end
end
