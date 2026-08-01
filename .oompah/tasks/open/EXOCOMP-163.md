---
id: EXOCOMP-163
type: task
status: Open
priority: 1
title: Revalidate and execute approved remedies inside the cluster
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-162
- EXOCOMP-151
- EXOCOMP-145
start_blocked_by: &id001
- EXOCOMP-204
labels: []
assignee: null
created_at: '2026-07-30T14:16:22.081454Z'
updated_at: '2026-08-01T12:58:26.328222Z'
work_branch: epic-EXOCOMP-132--task-EXOCOMP-163
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 1173023bdda4fb86526e326c74b28a164e0f52226aa7a268a238fe0678df5fc9
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: ade9e21d-d735-43f4-8ec4-aa437cd0b80a
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:58:18.388749+00:00'
  claim_expires_at: '2026-08-01T13:28:18.388749+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: d3c575b2-9c36-4da6-b5e2-ba0a3999db9d
oompah.work_branch: epic-EXOCOMP-132--task-EXOCOMP-163
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-132--task-EXOCOMP-163
  base_branch: epic-EXOCOMP-132
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:58:24.069316+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: profile remedies must remain typed and cluster-local. Integrate the verified Ceph safe-restart result from EXOCOMP-204 without allowing Mission Control to supply service allow-lists, profile commands, or arbitrary argv.
---
author: oompah
created: 2026-08-01 12:58
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:58
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
