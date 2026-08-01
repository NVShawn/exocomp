---
id: EXOCOMP-27
type: feature
status: In Validation
priority: 1
title: Integrate remediation lifecycle with A2A tasks and audit
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-18
- EXOCOMP-22
- EXOCOMP-24
- EXOCOMP-25
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:10:13.340897Z'
updated_at: '2026-08-01T03:00:11.109734Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 0bd07bc1-c000-4244-90c9-5047137b4b45
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 17
  total_output_tokens: 4970
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 17
      output_tokens: 4970
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 17
    output_tokens: 4970
    cost_usd: 0.0
    recorded_at: '2026-07-24T18:26:30.532188+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-5a1cb7b6399d
    project_id: proj-c260b117
    task_id: EXOCOMP-27
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 02a81a2ed71ea4ec7b5ed3b6886edbe9c99e1ebf643bae0d443b5d4f5bb69ecb
    attempts: []
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-01T03:00:08.582687+00:00'
  attempt_history: []
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Integrate remediation lifecycle with A2A tasks and audit.

Implementation
Connect structured proposals, fresh evidence, policy decisions, input-required approval state, execution, verification, and terminal artifacts; enforce audit-before-action; redact model output; expose typed remediation skills without exposing executors directly.

Testing
Test allow, deny, approval/deny/timeout, stale evidence, audit unavailable before action, post-action audit failure, cancellation, malformed proposal, model bypass attempts, and correlated artifact history.

Acceptance Criteria
- [ ] LLM proposals cannot skip validation, approval, execution restrictions, or verification.
- [ ] State-changing work does not start without durable intent audit.
- [ ] Every transition is represented in A2A task history and correlated audit.
- [ ] Focused lifecycle tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:24
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:24
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 18:25
---
Understanding: Investigating whether EXOCOMP-27 ('Integrate remediation lifecycle with A2A tasks and audit') is a duplicate of an existing task. I will search existing tasks and design docs covering remediation lifecycle, A2A task integration, audit-before-action, approval state transitions, proposal validation, and correlated audit trails before any implementation proceeds.
---
author: oompah
created: 2026-07-24 18:26
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-27 is a unique task with no coverage overlap in the existing task graph.

**Evidence reviewed (all candidates with full tracker reads):**

- **EXOCOMP-21** (Done): Defines action/evidence/risk/data-classification *types*. The foundational type system only — no lifecycle, no A2A wiring, no audit trail. A prerequisite for EXOCOMP-27, not a duplicate.

- **EXOCOMP-22** (Done): Implements deterministic least-impact *policy selection* (filtering, ranking, deny/allow/approval_required output). The policy decision engine only — does not connect to A2A task protocol, approval state machine, or correlated audit.

- **EXOCOMP-23** (Done): Implements coordinator-side signed approval issuance and operator approve/deny commands. Token creation only — does not wire into A2A task input-required state or drive the full remediation lifecycle.

- **EXOCOMP-24** (Done): Implements node-side approval token verification, precondition re-check, and durable replay ledger. Verification gate only — does not orchestrate the proposal→policy→approval→execution→verification→artifact lifecycle.

- **EXOCOMP-25** (Done): Implements unprivileged systemd executor, sudoers policy, per-target serialization, and post-action verifier. Execution infrastructure only — does not coordinate A2A task state transitions or correlated audit.

- **EXOCOMP-26** (Done): Implements bounded system-log cleanup action (disk-pressure evidence, installed bounds, pre/post audit). Specific cleanup action only — not the lifecycle integration layer.

- **EXOCOMP-28** (Open): M3 acceptance verification (runs adversarial/integration suites). Testing only, no implementation.

- **EXOCOMP-18** (Done, M2): Coordinator diagnostic task orchestration and audit. Covers *diagnostics*, not remediation — different domain, different safety requirements, different approval model.

- Prior duplicate_detector runs on **EXOCOMP-25** and **EXOCOMP-22** both explicitly listed EXOCOMP-27 as a *distinct sibling* covering 'lifecycle integration — A2A integration, not executor' with zero overlap.

**What makes EXOCOMP-27 unique:** It is the integration layer that wires all M3 components together via the A2A task protocol. Specifically:
1. Accepts structured LLM proposals via A2A skill interface (no direct executor exposure)
2. Drives the A2A task through states: working → input-required (approval) → working (post-approval) → completed/failed
3. Enforces audit-before-action (state-changing work blocked if intent audit cannot be durably written)
4. Correlates every lifecycle transition (proposal, evidence, policy, approval, execution, verification, artifact) under a single correlation ID in audit
5. Redacts raw model output per configured rules
6. Records terminal artifacts and correlated history for every completed remediation

