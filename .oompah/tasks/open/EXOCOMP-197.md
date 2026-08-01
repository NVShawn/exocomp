---
id: EXOCOMP-197
type: task
status: Open
priority: 1
title: Collect Ceph health and topology JSON
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-196
labels: []
assignee: null
created_at: '2026-07-30T21:38:19.643459Z'
updated_at: '2026-08-01T14:05:38.141142Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-197
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: e43fd8d66a650d86835d45ffb8befd5268d0b21aa1ba70e941003d4313d4b394
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 49d211ea-81c3-42ef-b069-44ecc98ab12b
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:05:30.413706+00:00'
  claim_expires_at: '2026-08-01T14:35:30.413706+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 37da4bf8-aa3f-4e1c-a177-871d337efa89
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-197
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-197
  base_branch: epic-EXOCOMP-186
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:05:36.170487+00:00'
---
## Summary

Plan: plans/mission-control.md, Ceph profile evidence.

Deliverable: Implement an unprivileged coordinator collector that runs the fixed Ceph CLI with fixed read-only JSON commands.

Acceptance criteria:
- Collect overall health plus monitor, manager, OSD, MDS, and available gateway topology using fixed argv.
- Enforce timeout and output-size limits and never invoke a shell.
- Normalize supported Ceph JSON versions into a versioned internal evidence structure.
- Preserve partial command failures with timestamps and sanitized reasons.
- Never expose keyring contents or command environment values.

Tests: Parse fixture output for HEALTH_OK, HEALTH_WARN, HEALTH_ERR, empty clusters, malformed JSON, partial failures, timeout, and truncation; run make test.

Out of scope: Node matching, health policy, service restart, and arbitrary Ceph commands.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:05
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:05
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
