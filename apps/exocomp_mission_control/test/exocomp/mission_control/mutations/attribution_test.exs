# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Mutations.AttributionTest do
  use ExUnit.Case, async: true

  alias Exocomp.MissionControl.Identity.Operator
  alias Exocomp.MissionControl.Mutations.Attribution

  defp operator(role \\ :operator) do
    %Operator{
      sub: "sub-12345",
      organization_id: "org-001",
      display_name: "Alice Operator",
      role: role
    }
  end

  # ── build/2 ──────────────────────────────────────────────────────────────────

  describe "build/2" do
    test "copies sub from operator" do
      attr = Attribution.build(operator())
      assert attr.sub == "sub-12345"
    end

    test "copies display_name from operator" do
      attr = Attribution.build(operator())
      assert attr.display_name == "Alice Operator"
    end

    test "copies organization_id from operator" do
      attr = Attribution.build(operator())
      assert attr.organization_id == "org-001"
    end

    test "generates a unique correlation_id when none is provided" do
      attr1 = Attribution.build(operator())
      attr2 = Attribution.build(operator())

      assert String.starts_with?(attr1.correlation_id, "corr_")
      assert String.starts_with?(attr2.correlation_id, "corr_")
      assert attr1.correlation_id != attr2.correlation_id
    end

    test "uses the provided correlation_id when supplied" do
      attr = Attribution.build(operator(), "corr_fixed-id-001")
      assert attr.correlation_id == "corr_fixed-id-001"
    end

    test "records :at as a DateTime" do
      before = DateTime.utc_now()
      attr = Attribution.build(operator())
      after_ = DateTime.utc_now()

      assert DateTime.compare(attr.at, before) in [:gt, :eq]
      assert DateTime.compare(attr.at, after_) in [:lt, :eq]
    end

    test "works for viewer, operator, and admin roles" do
      for role <- [:viewer, :operator, :admin] do
        op = %Operator{sub: "sub-#{role}", organization_id: "org-001", role: role}
        attr = Attribution.build(op)
        assert attr.sub == "sub-#{role}"
      end
    end

    test "handles nil display_name gracefully" do
      op = %Operator{sub: "sub-x", organization_id: "org-001", role: :operator}
      attr = Attribution.build(op)
      assert attr.display_name == nil
    end
  end

  # ── generate_correlation_id/0 ────────────────────────────────────────────────

  describe "generate_correlation_id/0" do
    test "returns a string prefixed with 'corr_'" do
      id = Attribution.generate_correlation_id()
      assert String.starts_with?(id, "corr_")
    end

    test "returns unique IDs on each call" do
      ids = Enum.map(1..20, fn _ -> Attribution.generate_correlation_id() end)
      assert length(Enum.uniq(ids)) == 20
    end

    test "returned ID is URL-safe (no + or / characters)" do
      # Base64 URL-safe encoding uses - and _ instead of + and /
      id = Attribution.generate_correlation_id()
      suffix = String.slice(id, 5, String.length(id))
      refute String.contains?(suffix, "+")
      refute String.contains?(suffix, "/")
      refute String.contains?(suffix, "=")
    end
  end

  # ── to_map/1 ─────────────────────────────────────────────────────────────────

  describe "to_map/1" do
    test "returns a map with all required keys" do
      attr = Attribution.build(operator(), "corr_test-001")
      map = Attribution.to_map(attr)

      assert map["sub"] == "sub-12345"
      assert map["display_name"] == "Alice Operator"
      assert map["organization_id"] == "org-001"
      assert map["correlation_id"] == "corr_test-001"
      assert is_binary(map["at"])
    end

    test "at field is ISO 8601 formatted" do
      attr = Attribution.build(operator())
      map = Attribution.to_map(attr)
      assert map["at"] =~ ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/
    end

    test "map is Jason-encodable" do
      attr = Attribution.build(operator(), "corr_json-test")
      map = Attribution.to_map(attr)
      assert {:ok, _json} = Jason.encode(map)
    end
  end
end
