---
id: EXOCOMP-32
type: feature
status: In Validation
priority: 1
title: Implement approval-required active and degraded recovery
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-24
- EXOCOMP-27
- EXOCOMP-30
labels:
- focus-complete:duplicate_detector
- focus-complete:frontend
assignee: null
created_at: '2026-07-23T19:10:47.855632Z'
updated_at: '2026-08-01T03:07:07.530817Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: d98f9a4d-cbd4-4bcb-a8c2-a5f39ec4c340
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 458571
  total_output_tokens: 8780
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 458571
      output_tokens: 8780
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 458535
    output_tokens: 2251
    cost_usd: 0.0
    recorded_at: '2026-07-24T18:57:14.993723+00:00'
  - profile: default
    model: unknown
    input_tokens: 36
    output_tokens: 6529
    cost_usd: 0.0
    recorded_at: '2026-07-24T19:01:02.802293+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-9d1bcb9ceaf3
    project_id: proj-c260b117
    task_id: EXOCOMP-32
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: a305e5c3a398a561e36d759d664d8c1b92bf80d219a87eb9cbc1c3ac7a4564d9
    attempts:
    - version: 1
      attempt_id: attempt-c951c161bf34
      target_state: Archived
      request_state: in_progress
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: a305e5c3a398a561e36d759d664d8c1b92bf80d219a87eb9cbc1c3ac7a4564d9
      created_at: '2026-08-01T03:07:03.580739+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T03:07:03.580739+00:00'
      branch_key: epic-EXOCOMP-4
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-01T03:00:21.599854+00:00'
    updated_at: '2026-08-01T03:07:03.580739+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-c951c161bf34
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: a305e5c3a398a561e36d759d664d8c1b92bf80d219a87eb9cbc1c3ac7a4564d9
    created_at: '2026-08-01T03:07:03.580739+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T03:07:03.580739+00:00'
    branch_key: epic-EXOCOMP-4
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Implement approval-required active and degraded recovery.

Implementation
When current evidence shows an active or degraded service, move the task to input-required; display exact impact and evidence; accept only a valid bound approval; refresh preconditions before execution; cancel or re-diagnose when state changes.

Testing
Test approve, deny, expiry, timeout, wrong approver/token, changed evidence, service becomes healthy/failed, cancellation, and duplicate approval.

Acceptance Criteria
- [ ] No active/degraded service restarts before valid approval.
- [ ] Approval is invalid after relevant state changes.
- [ ] Denial/timeout performs no action and leaves an auditable terminal/escalated result.
- [ ] Focused approval-flow tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:55
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:55
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 18:56
---
Understanding: Screening EXOCOMP-32 for duplication before any implementation. I will search existing tasks and design docs for approval-gated active/degraded recovery, inspect the full state/comments of plausible candidates, then archive only if the same underlying work is already tracked; otherwise I will record a duplicate-detector handoff and label the focus complete.
---
author: oompah
created: 2026-07-24 18:56
---
Discovery: Duplicate screening found no duplicate. The closest reviewed tasks are EXOCOMP-27 (generic remediation/A2A lifecycle), EXOCOMP-30 (recovery state machine), EXOCOMP-23/24/98 (approval issuance, node verification, replay gate), EXOCOMP-31 (automatic failed-service recovery), and EXOCOMP-33 (fault/idempotency tests). They provide prerequisites or sibling flows, but none owns the service-specific active/degraded path that presents exact impact/evidence, waits for an operator decision, accepts only a currently bound approval, refreshes service evidence immediately before execution, and re-diagnoses/escalates if the service becomes healthy/failed or evidence otherwise changes.
---
author: oompah
created: 2026-07-24 18:57
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-32 is the distinct Milestone 4 approval-required active/degraded recovery flow and should proceed to implementation.

Evidence and decisions: The checkout has no .oompah/tasks directory, so I searched plans/docs locally and read candidate tracker records in full. Reviewed EXOCOMP-23, EXOCOMP-24, EXOCOMP-27, EXOCOMP-30, EXOCOMP-31, EXOCOMP-33, and EXOCOMP-98. EXOCOMP-23/24/98 supply bound token issuance, verification, fresh-precondition enforcement, and replay protection. EXOCOMP-27 supplies the generic A2A remediation lifecycle. EXOCOMP-30 supplies the recovery transition machine. EXOCOMP-31 is the separate automatic path for already-failed services. EXOCOMP-33 owns broad fault/idempotency testing. None implements this exact active/degraded recovery orchestration. The Milestone 4 plan explicitly separates automatic failed recovery from active/degraded approval recovery.

