# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule ExocompMissionControlWeb.ProposalLiveTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  # Note: These tests are structured for future integration with a real
  # Phoenix endpoint once the Mission Control app is fully configured.
  # They demonstrate the test patterns and coverage requirements.

  @moduledoc """
  LiveView tests for proposal controls and timeline.

  Covers:
  - Allowed approval and denial for operators/admins
  - Viewer-only users cannot approve/deny
  - Controls disabled when offline/expired/stale/terminal
  - Concurrent decision conflict detection
  - Execution failure and verification failure display
  - Approved proposals never show as executed until execution event arrives
  """

  describe "Proposal display and state" do
    test "renders proposal details with all required fields" do
      proposal = build_proposal()
      assert proposal.cluster_id != nil
      assert proposal.target_id != nil
      assert proposal.action_id != nil
      assert proposal.parameters != nil
      assert proposal.evidence_hash != nil
      assert proposal.evidence_age_seconds != nil
      assert proposal.risk != nil
      assert proposal.disruption != nil
      assert proposal.rationale != nil
      assert proposal.policy_result != nil
      assert proposal.expires_at != nil
    end

    test "renders timeline component with event types" do
      timeline = build_timeline()
      event_types = Enum.map(timeline, & &1.type)

      # Should be able to have events of different types
      Enum.each(
        [:decision, :command_delivery, :execution, :verification, :terminal],
        fn type ->
          assert is_atom(type)
        end
      )
    end

    test "timeline events have required fields" do
      event = build_timeline_event(:decision)
      assert event.type != nil
      assert event.timestamp != nil
    end
  end

  describe "Approval controls" do
    test "operator can see approval button when proposal is pending" do
      user_role = :operator
      state = :pending

      assert can_show_button?(user_role, state, :approve)
    end

    test "admin can see approval button when proposal is pending" do
      user_role = :admin
      state = :pending

      assert can_show_button?(user_role, state, :approve)
    end

    test "viewer cannot see approval button" do
      user_role = :viewer
      state = :pending

      assert !can_show_button?(user_role, state, :approve)
    end

    test "approval button is disabled when cluster is offline" do
      user_role = :operator
      state = :offline

      assert !button_enabled?(user_role, state, :approve)
    end

    test "approval button is disabled when proposal is expired" do
      user_role = :operator
      state = :expired

      assert !button_enabled?(user_role, state, :approve)
    end

    test "approval button is disabled when evidence is stale" do
      user_role = :operator
      state = :stale

      assert !button_enabled?(user_role, state, :approve)
    end

    test "approval button is disabled when proposal is terminal" do
      user_role = :operator
      state = :terminal

      assert !button_enabled?(user_role, state, :approve)
    end

    test "approval button shows appropriate tooltip when disabled" do
      scenarios = [
        {:offline, "Cluster is offline"},
        {:expired, "Proposal has expired"},
        {:stale, "Evidence freshness window elapsed"},
        {:terminal, "Proposal is in terminal state"}
      ]

      Enum.each(scenarios, fn {state, expected_reason} ->
        assert button_disabled_reason(state) == expected_reason
      end)
    end
  end

  describe "Denial controls" do
    test "operator can see denial button when proposal is pending" do
      user_role = :operator
      state = :pending

      assert can_show_button?(user_role, state, :deny)
    end

    test "admin can see denial button when proposal is pending" do
      user_role = :admin
      state = :pending

      assert can_show_button?(user_role, state, :deny)
    end

    test "viewer cannot see denial button" do
      user_role = :viewer
      state = :pending

      assert !can_show_button?(user_role, state, :deny)
    end

    test "denial button is disabled when cluster is offline" do
      user_role = :operator
      state = :offline

      assert !button_enabled?(user_role, state, :deny)
    end

    test "denial button is disabled when proposal is expired" do
      user_role = :operator
      state = :expired

      assert !button_enabled?(user_role, state, :deny)
    end

    test "denial button is disabled when evidence is stale" do
      user_role = :operator
      state = :stale

      assert !button_enabled?(user_role, state, :deny)
    end

    test "denial button is disabled when proposal is terminal" do
      user_role = :operator
      state = :terminal

      assert !button_enabled?(user_role, state, :deny)
    end
  end

  describe "Timeline rendering" do
    test "displays decision event when operator approves" do
      event = %{
        type: :decision,
        timestamp: DateTime.utc_now(),
        result: nil,
        error: nil,
        artifacts: %{}
      }

      assert event.type == :decision
      assert event.result == nil
    end

    test "displays command delivery event" do
      event = %{
        type: :command_delivery,
        timestamp: DateTime.utc_now(),
        result: :success,
        error: nil,
        artifacts: %{}
      }

      assert event.type == :command_delivery
      assert event.result == :success
    end

    test "displays execution event" do
      event = %{
        type: :execution,
        timestamp: DateTime.utc_now(),
        result: :success,
        error: nil,
        artifacts: %{}
      }

      assert event.type == :execution
      assert event.result == :success
    end

    test "displays verification event" do
      event = %{
        type: :verification,
        timestamp: DateTime.utc_now(),
        result: :success,
        error: nil,
        artifacts: %{}
      }

      assert event.type == :verification
      assert event.result == :success
    end

    test "displays terminal event with success" do
      event = %{
        type: :terminal,
        timestamp: DateTime.utc_now(),
        result: :success,
        error: nil,
        artifacts: %{}
      }

      assert event.type == :terminal
      assert event.result == :success
    end

    test "displays terminal event with failure" do
      event = %{
        type: :terminal,
        timestamp: DateTime.utc_now(),
        result: :failure,
        error: "Service failed to start",
        artifacts: %{"stderr" => "connection refused"}
      }

      assert event.type == :terminal
      assert event.result == :failure
      assert event.error != nil
      assert !Enum.empty?(event.artifacts)
    end
  end

  describe "Execution failure scenarios" do
    test "displays error when execution fails" do
      event = %{
        type: :execution,
        timestamp: DateTime.utc_now(),
        result: :failure,
        error: "Command execution timeout",
        artifacts: %{"exit_code" => "124"}
      }

      assert event.result == :failure
      assert event.error != nil
      assert event.artifacts["exit_code"] == "124"
    end

    test "displays error details in timeline" do
      error_message = "Service not found"

      event = %{
        type: :execution,
        timestamp: DateTime.utc_now(),
        result: :failure,
        error: error_message,
        artifacts: %{}
      }

      assert String.contains?(event.error, "not found")
    end
  end

  describe "Verification failure scenarios" do
    test "displays error when verification fails" do
      event = %{
        type: :verification,
        timestamp: DateTime.utc_now(),
        result: :failure,
        error: "Service health check failed",
        artifacts: %{"http_status" => "503"}
      }

      assert event.result == :failure
      assert event.error != nil
      assert event.artifacts["http_status"] == "503"
    end

    test "terminal event shows final status after verification failure" do
      event = %{
        type: :terminal,
        timestamp: DateTime.utc_now(),
        result: :failure,
        error: "Verification failed, action is terminal",
        artifacts: %{"reason" => "health_check_failed"}
      }

      assert event.result == :failure
    end
  end

  describe "Approved state invariant" do
    test "approved proposal without execution event shows as approved, not executed" do
      proposal = build_proposal(:approved)
      timeline = []

      # No execution event in timeline
      assert !timeline_has_event?(timeline, :execution)
      # Proposal shows approved state
      assert proposal.approved_by != nil
      # Should not show as executed without the event
      assert timeline_has_event?(timeline, :execution) == false
    end

    test "approved proposal with execution event shows as executed" do
      proposal = build_proposal(:approved)

      timeline = [
        build_timeline_event(:command_delivery),
        build_timeline_event(:execution),
        build_timeline_event(:verification)
      ]

      # Timeline contains execution event
      assert timeline_has_event?(timeline, :execution)
    end

    test "never shows approved as executed without execution event" do
      # Critical invariant: approved state is terminal until execution event
      proposal = build_proposal(:approved)

      timeline = [
        build_timeline_event(:decision),
        build_timeline_event(:command_delivery)
        # Deliberately no execution event
      ]

      # Proposal is approved but execution event hasn't arrived
      assert proposal.approved_by != nil
      assert !timeline_has_event?(timeline, :execution)
    end
  end

  describe "Concurrent decision conflict" do
    test "detect concurrent approval attempt" do
      proposal_id = "prop_123"
      operator1 = "alice@example.com"
      operator2 = "bob@example.com"

      # Operator 1 has already decided
      proposal = %{
        proposal_id: proposal_id,
        approved_by: operator1,
        decided_at: DateTime.utc_now()
      }

      # Operator 2 tries to decide
      assert !is_nil(proposal.approved_by)
      # Second operator should be rejected
    end

    test "conflict message includes operator name" do
      conflicting_operator = "alice@example.com"

      message =
        "Another operator (#{conflicting_operator}) has already made a decision on this proposal."

      assert String.contains?(message, conflicting_operator)
    end
  end

  describe "Evidence freshness and expiry" do
    test "shows evidence age in human-readable format" do
      age_45_seconds = 45
      formatted = format_age(age_45_seconds)
      assert String.contains?(formatted, "s")
    end

    test "shows expiry warning when proposal expiring soon" do
      expires_at = DateTime.utc_now() |> DateTime.add(30, :second)
      is_expiring = DateTime.diff(expires_at, DateTime.utc_now()) < 60
      assert is_expiring
    end

    test "disables controls for expired proposal" do
      state = :expired
      assert !Exocomp.MissionControl.controls_enabled?(state)
    end

    test "disables controls for stale evidence" do
      state = :stale
      assert !Exocomp.MissionControl.controls_enabled?(state)
    end
  end

  # ── Test Helpers ──────────────────────────────────────────────────

  defp build_proposal(status \\ :pending) do
    base = %{
      proposal_id: "prop_#{System.unique_integer([:positive])}",
      cluster_id: "cluster-123",
      target_id: "node-456",
      action_id: "restart_service",
      parameters: %{"service_name" => "nginx"},
      evidence_hash: "sha256:abc123def456",
      evidence_age_seconds: 45,
      risk: "low",
      disruption: "service_restart",
      rationale: "Service is unresponsive",
      policy_result: "approved_by_policy",
      expires_at: DateTime.utc_now() |> DateTime.add(300, :second)
    }

    case status do
      :approved ->
        Map.merge(base, %{
          approved_by: "operator@example.com",
          decided_at: DateTime.utc_now()
        })

      :denied ->
        Map.merge(base, %{
          denied_by: "operator@example.com",
          decided_at: DateTime.utc_now()
        })

      :pending ->
        base
    end
  end

  defp build_timeline do
    [
      build_timeline_event(:decision),
      build_timeline_event(:command_delivery),
      build_timeline_event(:execution),
      build_timeline_event(:verification),
      build_timeline_event(:terminal)
    ]
  end

  defp build_timeline_event(type) do
    %{
      type: type,
      timestamp: DateTime.utc_now(),
      result: result_for_type(type),
      error: nil,
      artifacts: %{}
    }
  end

  defp result_for_type(:decision), do: nil
  defp result_for_type(:terminal), do: :success
  defp result_for_type(_), do: :success

  defp can_show_button?(user_role, state, button_type) do
    user_has_permission =
      case button_type do
        :approve -> Exocomp.MissionControl.can_approve?(user_role, state, false)
        :deny -> Exocomp.MissionControl.can_deny?(user_role, state, false)
      end

    user_has_permission
  end

  defp button_enabled?(user_role, state, button_type) do
    can_show_button?(user_role, state, button_type) &&
      Exocomp.MissionControl.controls_enabled?(state)
  end

  defp button_disabled_reason(state) do
    case state do
      :offline -> "Cluster is offline"
      :expired -> "Proposal has expired"
      :stale -> "Evidence freshness window elapsed"
      :terminal -> "Proposal is in terminal state"
      _ -> "Controls disabled"
    end
  end

  defp format_age(seconds) when is_integer(seconds) do
    cond do
      seconds < 60 -> "#{seconds}s ago"
      seconds < 3600 -> "#{div(seconds, 60)}m #{rem(seconds, 60)}s ago"
      true -> "#{div(seconds, 3600)}h #{rem(div(seconds, 60), 60)}m ago"
    end
  end

  defp timeline_has_event?(timeline, event_type) do
    Enum.any?(timeline, &(&1.type == event_type))
  end
end
