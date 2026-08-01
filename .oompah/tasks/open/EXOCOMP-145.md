---
id: EXOCOMP-145
type: task
status: Open
priority: 1
title: Add optional Mission Control coordinator configuration
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-139
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:01.267951Z'
updated_at: '2026-08-01T12:09:15.216359Z'
work_branch: epic-EXOCOMP-130--task-EXOCOMP-145
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 30ddb9d816071439d009ad0069001d7e1303da35f2e4e0d737ab3be8cb53c5d5
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: b538f6ff-fb80-49cd-9bb2-d32e1dc8a10b
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:09:04.310409+00:00'
  claim_expires_at: '2026-08-01T12:39:04.310409+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 1277172c-6320-4be4-ae00-5dfe4dc12787
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-145
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-145
  base_branch: epic-EXOCOMP-130
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:09:13.107153+00:00'
---
## Summary

Plan: plans/mission-control.md, Rollout and Connection Protocol.

Deliverables:
- Add a versioned coordinator configuration block for Mission Control URL, trust root, client certificate/key paths, heartbeat interval, reconnect bounds, and outbox path.
- Validate paths, TLS settings, and numeric bounds at startup.
- Start the Mission Control client supervision subtree only when the block is present and enabled.

Acceptance:
- Existing coordinator behavior is unchanged when configuration is absent.
- Invalid partial configuration fails with actionable bounded errors.
- Tests prove Mission Control disablement cannot stop local inventory, diagnostics, or recovery.

Out of scope: network connections and enrollment.
Quality gate: focused configuration/supervision tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:09
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:09
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
