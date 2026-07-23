defmodule Exocomp.Node.Safety.ValidatorResultTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Safety.ValidatorResult

  # ── schema_version/0 ──────────────────────────────────────────────────

  test "schema_version/0 returns '1'" do
    assert ValidatorResult.schema_version() == "1"
  end

  # ── Constructor functions ─────────────────────────────────────────────

  describe "deny/1 (reason only)" do
    test "creates a :deny result with no action_id" do
      result = ValidatorResult.deny("validation failed")
      assert result.decision == :deny
      assert result.reason == "validation failed"
      assert result.action_id == nil
      assert result.evidence_refs == []
      assert result.schema_version == "1"
    end
  end

  describe "deny/3 (action_id, reason, evidence_refs)" do
    test "creates a :deny result with action context" do
      result = ValidatorResult.deny("systemd.service.restart", "stale evidence", ["ev-001"])
      assert result.decision == :deny
      assert result.action_id == "systemd.service.restart"
      assert result.reason == "stale evidence"
      assert result.evidence_refs == ["ev-001"]
    end
  end

  describe "allow/3" do
    test "creates an :allow result" do
      result = ValidatorResult.allow("systemd.service.restart", "valid evidence", ["ev-001"])
      assert result.decision == :allow
      assert result.action_id == "systemd.service.restart"
      assert result.reason == "valid evidence"
      assert result.evidence_refs == ["ev-001"]
      assert result.schema_version == "1"
    end
  end

  describe "approval_required/3" do
    test "creates an :approval_required result" do
      result =
        ValidatorResult.approval_required(
          "systemd.service.restart",
          "service is active",
          ["ev-002"]
        )

      assert result.decision == :approval_required
      assert result.action_id == "systemd.service.restart"
      assert result.reason == "service is active"
      assert result.evidence_refs == ["ev-002"]
    end
  end

  # ── Predicate helpers ─────────────────────────────────────────────────

  describe "allow?/1" do
    test "returns true only for :allow decision" do
      assert ValidatorResult.allow?(ValidatorResult.allow("a", "r", [])) == true
      assert ValidatorResult.allow?(ValidatorResult.deny("reason")) == false
      assert ValidatorResult.allow?(ValidatorResult.approval_required("a", "r", [])) == false
    end
  end

  describe "deny?/1" do
    test "returns true only for :deny decision" do
      assert ValidatorResult.deny?(ValidatorResult.deny("reason")) == true
      assert ValidatorResult.deny?(ValidatorResult.allow("a", "r", [])) == false
      assert ValidatorResult.deny?(ValidatorResult.approval_required("a", "r", [])) == false
    end
  end

  describe "approval_required?/1" do
    test "returns true only for :approval_required decision" do
      assert ValidatorResult.approval_required?(ValidatorResult.approval_required("a", "r", [])) ==
               true

      assert ValidatorResult.approval_required?(ValidatorResult.deny("reason")) == false
      assert ValidatorResult.approval_required?(ValidatorResult.allow("a", "r", [])) == false
    end
  end

  # ── Default struct is :deny ───────────────────────────────────────────

  test "default struct decision is :deny (fail-closed)" do
    default = %ValidatorResult{
      schema_version: "1",
      decision: :deny,
      reason: "",
      evidence_refs: []
    }

    assert default.decision == :deny
  end

  # ── parse/1 — valid inputs ────────────────────────────────────────────

  @valid_attrs %{
    "schema_version" => "1",
    "decision" => "deny",
    "action_id" => "systemd.service.restart",
    "reason" => "stale evidence",
    "evidence_refs" => ["ev-001"]
  }

  test "parse/1 returns {:ok, ValidatorResult} for valid deny" do
    assert {:ok, %ValidatorResult{decision: :deny}} = ValidatorResult.parse(@valid_attrs)
  end

  test "parse/1 accepts 'allow' decision" do
    attrs = Map.put(@valid_attrs, "decision", "allow")
    assert {:ok, %ValidatorResult{decision: :allow}} = ValidatorResult.parse(attrs)
  end

  test "parse/1 accepts 'approval_required' decision" do
    attrs = Map.put(@valid_attrs, "decision", "approval_required")
    assert {:ok, %ValidatorResult{decision: :approval_required}} = ValidatorResult.parse(attrs)
  end

  test "parse/1 accepts missing action_id (optional field)" do
    attrs = Map.delete(@valid_attrs, "action_id")
    assert {:ok, %ValidatorResult{action_id: nil}} = ValidatorResult.parse(attrs)
  end

  test "parse/1 accepts missing evidence_refs (defaults to [])" do
    attrs = Map.delete(@valid_attrs, "evidence_refs")
    assert {:ok, %ValidatorResult{evidence_refs: []}} = ValidatorResult.parse(attrs)
  end

  # ── parse/1 — schema version ──────────────────────────────────────────

  test "parse/1 rejects missing schema_version" do
    attrs = Map.delete(@valid_attrs, "schema_version")
    assert {:error, :missing_schema_version} = ValidatorResult.parse(attrs)
  end

  test "parse/1 rejects unknown schema_version '2'" do
    attrs = Map.put(@valid_attrs, "schema_version", "2")
    assert {:error, {:unknown_schema_version, "2"}} = ValidatorResult.parse(attrs)
  end

  # ── parse/1 — unknown fields ──────────────────────────────────────────

  test "parse/1 rejects an extra field" do
    attrs = Map.put(@valid_attrs, "extra", "value")
    assert {:error, {:unknown_fields, ["extra"]}} = ValidatorResult.parse(attrs)
  end

  # ── parse/1 — decision validation ────────────────────────────────────

  test "parse/1 rejects unknown decision value" do
    attrs = Map.put(@valid_attrs, "decision", "grant")
    assert {:error, {:unknown_decision, "grant"}} = ValidatorResult.parse(attrs)
  end

  test "parse/1 rejects missing decision" do
    attrs = Map.delete(@valid_attrs, "decision")
    assert {:error, {:missing_field, "decision"}} = ValidatorResult.parse(attrs)
  end

  # ── parse/1 — non-map input ───────────────────────────────────────────

  test "parse/1 rejects nil" do
    assert {:error, :invalid_validator_result_input} = ValidatorResult.parse(nil)
  end

  test "parse/1 rejects a list" do
    assert {:error, :invalid_validator_result_input} = ValidatorResult.parse([])
  end
end
