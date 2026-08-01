---
id: EXOCOMP-166
type: task
status: Open
priority: 2
title: Build the cluster detail LiveView
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-164
- EXOCOMP-152
- EXOCOMP-153
- EXOCOMP-154
start_blocked_by: &id001
- EXOCOMP-152
- EXOCOMP-155
labels: []
assignee: null
created_at: '2026-07-30T14:16:59.969604Z'
updated_at: '2026-08-01T15:18:49.275606Z'
work_branch: epic-EXOCOMP-133--task-EXOCOMP-166
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: a122ac1299767d55f8cb09a8ce012dfc745109d5a470c7459330591a110cc534
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: b55635cc-9959-4985-9914-73344d673c7a
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T15:18:41.921275+00:00'
  claim_expires_at: '2026-08-01T15:48:41.921275+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: fd9d834f-375e-4ad8-80ae-369d50b7ca8a
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-166
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-166
  base_branch: epic-EXOCOMP-133
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:18:47.520736+00:00'
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Show cluster identity, labels, current nodes, capabilities, versions, health history summary, incidents, conversations, and recent audited actions.
- Add stable links to incident and conversation routes.
- Update node/connectivity/incident sections from PubSub after commit.

Acceptance:
- LiveView tests cover connected/disconnected clusters, mixed node health, missing history, pagination, updates, unknown ID, and organization isolation.
- No private certificate or secret field is rendered.

Out of scope: editing labels and starting chat.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: cluster detail must show effective services, manual/automatic/profile source badges, systemd versus application health depth, recovery authority, Ceph profile version and coverage, stale/unsupported states, and evidence timestamps.
---
author: oompah
created: 2026-08-01 15:18
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:18
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