Relevant files/specification: plans/milestone-4-service-recovery.md (Recovery State Machine, approval and failure behavior, test strategy); plans/milestone-3-safety-validation.md (approval bindings); apps/exocomp_core/lib/exocomp/recovery/state_machine.ex and its tests from EXOCOMP-30; coordinator remediation lifecycle from EXOCOMP-27; node ApprovalGate from EXOCOMP-98.

Remaining work/risks: Integrate the completed prerequisite branches into epic-EXOCOMP-4 as needed; show exact disruption impact and evidence in input-required state; distinguish approve, deny, expiry, timeout, cancel, wrong approver/token, and duplicate decisions; refresh evidence before execution; invalidate approval and re-diagnose/escalate when evidence or service state changes, including healthy/failed transitions; prove zero restart on all non-valid paths. Preserve EXOCOMP-30's one-attempt/audit invariants and use EXOCOMP-98 rather than duplicating token validation.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 18:57
---
Agent completed successfully in 85s (460786 tokens)
---
author: oompah
created: 2026-07-24 18:57
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 12
- Tokens: 458.5K in / 2.3K out [460.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 25s
- Log: EXOCOMP-32__20260724T185553Z.jsonl
---
author: oompah
created: 2026-07-24 18:57
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 18:57
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:57
---
Focus: Frontend Developer
---
author: oompah
created: 2026-07-24 18:57
---
Understanding: I am the Frontend Developer focus for EXOCOMP-32. This task implements approval-required active and degraded recovery. My role is to handle any user-facing UI components needed: displaying exact impact/evidence when a service is active/degraded, showing the approval prompt with correct context, and surfacing denial/timeout/expiry results in the UI. I will first explore the codebase to understand what UI exists (LiveView templates, Phoenix components, JS hooks) and what new UI is needed to support the approval flow.
---
author: oompah
created: 2026-07-24 18:59
---
Discovery: Examined the full codebase. This project is a pure Elixir A2A (Agent-to-Agent) backend — no HTML, CSS, JavaScript, LiveView, or any browser-facing UI exists anywhere. The codebase consists of Elixir OTP applications (exocomp_core, exocomp_coordinator, exocomp_node) with JSON/HTTP Plug endpoints for A2A protocol communication. There is no frontend work to perform for this task.

Key files found:
- apps/exocomp_core/lib/exocomp/recovery/state_machine.ex — full StateMachine already implemented (EXOCOMP-30), including :awaiting_approval state
- apps/exocomp_core/lib/exocomp/recovery/evidence.ex — Evidence freshness checking
- apps/exocomp_core/lib/exocomp/a2a/task_state.ex — includes :input_required state
- apps/exocomp_node/lib/exocomp/node/skills/ — ServiceDiagnose, RemediationPropose, SystemDiagnose skills
- apps/exocomp_node/lib/exocomp/node/task_registry.ex — GenServer task registry
- apps/exocomp_node/lib/exocomp/node/a2a/codec.ex — A2A message codec

What is NOT yet implemented (needs a feature/backend agent):
1. A service recovery skill (e.g., exocomp.service.recover) that integrates the StateMachine
2. Logic to detect active/degraded service and move the A2A task to :input_required
3. Approval gate: binding approval to task+evidence, validation, expiry, replay protection
4. Evidence refresh immediately before executing a restart
5. Invalidating approval when service state changes (healthy/failed transitions)
6. Focused approval-flow tests: approve, deny, expiry, timeout, wrong approver/token, changed evidence, cancellation, duplicate approval
---
author: oompah
created: 2026-07-24 19:00
---
Focus handoff: frontend

Outcome: No frontend/UI work exists or is needed. This is a pure Elixir A2A backend project with no browser-facing components.

Relevant files, evidence, decisions:
- Searched entire workspace for *.html*, *.heex, *.css, *.js, *.ts, *.jsx, *.tsx, *live*.ex — found zero results.
- The only Plug usage is JSON HTTP endpoints for A2A protocol (not browser-facing).
- plans/milestone-4-service-recovery.md describes the full backend design with state machine, approval bindings, evidence freshness, audit trail.
- The StateMachine (EXOCOMP-30) is complete and includes :awaiting_approval state.
- The A2A TaskState has :input_required which should be used when service is active/degraded.

Remaining work:
1. Implement exocomp.service.recover skill that uses StateMachine to gate recovery on approval
2. When StateMachine enters :awaiting_approval, transition the A2A task to :input_required with impact/evidence in the status message
3. Implement approval binding: accept {:valid_approval, map()} with nonce, task_id, action_id, optional expires_at
4. Refresh evidence immediately before executing restart; if state changed → {:deny_or_expire_or_changed, reason}
5. Handle deny/timeout/expiry with auditable terminal escalation
6. Tests: approve, deny, expiry, timeout, wrong approver/token, changed evidence, healthy/failed transition, cancellation, duplicate approval

Recommended next focus: feature
---
author: oompah
created: 2026-07-24 19:01
---
Agent completed successfully in 214s (6565 tokens)
---
author: oompah
created: 2026-07-24 19:01
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 65, Tool calls: 55
- Tokens: 36 in / 6.5K out [6.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 34s
- Log: EXOCOMP-32__20260724T185729Z.jsonl
---
author: oompah
created: 2026-07-24 19:01
---
Focus handoff from `frontend` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 19:01
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 19:01
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-24 19:01
---
Understanding: Implement the backend-only active/degraded service recovery lifecycle. I will build on the existing Recovery.StateMachine and node approval gate, expose a service recovery skill through the A2A dispatcher, emit input-required approval context with exact impact/evidence, re-read evidence immediately before restart, reject stale/mismatched/replayed decisions without action, and cover approve, deny, expiry, timeout, identity/token mismatch, state drift, cancellation, and duplicates. I will use Makefile quality gates and preserve the existing one-attempt/audit invariants.
---
author: oompah
created: 2026-07-24 19:05
---
Discovery: Integrated the completed EXOCOMP-27 branch, which brings in the generic remediation lifecycle plus EXOCOMP-24's ApprovalGate/Verifier/PreconditionChecker/ReplayLedger and restricted Executor. The clean EXOCOMP-32 boundary is a service-specific recovery flow: Recovery.StateMachine owns legal/audited transitions; A2A Task exposes input_required with exact impact/evidence; ApprovalGate remains the sole approval-to-execution path. Its injected executor boundary lets this flow durably record the executing transition after token/precondition/replay checks and before the actual restart, without duplicating token validation.
---
author: oompah
created: 2026-07-24 19:17
---
Implementation: Added Exocomp.Node.Recovery.ApprovalRequired, a data-only A2A recovery flow for active/degraded services. It advances the recovery machine into awaiting_approval, exposes input_required with the exact disruption impact, full evidence, and approval bindings, validates the signed operator through ApprovalGate, refreshes evidence both before and inside the gate, persists execution intent before the restricted restart, verifies health, and emits terminal artifacts. Deny/timeout/expiry/evidence drift/healthy-or-failed transitions escalate with no action; invalid identity/token stays pending; replay/cancel are safe. Added 14 focused tests. Also completed the prerequisite branch integration by removing obsolete coordinator modules/tests that conflicted with EXOCOMP-27's replacement architecture.
---
author: oompah
created: 2026-07-24 19:17
---
Verification: Focused approval-flow suite passes (14 tests, 0 failures). Full host umbrella suite passes: bench 55, core 152, node 740, coordinator 280 = 1,227 tests, 0 failures, 10 excluded integration/systemd tests. Host format check and forced test compilation with warnings-as-errors pass. make fmt-check/test/lint were each invoked but cannot start their pinned container in this managed sandbox because rootless Podman cannot chmod /run/user/1000/libpod (read-only); equivalent host gates used Elixir 1.18/OTP 27 with the matching Erlang development header. git diff --check passes.
---
author: oompah
created: 2026-07-24 19:18
---
Completion: Delivered and pushed commit 0466ba8 on origin/epic-EXOCOMP-4. Active/degraded recovery now exposes an exact-evidence input_required approval task, accepts only the correctly bound operator token through the existing fail-closed ApprovalGate, refreshes preconditions immediately before execution, persists execution intent before restart, prevents replay, verifies health, and terminally audits denial/timeout/expiry/state changes/cancellation. Focused 14/14 tests and the full 1,227-test host suite pass; forced warnings-as-errors compile and format check pass. The pinned Make wrappers remain unavailable only because this sandbox's rootless Podman runtime directory is read-only. Worktree is clean and up to date with origin.
---
author: oompah
created: 2026-07-24 19:18
---
Implemented approval-required active/degraded service recovery with exact A2A impact/evidence, bound ApprovalGate execution, fresh precondition checks, audit-before-action, safe terminal outcomes, replay protection, and focused coverage.
---
author: oompah
created: 2026-07-24 19:18
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 0, Tool calls: 132
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 17m 39s
- Log: EXOCOMP-32__20260724T190140Z.jsonl
---
author: oompah
created: 2026-08-01 03:00
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-08-01 03:07
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 03:07
---
Focus: Completion Auditor
---
<!-- COMMENTS:END -->
