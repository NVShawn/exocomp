---
id: EXOCOMP-165
type: task
status: Open
priority: 2
title: Build the fleet overview LiveView
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-164
- EXOCOMP-152
- EXOCOMP-155
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:58.020040Z'
updated_at: '2026-08-01T15:14:24.036147Z'
work_branch: epic-EXOCOMP-133--task-EXOCOMP-165
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 8bdc46b38dfb6fd4d3ffb049596cc67c32cbca1a319939044eb2391e7f82a71f
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 8f889175-4350-49e3-9bed-8ca26813dd36
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T15:14:14.486877+00:00'
  claim_expires_at: '2026-08-01T15:44:14.486877+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 348efd6a-e30c-42e8-9612-0a34e4c4924f
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-165
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-165
  base_branch: epic-EXOCOMP-133
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:14:21.668454+00:00'
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Render cluster connectivity, health/severity counts, versions, node counts, labels, last contact, and open incident counts.
- Add organization-scoped filters and deterministic sorting.
- Subscribe to committed PubSub updates and update only affected rows.

Acceptance:
- LiveView tests cover empty/loading/error states, filters, sorting, connect/disconnect updates, health updates, and organization isolation.
- A disconnected cluster is visually distinct from a healthy connected cluster.
- Viewer access is read-only.

Out of scope: cluster detail and incident mutations.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:14
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:14
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
