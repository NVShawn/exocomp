---
id: EXOCOMP-20
type: chore
status: Open
priority: 1
title: Verify the M2 coordinator milestone
parent: EXOCOMP-2
children: []
blocked_by:
- EXOCOMP-13
- EXOCOMP-15
- EXOCOMP-17
- EXOCOMP-18
- EXOCOMP-19
labels:
- focus-complete:duplicate_detector
- focus-complete:test
assignee: null
created_at: '2026-07-23T19:09:33.364917Z'
updated_at: '2026-07-24T18:52:20.032971Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 4fbbb64c-c4f8-4861-b89d-1ffbd75c0453
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 20
  total_output_tokens: 4628
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 20
      output_tokens: 4628
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 20
    output_tokens: 4628
    cost_usd: 0.0
    recorded_at: '2026-07-24T18:49:33.675676+00:00'
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Verify the M2 coordinator milestone.

Implementation
Build a disposable coordinator plus at least three node fixtures; exercise inventory, DNS, polling, enrollment, renewal, cluster diagnostics, partial failure, cancellation, audit, and coordinator restart; record evidence for every M2 criterion.

Testing
Run all unit/integration tests and relevant Make gates, including token replay, wrong-root, slow node, unreachable node, and restart scenarios.

Acceptance Criteria
- [ ] Every M2-CRIT-* item has recorded pass/fail evidence.
- [ ] Multi-node discovery and diagnostics work after enrollment.
- [ ] Restart reconstructs state without losing durable audit.
- [ ] No M2 path invokes remediation.
- [ ] All quality gates pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:47
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:47
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 18:47
---
Understanding: I am the Duplicate Investigator for EXOCOMP-20 ('Verify the M2 coordinator milestone'). My role is to determine whether this task is a duplicate of an existing one before any implementation begins. I will search for tasks with similar keywords (M2, coordinator, milestone, verify) and review any candidates in detail.
---
author: oompah
created: 2026-07-24 18:49
---
Discovery: No duplicate confirmed. Searched plans/, docs/, README.md, WORKFLOW.md for M2, milestone, coordinator, verify keywords; reviewed all EXOCOMP-2 epic children in full (EXOCOMP-14 Done, EXOCOMP-15 Done, EXOCOMP-16 Done, EXOCOMP-17 Done, EXOCOMP-18 Done, EXOCOMP-19 Done). Closest structural analogue is EXOCOMP-13 ('Verify the M1 node-agent milestone') — same milestone-verification pattern but covers M1/node-agent, not M2/coordinator. EXOCOMP-20 uniquely owns end-to-end M2 acceptance evidence (M2-CRIT-1 through M2-CRIT-8): disposable coordinator fixture, 3+ node fixtures, inventory/DNS/polling/enrollment/renewal/diagnostics/partial-failure/cancellation/audit/restart scenarios, and all quality gates. No implementation task (EXOCOMP-14–19) provides this cross-cutting acceptance evidence.
---
author: oompah
created: 2026-07-24 18:49
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-20 is unique — no other task in the EXOCOMP graph exercises the end-to-end M2 coordinator acceptance criteria.

**Evidence reviewed (all candidates read in full):**
- EXOCOMP-13 (Merged): Verifies M1 node-agent milestone only; same verification pattern but different scope (node, not coordinator). Its acceptance evidence covers M1-CRIT-1..7 only.
- EXOCOMP-14 (Done): Coordinator inventory, registry, audit scaffold — unit-level foundation only; no multi-node integration fixture or M2-CRIT evidence.
- EXOCOMP-15 (Done): DNS discovery and concurrent node polling — covers M2-CRIT-2 implementation, but does not record pass/fail evidence for all 8 M2 criteria.
- EXOCOMP-16 (Done): Coordinator CA initialization and enrollment tokens — PKI-only scope.
- EXOCOMP-17 (Done): Node enrollment and certificate renewal — enrollment protocol implementation; no holistic M2 acceptance fixture.
- EXOCOMP-18 (Done): Coordinator diagnostic orchestration and audit — implementation + unit/integration coverage; no multi-node disposable fixture recording criterion evidence.
- EXOCOMP-19 (Done): Coordinator cluster A2A service — implementation + 83 focused tests; no cross-cutting M2 criterion evidence.
- No mention of another M2 verification or acceptance task found in plans/, docs/, or task graph.

**Relevant files/decisions:**
- plans/milestone-2-coordinator.md lines 182-195 — M2-CRIT-1 through M2-CRIT-8 acceptance criteria
- apps/exocomp_coordinator/ — all M2 implementation on branch epic-EXOCOMP-2
- apps/exocomp_node/ — node fixtures for multi-node testing
- Makefile — quality gate targets (make test, make lint, make fmt-check, make build)
- EXOCOMP-13 history (especially apps/exocomp_node/test/integration/m1_acceptance_test.exs) — direct pattern to follow for M2 acceptance test structure

