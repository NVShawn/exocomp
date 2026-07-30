---
id: EXOCOMP-163
type: task
status: Backlog
priority: 1
title: Revalidate and execute approved remedies inside the cluster
parent: EXOCOMP-132
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:22.081454Z'
updated_at: '2026-07-30T14:16:22.081454Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Typed Remedy Approval.

Deliverables:
- Handle the typed approval command in the coordinator.
- Recollect evidence, rerun deterministic local policy, and reject changed target, parameters, evidence, or policy.
- Sign the existing short-lived Ed25519 approval token locally and submit through existing node safety/idempotency boundaries.
- Report started, completed, failed, and verification-failed events with artifacts and correlation IDs.

Acceptance:
- Tests cover success, stale evidence, policy change, target/parameter mismatch, token expiry/replay, duplicate command, execution failure, verification failure, and restart recovery.
- Mission Control never receives the cluster approval key.

Out of scope: arbitrary actions and changing automatic failed-service recovery policy.
Quality gate: focused node/coordinator tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

