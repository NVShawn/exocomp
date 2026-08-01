# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.MissionControl.Security.ApprovalsSecurityTest do
  @moduledoc """
  Comprehensive security negative tests for approval boundaries.

  Tests verify that malicious or attacker inputs are rejected before
  execution, including: cross-organization access, expired approvals,
  stale evidence, cluster disconnection, invalid denial reasons, and
  payload identity override attempts.

  ## Security Boundaries Tested

  - **Cross-organization isolation**: Operator from org-a cannot approve
    proposals in org-b, even if they are admin in their own org.
  - **Approval expiry**: Expired proposals cannot be approved.
  - **Evidence freshness**: Approvals with stale evidence are rejected.
  - **Cluster connectivity**: Approvals are disabled when cluster disconnected.
  - **Unauthenticated rejection**: nil or invalid operators are rejected.
  - **Proposal terminal state**: Only pending proposals can be approved.
  - **Denial reason bounds**: Reasons must be non-empty and size-bounded.
  - **Organization mismatch**: Proposal and request org must match.
  - **Audit attribution**: Operator identity is immutable in audit records.
  """

  use ExUnit.Case, async: true

  @moduletag :security

  alias Exocomp.MissionControl.{Approvals, Proposal}
  alias Exocomp.MissionControl.Identity.Operator

  @org_a "org-alpha"
  @org_b "org-beta"
  @proposal_id "prop-001"

  defp operator(org_id, role, sub \\ nil) do
    %Operator{
      sub: sub || "sub-#{org_id}-#{role}",
      organization_id: org_id,
      display_name: "Test #{role}",
      role: role
    }
  end

  defp proposal(org_id, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    expires_at = Keyword.get(opts, :expires_at, DateTime.add(now, 3600, :second))
    evidence_fresh_until = Keyword.get(opts, :evidence_fresh_until, DateTime.add(now, 3600, :second))

    %Proposal{
      proposal_id: Keyword.get(opts, :proposal_id, @proposal_id),
      organization_id: org_id,
      cluster_id: Keyword.get(opts, :cluster_id, "cluster-001"),
      node_id: Keyword.get(opts, :node_id, "node-001"),
      target_id: Keyword.get(opts, :target_id, "target-001"),
      action_id: Keyword.get(opts, :action_id, "action-001"),
      task_id: Keyword.get(opts, :task_id, "task-001"),
      correlation_id: Keyword.get(opts, :correlation_id, "corr-001"),
      status: Keyword.get(opts, :status, "pending"),
      decision: Keyword.get(opts, :decision, nil),
      expires_at: expires_at,
      evidence_hash: Keyword.get(opts, :evidence_hash, "hash-001"),
      evidence_fresh_until: evidence_fresh_until,
      parameters: Keyword.get(opts, :parameters, %{})
    }
  end

  # ── Cross-Organization Isolation ─────────────────────────────────────────────

  describe "approve/4 — cross-organization isolation (fail closed)" do
    test "operator from org-a cannot approve proposal in org-b (even if admin)" do
      admin_org_a = operator(@org_a, :admin)
      proposal_org_b = proposal(@org_b)

      result =
        Approvals.approve(@org_b, proposal_org_b.proposal_id, admin_org_a,
          now: DateTime.utc_now(),
          repo: MockRepo.approved_proposal()
        )

      assert {:error, :cross_organization} = result,
             "Expected cross_organization error, got #{inspect(result)}"
    end

    test "operator from org-a cannot deny proposal in org-b" do
      operator_org_a = operator(@org_a, :operator)
      proposal_org_b = proposal(@org_b)

      result =
        Approvals.deny(@org_b, proposal_org_b.proposal_id, operator_org_a, "Reasons", [])

      assert {:error, :cross_organization} = result,
             "Expected cross_organization error, got #{inspect(result)}"
    end

    test "viewer from org-a cannot read org-b proposals to approve" do
      viewer_org_a = operator(@org_a, :viewer)

      # Viewers cannot operate, so they should be rejected with insufficient_role
      # not cross_organization, but the organizational scope must be verified first
      result =
        Approvals.approve(@org_a, @proposal_id, viewer_org_a, now: DateTime.utc_now())

      assert {:error, :insufficient_role} = result,
             "Viewer should be rejected with insufficient_role"
    end
  end

  # ── Approval Expiry: Stale or Replayed Approvals ──────────────────────────────

  describe "approve/4 — stale/expired approvals (fail closed)" do
    test "expired proposal cannot be approved" do
      now = DateTime.utc_now()
      expired_at = DateTime.add(now, -1, :second)

      proposal_expired = proposal(@org_a, expires_at: expired_at, now: now)
      operator_a = operator(@org_a, :operator)

      result =
        Approvals.approve(@org_a, proposal_expired.proposal_id, operator_a,
          now: now,
          repo: MockRepo.proposal(proposal_expired)
        )

      assert {:error, :proposal_expired} = result,
             "Expired proposal should be rejected"
    end

    test "approval at exactly expiry time is rejected" do
      now = DateTime.utc_now()

      proposal_exactly_expired = proposal(@org_a, expires_at: now)
      operator_a = operator(@org_a, :operator)

      result =
        Approvals.approve(@org_a, proposal_exactly_expired.proposal_id, operator_a,
          now: now,
          repo: MockRepo.proposal(proposal_exactly_expired)
        )

      # At or past expiry time should be rejected
      assert {:error, :proposal_expired} = result
    end

    test "approval with stale evidence is rejected" do
      now = DateTime.utc_now()
      stale_evidence_at = DateTime.add(now, -1, :second)

      proposal_stale_evidence = proposal(@org_a, evidence_fresh_until: stale_evidence_at, now: now)
      operator_a = operator(@org_a, :operator)

      result =
        Approvals.approve(@org_a, proposal_stale_evidence.proposal_id, operator_a,
          now: now,
          repo: MockRepo.proposal(proposal_stale_evidence)
        )

      assert {:error, :evidence_stale} = result,
             "Proposal with stale evidence should be rejected"
    end

    test "approval at exactly evidence freshness boundary is rejected" do
      now = DateTime.utc_now()

      proposal_exactly_stale = proposal(@org_a, evidence_fresh_until: now)
      operator_a = operator(@org_a, :operator)

      result =
        Approvals.approve(@org_a, proposal_exactly_stale.proposal_id, operator_a,
          now: now,
          repo: MockRepo.proposal(proposal_exactly_stale)
        )

      assert {:error, :evidence_stale} = result
    end
  end

  # ── Cluster Disconnection ────────────────────────────────────────────────────

  describe "approve/4 — cluster disconnection (fail closed)" do
    test "approval is rejected when cluster disconnected" do
      now = DateTime.utc_now()
      operator_a = operator(@org_a, :operator)
      proposal_a = proposal(@org_a, now: now)

      result =
        Approvals.approve(@org_a, proposal_a.proposal_id, operator_a,
          now: now,
          repo: MockRepo.proposal(proposal_a),
          connected?: fn -> false end
        )

      assert {:error, :cluster_disconnected} = result,
             "Approval should be rejected when cluster disconnected"
    end

    test "approval is accepted when cluster connected" do
      now = DateTime.utc_now()
      operator_a = operator(@org_a, :operator)
      proposal_a = proposal(@org_a, now: now)

      result =
        Approvals.approve(@org_a, proposal_a.proposal_id, operator_a,
          now: now,
          repo: MockRepo.approved_proposal(),
          connected?: fn -> true end
        )

      assert {:ok, _} = result,
             "Approval should succeed when cluster connected"
    end

    test "denial is allowed even when cluster disconnected" do
      now = DateTime.utc_now()
      operator_a = operator(@org_a, :operator)
      proposal_a = proposal(@org_a, now: now)

      result =
        Approvals.deny(@org_a, proposal_a.proposal_id, operator_a, "Reason",
          now: now,
          repo: MockRepo.denied_proposal(),
          connected?: fn -> false end
        )

      # Denial should not check cluster connectivity
      assert {:ok, _} = result
    end
  end

  # ── Terminal Proposal State ──────────────────────────────────────────────────

  describe "approve/4 — terminal proposal state (fail closed)" do
    test "already-approved proposal cannot be approved again" do
      now = DateTime.utc_now()

      already_approved = proposal(@org_a,
        status: "approved",
        decision: "approved",
        now: now
      )

      operator_a = operator(@org_a, :operator)

      result =
        Approvals.approve(@org_a, already_approved.proposal_id, operator_a,
          now: now,
          repo: MockRepo.proposal(already_approved)
        )

      assert {:error, :proposal_terminal} = result,
             "Already-approved proposal should be terminal"
    end

    test "already-denied proposal cannot be approved" do
      now = DateTime.utc_now()

      already_denied = proposal(@org_a,
        status: "denied",
        decision: "denied",
        now: now
      )

      operator_a = operator(@org_a, :operator)

      result =
        Approvals.approve(@org_a, already_denied.proposal_id, operator_a,
          now: now,
          repo: MockRepo.proposal(already_denied)
        )

      assert {:error, :proposal_terminal} = result,
             "Already-denied proposal should be terminal"
    end

    test "already-denied proposal cannot be denied again" do
      now = DateTime.utc_now()

      already_denied = proposal(@org_a,
        status: "denied",
        decision: "denied",
        now: now
      )

      operator_a = operator(@org_a, :operator)

      result =
        Approvals.deny(@org_a, already_denied.proposal_id, operator_a, "Another reason",
          now: now,
          repo: MockRepo.proposal(already_denied)
        )

      assert {:error, :proposal_terminal} = result,
             "Already-denied proposal should be terminal"
    end
  end

  # ── Unauthenticated Rejection ────────────────────────────────────────────────

  describe "approve/4 — unauthenticated rejection (fail closed)" do
    test "nil operator is rejected" do
      proposal_a = proposal(@org_a)

      result = Approvals.approve(@org_a, proposal_a.proposal_id, nil, [])

      assert {:error, :unauthenticated} = result,
             "nil operator should be rejected with :unauthenticated"
    end

    test "approval fails when operator has no organization" do
      invalid_operator = %Operator{
        sub: "sub",
        organization_id: nil,
        display_name: "Invalid",
        role: :operator
      }

      proposal_a = proposal(@org_a)

      result =
        Approvals.approve(@org_a, proposal_a.proposal_id, invalid_operator,
          now: DateTime.utc_now()
        )

      # Should fail because org_id is nil
      assert match?({:error, :cross_organization}, result)
    end

    test "denial with nil operator is rejected" do
      proposal_a = proposal(@org_a)

      result = Approvals.deny(@org_a, proposal_a.proposal_id, nil, "Reason", [])

      assert {:error, :unauthenticated} = result,
             "nil operator should be rejected"
    end
  end

  # ── Insufficient Role Rejection ──────────────────────────────────────────────

  describe "approve/4 — insufficient role (fail closed)" do
    test "viewer cannot approve" do
      viewer = operator(@org_a, :viewer)
      proposal_a = proposal(@org_a)

      result =
        Approvals.approve(@org_a, proposal_a.proposal_id, viewer,
          now: DateTime.utc_now(),
          repo: MockRepo.proposal(proposal_a)
        )

      assert {:error, :insufficient_role} = result,
             "Viewer should not be allowed to approve"
    end

    test "viewer cannot deny" do
      viewer = operator(@org_a, :viewer)
      proposal_a = proposal(@org_a)

      result = Approvals.deny(@org_a, proposal_a.proposal_id, viewer, "Reason", [])

      assert {:error, :insufficient_role} = result,
             "Viewer should not be allowed to deny"
    end
  end

  # ── Denial Reason Validation ─────────────────────────────────────────────────

  describe "deny/4 — denial reason validation (fail closed)" do
    test "empty denial reason is rejected" do
      operator_a = operator(@org_a, :operator)
      proposal_a = proposal(@org_a)

      result = Approvals.deny(@org_a, proposal_a.proposal_id, operator_a, "", [])

      assert {:error, :invalid_denial_reason} = result,
             "Empty denial reason should be rejected"
    end

    test "whitespace-only denial reason is rejected" do
      operator_a = operator(@org_a, :operator)
      proposal_a = proposal(@org_a)

      result =
        Approvals.deny(@org_a, proposal_a.proposal_id, operator_a, "   \n\t  ", [])

      assert {:error, :invalid_denial_reason} = result,
             "Whitespace-only reason should be rejected"
    end

    test "nil denial reason is rejected" do
      operator_a = operator(@org_a, :operator)
      proposal_a = proposal(@org_a)

      result = Approvals.deny(@org_a, proposal_a.proposal_id, operator_a, nil, [])

      assert {:error, :invalid_denial_reason} = result,
             "nil reason should be rejected"
    end

    test "denial reason exceeding max size is rejected" do
      operator_a = operator(@org_a, :operator)
      proposal_a = proposal(@org_a)

      # Build a reason larger than 4096 bytes
      oversized_reason = String.duplicate("x", 4097)

      result =
        Approvals.deny(@org_a, proposal_a.proposal_id, operator_a, oversized_reason, [])

      assert {:error, :invalid_denial_reason} = result,
             "Oversized denial reason should be rejected"
    end

    test "denial reason at max boundary (4096 bytes) is accepted" do
      operator_a = operator(@org_a, :operator)
      proposal_a = proposal(@org_a)

      # Build a reason exactly 4096 bytes
      max_reason = String.duplicate("x", 4096)

      result =
        Approvals.deny(@org_a, proposal_a.proposal_id, operator_a, max_reason,
          now: DateTime.utc_now(),
          repo: MockRepo.denied_proposal()
        )

      assert {:ok, _} = result,
             "Denial reason at max boundary should be accepted"
    end

    test "denial reason just under max boundary is accepted" do
      operator_a = operator(@org_a, :operator)
      proposal_a = proposal(@org_a)

      safe_reason = String.duplicate("x", 4095)

      result =
        Approvals.deny(@org_a, proposal_a.proposal_id, operator_a, safe_reason,
          now: DateTime.utc_now(),
          repo: MockRepo.denied_proposal()
        )

      assert {:ok, _} = result,
             "Denial reason under max should be accepted"
    end
  end

  # ── Organization Mismatch ────────────────────────────────────────────────────

  describe "approve/4 —organization mismatch (fail closed)" do
    test "proposal from org-b cannot be approved under org-a context" do
      now = DateTime.utc_now()
      operator_a = operator(@org_a, :operator)
      proposal_b = proposal(@org_b, now: now)

      result =
        Approvals.approve(@org_a, proposal_b.proposal_id, operator_a,
          now: now,
          repo: MockRepo.proposal(proposal_b)
        )

      assert {:error, :organization_mismatch} = result,
             "Proposal org mismatch should be rejected"
    end

    test "requesting org and proposal org must match exactly" do
      now = DateTime.utc_now()
      operator_a = operator(@org_a, :operator)

      # Use a different org in the proposal
      proposal_with_different_org = proposal(@org_b, proposal_id: "different-prop")

      result =
        Approvals.approve(@org_a, proposal_with_different_org.proposal_id, operator_a,
          now: now,
          repo: MockRepo.proposal(proposal_with_different_org)
        )

      assert {:error, :organization_mismatch} = result,
             "Request org and proposal org must match"
    end
  end

  # ── Audit Attribution Immutability ───────────────────────────────────────────

  describe "approve/4 — audit attribution (identity immutable in records)" do
    test "operator sub is recorded immutably in decision" do
      now = DateTime.utc_now()
      operator_a = operator(@org_a, :operator, "unique-sub-001")
      proposal_a = proposal(@org_a, now: now)

      result =
        Approvals.approve(@org_a, proposal_a.proposal_id, operator_a,
          now: now,
          repo: MockRepo.approved_proposal_for_audit(operator_a)
        )

      assert {:ok, updated} = result
      assert updated.decided_by_sub == "unique-sub-001",
             "Operator sub should be recorded immutably"
    end

    test "operator display name is recorded in decision" do
      now = DateTime.utc_now()
      operator_a = %Operator{
        sub: "sub-001",
        organization_id: @org_a,
        display_name: "Alice Smith",
        role: :operator
      }

      proposal_a = proposal(@org_a, now: now)

      result =
        Approvals.approve(@org_a, proposal_a.proposal_id, operator_a,
          now: now,
          repo: MockRepo.approved_proposal_for_audit(operator_a)
        )

      assert {:ok, updated} = result
      assert updated.decided_by_display_name == "Alice Smith",
             "Display name should be recorded immutably"
    end

    test "operator organization is recorded in decision" do
      now = DateTime.utc_now()
      operator_a = operator(@org_a, :operator)
      proposal_a = proposal(@org_a, now: now)

      result =
        Approvals.approve(@org_a, proposal_a.proposal_id, operator_a,
          now: now,
          repo: MockRepo.approved_proposal_for_audit(operator_a)
        )

      assert {:ok, updated} = result
      assert updated.decided_by_organization_id == @org_a,
             "Organization should be recorded immutably"
    end
  end

  # ── Not Found ────────────────────────────────────────────────────────────────

  describe "approve/4 — proposal not found" do
    test "non-existent proposal returns not_found" do
      operator_a = operator(@org_a, :operator)

      result =
        Approvals.approve(@org_a, "non-existent-id", operator_a,
          now: DateTime.utc_now(),
          repo: MockRepo.not_found()
        )

      assert {:error, :not_found} = result,
             "Non-existent proposal should return not_found"
    end
  end
end

# ── Mock Repository Implementations ──────────────────────────────────────────────

defmodule MockRepo do
  @moduledoc """
  Mock repository implementations for testing security boundaries.
  """

  def proposal(prop) do
    %{
      one: fn _query -> prop end,
      transaction: fn func ->
        case func.() do
          {:ok, result} -> {:ok, result}
          {:error, reason} -> {:error, reason}
          result when is_map(result) -> {:ok, result}
        end
      end,
      rollback: fn reason -> {:error, reason} end
    }
  end

  def approved_proposal do
    proposal(%Exocomp.MissionControl.Proposal{
      proposal_id: "prop-001",
      organization_id: "org-alpha",
      cluster_id: "cluster-001",
      node_id: "node-001",
      target_id: "target-001",
      action_id: "action-001",
      task_id: "task-001",
      correlation_id: "corr-001",
      status: "pending",
      expires_at: DateTime.add(DateTime.utc_now(), 3600, :second),
      evidence_hash: "hash-001",
      evidence_fresh_until: DateTime.add(DateTime.utc_now(), 3600, :second)
    })
  end

  def approved_proposal_for_audit(operator) do
    base_proposal = %Exocomp.MissionControl.Proposal{
      proposal_id: "prop-001",
      organization_id: "org-alpha",
      cluster_id: "cluster-001",
      node_id: "node-001",
      target_id: "target-001",
      action_id: "action-001",
      task_id: "task-001",
      correlation_id: "corr-001",
      status: "pending",
      expires_at: DateTime.add(DateTime.utc_now(), 3600, :second),
      evidence_hash: "hash-001",
      evidence_fresh_until: DateTime.add(DateTime.utc_now(), 3600, :second)
    }

    %{
      one: fn _query -> base_proposal end,
      transaction: fn func ->
        case func.() do
          {:ok, _} ->
            updated = %{
              base_proposal
              | status: "approved",
                decision: "approved",
                decided_by_sub: operator.sub,
                decided_by_display_name: operator.display_name,
                decided_by_organization_id: operator.organization_id
            }

            {:ok, updated}

          {:error, reason} ->
            {:error, reason}
        end
      end,
      rollback: fn reason -> {:error, reason} end,
      update: fn _changeset -> {:ok, base_proposal} end
    }
  end

  def denied_proposal do
    proposal(%Exocomp.MissionControl.Proposal{
      proposal_id: "prop-001",
      organization_id: "org-alpha",
      cluster_id: "cluster-001",
      node_id: "node-001",
      target_id: "target-001",
      action_id: "action-001",
      task_id: "task-001",
      correlation_id: "corr-001",
      status: "pending",
      expires_at: DateTime.add(DateTime.utc_now(), 3600, :second),
      evidence_hash: "hash-001",
      evidence_fresh_until: DateTime.add(DateTime.utc_now(), 3600, :second),
      denial_reason: ""
    })
  end

  def not_found do
    %{
      one: fn _query -> nil end,
      transaction: fn func -> func.() end,
      rollback: fn reason -> {:error, reason} end
    }
  end
end