**Remaining work/risks:**
1. Build a disposable coordinator fixture plus at least 3 node fixtures using test certs
2. Exercise and record evidence for M2-CRIT-1 (inventory), M2-CRIT-2 (concurrent polling), M2-CRIT-3 (enrollment), M2-CRIT-4 (renewal), M2-CRIT-5 (A2A cluster diagnosis), M2-CRIT-6 (restart reconstruction), M2-CRIT-7 (no remediation path), M2-CRIT-8 (all quality gates)
3. Include token replay, wrong-root, slow node, unreachable node, and restart scenarios
4. Run make test, make lint, make fmt-check, make build
5. All blockers (EXOCOMP-13, 15, 17, 18, 19) are now Done — prerequisite code is available on epic-EXOCOMP-2

**Recommended next focus:** test
---
author: oompah
created: 2026-07-24 18:49
---
Agent completed successfully in 109s (4648 tokens)
---
author: oompah
created: 2026-07-24 18:49
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 37, Tool calls: 25
- Tokens: 20 in / 4.6K out [4.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 49s
- Log: EXOCOMP-20__20260724T184748Z.jsonl
---
author: oompah
created: 2026-07-24 18:49
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 18:49
---
Agent dispatched (profile: quick)
---
author: oompah
created: 2026-07-24 18:49
---
Focus: Test Engineer
---
author: oompah
created: 2026-07-24 18:49
---
Understanding: I will verify M2 with a deterministic disposable coordinator and 3+ local node fixtures, covering inventory/DNS/polling, enrollment and renewal failures, cluster diagnostics including partial failure/cancellation, durable audit and restart reconstruction, and proof that no remediation path runs. I will follow the M1 acceptance-test pattern, record M2-CRIT-1..8 evidence, and run all affected Make targets.
---
author: oompah
created: 2026-07-24 18:51
---
Discovery: The checked-out managed worktree is clean at epic-EXOCOMP-2/a8f2e25, but the prerequisite implementation is not actually integrated. Current coordinator code only contains EXOCOMP-19's A2A surface; Inventory/Registry/Resolver/HealthPoller/Orchestrator/Audit/PKI/enrollment modules are absent. Those discovery/orchestration modules exist only on epic-EXOCOMP-18 (e32a175), PKI exists separately on epic-EXOCOMP-16 (9afb6f8) plus EXOCOMP-87 (1f3c323), and EXOCOMP-17's recorded history shows only the CSR-issuer child—no node enrollment client, atomic credential store, enrollment endpoint, renewal endpoint, or renewal scheduler. Therefore a truthful end-to-end M2 acceptance suite cannot yet compile or pass on this branch.
---
author: oompah
created: 2026-07-24 18:51
---
Verification: M2 acceptance execution is blocked before test implementation. Repository inspection confirms no apps/exocomp_coordinator test can exercise inventory/DNS/polling/orchestration/audit/PKI on current HEAD because their production modules are absent, and no node enrollment/renewal implementation exists anywhere in EXOCOMP-17's integrated history. Existing M1 and EXOCOMP-19 tests are not substitute evidence for M2-CRIT-1..8. No files were changed and no misleading passing gate result is claimed.
---
author: oompah
created: 2026-07-24 18:51
---
Focus handoff: test\n\nOutcome: Test design is blocked by missing prerequisite implementation/integration; no acceptance test was added because it would necessarily fail to compile or falsely mock away the milestone behavior.\n\nEvidence: Current HEAD epic-EXOCOMP-2/a8f2e25 lacks Inventory, Registry, Resolver, HealthPoller, Orchestrator, Audit, PKI, and enrollment/renewal modules. Discovery/orchestration live on epic-EXOCOMP-18/e32a175; PKI lives on epic-EXOCOMP-16/9afb6f8 and EXOCOMP-87/1f3c323. EXOCOMP-17 has no delivered node enrollment/renewal client, endpoints, atomic installer, or scheduler despite being marked Done. git status is clean.\n\nRemaining work/risks: A feature agent must integrate the completed M2 branches, resolve their application/codec conflicts with EXOCOMP-19, finish EXOCOMP-17's missing coordinator and node protocol, and run focused implementation tests. Then return to test focus to add the disposable 3+ node suite covering M2-CRIT-1..8, including replay, wrong root, slow/unreachable nodes, cancellation, durable restart audit, and remediation exclusion.\n\nRecommended next focus: feature.
---
author: oompah
created: 2026-07-24 18:52
---
Run #1 [attempt=1, profile=quick, role=fast -> Codex/default]
- Turns: 0, Tool calls: 18
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 2m 22s
- Log: EXOCOMP-20__20260724T184945Z.jsonl
---
author: oompah
created: 2026-07-24 18:52
---
Agent dispatched (profile: quick)
---
author: oompah
created: 2026-07-24 18:52
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 18:52
---
Agent completed successfully in 4s
---
author: oompah
created: 2026-07-24 18:52
---
Run #1 [attempt=1, profile=quick, role=fast -> Claude/default]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: normal, Duration: 4s
- Log: EXOCOMP-20__20260724T185213Z.jsonl
---
author: oompah
created: 2026-07-24 18:52
---
Agent completed without closing this issue (4s). Escalating from 'quick' to 'standard'. Retrying in 10s (1/3).
---
<!-- COMMENTS:END -->
