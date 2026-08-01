# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControlTest do
  use ExUnit.Case

  alias Exocomp.MissionControl

  doctest Exocomp.MissionControl

  describe "controls_enabled?/1" do
    test "returns true for pending proposals" do
      assert MissionControl.controls_enabled?(:pending) == true
    end

    test "returns false for approved proposals" do
      assert MissionControl.controls_enabled?(:approved) == false
    end

    test "returns false for denied proposals" do
      assert MissionControl.controls_enabled?(:denied) == false
    end

    test "returns false when cluster is offline" do
      assert MissionControl.controls_enabled?(:offline) == false
    end

    test "returns false when proposal is expired" do
      assert MissionControl.controls_enabled?(:expired) == false
    end

    test "returns false when evidence is stale" do
      assert MissionControl.controls_enabled?(:stale) == false
    end

    test "returns false for terminal proposals" do
      assert MissionControl.controls_enabled?(:terminal) == false
    end
  end

  describe "can_approve?/3" do
    test "operators can approve pending proposals" do
      assert MissionControl.can_approve?(:operator, :pending, false) == true
    end

    test "admins can approve pending proposals" do
      assert MissionControl.can_approve?(:admin, :pending, false) == true
    end

    test "viewers cannot approve" do
      assert MissionControl.can_approve?(:viewer, :pending, false) == false
    end

    test "operators cannot approve when controls are disabled" do
      assert MissionControl.can_approve?(:operator, :offline, false) == false
    end

    test "operators cannot approve when there is a concurrent decision" do
      assert MissionControl.can_approve?(:operator, :pending, true) == false
    end

    test "cannot approve expired proposals" do
      assert MissionControl.can_approve?(:operator, :expired, false) == false
    end

    test "cannot approve stale proposals" do
      assert MissionControl.can_approve?(:operator, :stale, false) == false
    end

    test "cannot approve terminal proposals" do
      assert MissionControl.can_approve?(:operator, :terminal, false) == false
    end
  end

  describe "can_deny?/3" do
    test "operators can deny pending proposals" do
      assert MissionControl.can_deny?(:operator, :pending, false) == true
    end

    test "admins can deny pending proposals" do
      assert MissionControl.can_deny?(:admin, :pending, false) == true
    end

    test "viewers cannot deny" do
      assert MissionControl.can_deny?(:viewer, :pending, false) == false
    end

    test "operators cannot deny when controls are disabled" do
      assert MissionControl.can_deny?(:operator, :offline, false) == false
    end

    test "operators cannot deny when there is a concurrent decision" do
      assert MissionControl.can_deny?(:operator, :pending, true) == false
    end

    test "cannot deny expired proposals" do
      assert MissionControl.can_deny?(:operator, :expired, false) == false
    end

    test "cannot deny stale proposals" do
      assert MissionControl.can_deny?(:operator, :stale, false) == false
    end

    test "cannot deny terminal proposals" do
      assert MissionControl.can_deny?(:operator, :terminal, false) == false
    end
  end
end
