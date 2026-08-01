---
id: EXOCOMP-161
type: task
status: Open
priority: 1
title: Store and validate typed remedy proposals
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-158
- EXOCOMP-160
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:19.626537Z'
updated_at: '2026-08-01T12:52:17.944765Z'
work_branch: epic-EXOCOMP-132--task-EXOCOMP-161
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 74088b2caf2a8431cc204ab33f3062713035a5d1363667b0b053a1bd79b56b70
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: aeb53c3d-827b-404f-8e9a-6bdc103c01a8
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:52:07.339657+00:00'
  claim_expires_at: '2026-08-01T13:22:07.339657+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 208def74-9d2e-4847-b071-6f290270cc75
oompah.work_branch: epic-EXOCOMP-132--task-EXOCOMP-161
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-132--task-EXOCOMP-161
  base_branch: epic-EXOCOMP-132
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:52:15.949255+00:00'
---
## Summary

Plan: plans/mission-control.md, Typed Remedy Approval.

Deliverables:
- Add organization-scoped proposal records for IDs, cluster/node target, catalog action, validated parameters, evidence reference/hash, risk, expected disruption, rationale, policy result, and expiry.
- Validate proposals against the shared action catalog and immutable parameter schema before persistence.
- Link each proposal to its conversation message and correlation/task IDs.

Acceptance:
- Tests cover valid proposal, unknown action, caller-supplied command/path, invalid target/parameters, stale/missing evidence, duplicate ID, expiry, and organization mismatch.
- Persisting a proposal cannot execute it.

Out of scope: approval and coordinator execution.
Quality gate: focused schema/context tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:52
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:52
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
