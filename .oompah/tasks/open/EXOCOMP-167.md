---
id: EXOCOMP-167
type: task
status: Open
priority: 2
title: Build the incident inbox and detail LiveViews
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-164
- EXOCOMP-156
- EXOCOMP-157
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:01.826681Z'
updated_at: '2026-08-01T15:21:06.672838Z'
work_branch: epic-EXOCOMP-133--task-EXOCOMP-167
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 042bbe211e5d1da761f0db322eab554f23801783fbc87fc2363f87df7bf1abfc
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 4960d32a-7409-406d-b28d-070a692ce218
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T15:20:59.211541+00:00'
  claim_expires_at: '2026-08-01T15:50:59.211541+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 34d5ee76-e05a-4435-b363-39379c173dfd
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-167
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-167
  base_branch: epic-EXOCOMP-133
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:21:04.450968+00:00'
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Add severity/status/cluster/label filters and pagination to the incident inbox.
- Add an incident timeline/detail view with evidence and related incidents.
- Add operator controls for acknowledge, assignment, snooze, and manual resolution with required reason.

Acceptance:
- LiveView tests cover filters, pagination, real-time open/reopen/resolve, each mutation, invalid transition, stale form, viewer denial, and organization isolation.
- Snoozed incidents remain queryable and display the wake time.

Out of scope: notifications and chat UI.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:21
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:21
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
