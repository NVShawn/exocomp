---
id: EXOCOMP-32
type: feature
status: In Progress
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
assignee: null
created_at: '2026-07-23T19:10:47.855632Z'
updated_at: '2026-07-24T18:57:10.624264Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 5e30ed94-6ac7-4a07-9603-4659224ba31b
oompah.work_branch: epic-EXOCOMP-4
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
<!-- COMMENTS:END -->
