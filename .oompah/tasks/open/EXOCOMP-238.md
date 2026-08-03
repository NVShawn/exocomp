---
id: EXOCOMP-238
type: task
status: Open
priority: null
title: Document hierarchical management policy operations
parent: EXOCOMP-212
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-218
- EXOCOMP-224
- EXOCOMP-234
- EXOCOMP-237
labels: []
assignee: null
created_at: '2026-08-03T14:28:21.152567Z'
updated_at: '2026-08-03T15:56:32.863310Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 823f0f33e1c4a77b6db10f8c58ca0ace1142ccd17a26efaddc495abaac9fb769
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 99c81e41-1a83-4f75-8e11-db8457746457
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:56:22.112804+00:00'
  claim_expires_at: '2026-08-03T16:26:22.112804+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: c2845f01-779d-42ca-8a15-466ee8a38538
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable:
Write user-facing documentation for configuring, reviewing, troubleshooting, and safely rolling back hierarchical observe/manage policy.

Acceptance criteria:
- Explain all five scopes, precedence, the same-rank disagreement rule, and the implicit observe default with examples.
- Document administrator, operator, and viewer permissions for enabling or restricting manage mode.
- Describe lease duration, renewal, stale-policy behavior, and the status fields operators should inspect.
- Provide safe enablement, emergency restrict-to-observe, and rollback procedures.
- Document audit records and troubleshooting for rejected or unavailable actions.
- Link to the relevant Mission Control and node installation documentation without duplicating task tracking.

Tests:
- Run make check-links and make test-compliance.
- Verify every documented command and configuration key against the implemented interfaces.

Out of scope:
- Internal implementation design, which remains in the linked plan.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:56
---
Duplicate screening dispatched (profile: default, task remains Open)
---
<!-- COMMENTS:END -->
