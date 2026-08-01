---
id: EXOCOMP-172
type: task
status: Open
priority: 1
title: Store encrypted webhook endpoint configuration
parent: EXOCOMP-134
children: []
blocked_by:
- EXOCOMP-141
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:36.185587Z'
updated_at: '2026-08-01T13:05:48.621452Z'
work_branch: epic-EXOCOMP-134--task-EXOCOMP-172
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 1457c029666336ab9687f1ee0b0ae7d6403cab50c3b23df4fd2f63d1543a99b7
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 862beb0c-b65e-4750-ae7f-1f1f79f4a43b
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:05:38.769514+00:00'
  claim_expires_at: '2026-08-01T13:35:38.769514+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 720037ef-83fc-4c12-a0b5-852b3b6a8f0d
oompah.work_branch: epic-EXOCOMP-134--task-EXOCOMP-172
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-134--task-EXOCOMP-172
  base_branch: epic-EXOCOMP-134
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:05:46.554356+00:00'
---
## Summary

Plan: plans/mission-control.md, Webhooks.

Deliverables:
- Add organization-scoped webhook endpoints with URL, subscribed event types, enabled state, encrypted HMAC secret, and timestamps.
- Generate a secret, show it once, and encrypt it using a configured deployment master key.
- Add admin-only create, update subscriptions, disable, and rotate-secret context functions.

Acceptance:
- Tests cover encryption round-trip, missing/wrong master key, HTTPS URL validation, disallowed/private destinations per configured policy, secret one-time display, rotation, roles, and organization isolation.
- Plaintext secrets are absent from database/log inspection.

Out of scope: HTTP delivery.
Quality gate: focused webhook-context tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:05
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:05
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
