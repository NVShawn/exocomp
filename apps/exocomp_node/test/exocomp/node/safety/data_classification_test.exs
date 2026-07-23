defmodule Exocomp.Node.Safety.DataClassificationTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Safety.DataClassification

  # ── classify/1 ──────────────────────────────────────────────────────────

  describe "classify/1 known values" do
    test "string 'system_data'" do
      assert DataClassification.classify("system_data") == :system_data
    end

    test "string 'protected_user_data'" do
      assert DataClassification.classify("protected_user_data") == :protected_user_data
    end

    test "atom :system_data" do
      assert DataClassification.classify(:system_data) == :system_data
    end

    test "atom :protected_user_data" do
      assert DataClassification.classify(:protected_user_data) == :protected_user_data
    end
  end

  describe "classify/1 fail-closed invariant — simple scalar unknown values" do
    # Table of simple scalar values that must all resolve to :protected_user_data.
    @scalar_unknown_inputs [
      nil,
      "",
      "unknown",
      "SYSTEM_DATA",
      "SystemData",
      "user_data",
      "public",
      :unknown,
      :public,
      0,
      false
    ]

    for value <- @scalar_unknown_inputs do
      test "#{inspect(value)} classifies as :protected_user_data" do
        assert DataClassification.classify(unquote(value)) == :protected_user_data
      end
    end
  end

  test "classify/1 treats a map as unknown → :protected_user_data" do
    assert DataClassification.classify(%{}) == :protected_user_data
  end

  test "classify/1 treats a list as unknown → :protected_user_data" do
    assert DataClassification.classify([]) == :protected_user_data
  end

  # ── deletion_eligible?/1 ────────────────────────────────────────────────

  describe "deletion_eligible?/1" do
    test ":system_data is deletion-eligible" do
      assert DataClassification.deletion_eligible?(:system_data) == true
    end

    test ":protected_user_data is never deletion-eligible" do
      assert DataClassification.deletion_eligible?(:protected_user_data) == false
    end

    test "arbitrary atom is not deletion-eligible (fail-closed)" do
      assert DataClassification.deletion_eligible?(:unknown) == false
    end

    test "nil is not deletion-eligible" do
      assert DataClassification.deletion_eligible?(nil) == false
    end
  end

  # ── Round-trip: classify then check eligibility ─────────────────────────

  describe "classify+deletion_eligible? round-trip" do
    test "classified :system_data is deletion-eligible" do
      result = DataClassification.classify("system_data")
      assert DataClassification.deletion_eligible?(result) == true
    end

    test "classified unknown is never deletion-eligible" do
      result = DataClassification.classify("totally_unknown_classification")
      assert DataClassification.deletion_eligible?(result) == false
    end
  end
end
