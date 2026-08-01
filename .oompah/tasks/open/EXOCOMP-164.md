---
id: EXOCOMP-164
type: task
status: Open
priority: 2
title: Build the authenticated LiveView shell and navigation
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-136
- EXOCOMP-140
- EXOCOMP-141
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:55.693389Z'
updated_at: '2026-08-01T14:59:57.149193Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: cf7a5bbd6f1c40fbea90a4613c484094d34e5df050fbdd873c744755110e5d04
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 13e0cb12-d16f-4a4f-ad78-134f5b533d32
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:59:56.405087+00:00'
  claim_expires_at: '2026-08-01T15:29:56.405087+00:00'
  retry_count: 0
  retry_after: null
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Add the authenticated root layout, navigation, flash/error handling, organization context, and role-aware route guards.
- Add reusable components for connectivity, health, severity, timestamps, empty states, and loading/error states.
- Redirect unauthenticated users through OIDC and show a bounded forbidden page for denied roles.

Acceptance:
- LiveView tests cover unauthenticated, viewer, operator, and admin navigation.
- Organization and actor identity survive reconnect without being accepted from client parameters.
- Accessibility checks cover landmarks, focus, labels, and keyboard navigation.

Out of scope: feature pages.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