**Relevant files for feature agent:**
- `plans/milestone-3-safety-validation.md` — Audit and Failure Behavior, Architecture diagram, Acceptance Criteria M3-CRIT-8
- `apps/exocomp_coordinator/lib/exocomp/coordinator/` — coordinator audit, supervisor, A2A server (from M2 work)
- `apps/exocomp_node/lib/exocomp/node/safety/` — types from EXOCOMP-21
- `apps/exocomp_node/lib/exocomp/node/` — executor, approval gate (from EXOCOMP-22–25)
- `apps/exocomp_core/` — shared A2A protocol types
- Branches on origin: EXOCOMP-21–26 all Done; confirm epic-EXOCOMP-3 includes their work

**Remaining work and risks (for feature agent):**
1. Implement coordinator-side remediation A2A skill handler: validates proposals, drives policy, issues approval, tracks task state transitions
2. Implement audit-before-action enforcement: block state-changing work if intent audit write fails
3. Implement correlated artifact recording: every lifecycle event shares correlation ID in audit
4. Redact model output per configured rules before audit/history recording
5. Expose typed remediation skill interface without exposing executors directly
6. Test all scenarios: allow, deny, approval/approve/deny/timeout, stale evidence, audit unavailable, post-action audit failure, cancellation, malformed proposal, model bypass attempts, correlated artifact history
7. Run make test, make lint, make fmt-check

**Recommended next focus:** feature
---
author: oompah
created: 2026-07-24 18:26
---
Agent completed successfully in 122s (4987 tokens)
---
author: oompah
created: 2026-07-24 18:26
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 34, Tool calls: 23
- Tokens: 17 in / 5.0K out [5.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 2s
- Log: EXOCOMP-27__20260724T182432Z.jsonl
---
author: oompah
created: 2026-07-24 18:26
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 18:26
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:26
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-24 18:27
---
Understanding: Implement the coordinator-side remediation integration that accepts only typed proposals, refreshes and validates evidence, applies policy and approval gates, enforces durable intent audit before any mutation, executes through the restricted node interface, verifies outcomes, and records redacted/correlated A2A history and terminal artifacts. I will first map the existing M2 A2A and M3 safety components, then add focused lifecycle/adversarial tests and run affected Make targets.
---
author: oompah
created: 2026-07-24 18:35
---
Discovery: The prerequisite branches were not present in this stale epic worktree, so I integrated the completed M2 coordinator audit/orchestration and M3 policy, approval-gate/executor, and vacuum-evidence branches first. The clean integration boundary is coordinator-side: a public typed remediation skill/lifecycle calls a trusted adapter for proposal validation, fresh evidence, deterministic policy, restricted execution, and verification; the adapter does not expose command/executable/path primitives. Existing Coordinator.Audit provides durable redacted correlated events, and A2A Task supports input_required/history/artifacts.
---
author: oompah
created: 2026-07-24 18:35
---
Implementation: Added RemediationLifecycle plus a narrow RemediationAdapter behavior and fail-closed default. The lifecycle creates correlated A2A tasks, records every state transition in history, validates proposals, refreshes evidence, applies allow/deny/input-required approval decisions, requires durable remediation_intent_accepted audit before invoking mutation, verifies after execution, emits terminal artifacts, handles approval deny/timeout/cancel, records post-action audit reconciliation without retry, and redacts/bounds raw model output. Added the supervised typed remediation.execute skill without exposing executors.
---
author: oompah
created: 2026-07-24 18:37
---
Verification: Focused remediation lifecycle suite passes (13 tests, 0 failures); all coordinator tests pass (280 tests, 0 failures); coordinator compiles with warnings-as-errors; repository format check passes. The pinned Make targets were attempted but this managed sandbox cannot start rootless Podman because /run/user/1000/libpod is read-only and user-namespace clone is denied. I ran the equivalent coordinator gates with the available host toolchain (temporarily relaxing only the local version assertion, then restoring it); full umbrella host compilation is additionally blocked by a missing Erlang public_key include. No product source workaround was retained.
---
author: oompah
created: 2026-07-24 18:39
---
Completion: Delivered and pushed commit 7813d30 on origin/EXOCOMP-27. The coordinator now exposes a supervised typed remediation.execute A2A lifecycle with fail-closed adapter boundaries, durable audit-before-action, input-required approvals, restricted execution/verification sequencing, redacted bounded model output, correlated transition history, terminal artifacts, cancellation/timeouts, and post-action reconciliation without retry. Focused suite: 13/13 passing; coordinator suite: 280/280 passing; coordinator warnings-as-errors compile and format check pass. Branch is clean and up to date with origin.
---
author: oompah
created: 2026-07-24 18:39
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 0, Tool calls: 102
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 12m 54s
- Log: EXOCOMP-27__20260724T182646Z.jsonl
---
author: oompah
created: 2026-07-24 18:39
---
Integrated the typed remediation lifecycle with correlated A2A history/artifacts and durable audit-before-action; added approval, failure, cancellation, redaction, bypass, and reconciliation coverage; pushed commit 7813d30 to origin/EXOCOMP-27.
---
author: oompah
created: 2026-08-01 03:00
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
<!-- COMMENTS:END -->
