---
id: EXOCOMP-152
type: task
status: Open
priority: 1
title: Persist current cluster and node status
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-149
start_blocked_by: &id001
- EXOCOMP-194
labels: []
assignee: null
created_at: '2026-07-30T14:15:36.397265Z'
updated_at: '2026-08-01T12:28:44.228602Z'
work_branch: epic-EXOCOMP-131--task-EXOCOMP-152
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: b810f85a7e08d820682dae622de9369a8b323957fbc131cb44a49075d1c29fd6
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 618bce9c-9725-42fc-b618-8df9820aeaba
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:28:33.787829+00:00'
  claim_expires_at: '2026-08-01T12:58:33.787829+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 608724a7-d244-46c3-859d-feaaa351c481
oompah.work_branch: epic-EXOCOMP-131--task-EXOCOMP-152
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-131--task-EXOCOMP-152
  base_branch: epic-EXOCOMP-131
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:28:41.775935+00:00'
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Add organization-scoped cluster and node current-state schemas for connectivity, health, versions, capabilities, labels, node counts, and last contact.
- Reduce cluster.hello, heartbeat, and status.snapshot events into the materialized current view transactionally.
- Reject stale snapshots using sequence/observation ordering.

Acceptance:
- Reducer tests cover initial state, partial update, stale update, node removal/tombstone, reconnect, duplicate event, and organization isolation.
- Current state can be queried without scanning event history.

Out of scope: history checkpoints, incidents, and UI.
Quality gate: focused context tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: persist the current effective service expectation and health per organization/cluster/node/unit, including source set, health depth, recovery authority, profile version, observation time, and retirement state. EXOCOMP-194 supplies the protocol contract.
---
author: oompah
created: 2026-08-01 12:28
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:28
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
