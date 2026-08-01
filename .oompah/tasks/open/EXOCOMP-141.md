---
id: EXOCOMP-141
type: task
status: Open
priority: 1
title: Enforce viewer, operator, and admin authorization
parent: EXOCOMP-129
children: []
blocked_by:
- EXOCOMP-140
- EXOCOMP-138
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:14:23.272282Z'
updated_at: '2026-08-01T11:50:45.330995Z'
work_branch: epic-EXOCOMP-129--task-EXOCOMP-141
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: e870e84d569c131f18582cc1b814f0f986b0048b3c84c378caefe54253873b4a
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 423b8bea-4277-41c9-adbe-6ce32172cd82
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T11:50:33.397090+00:00'
  claim_expires_at: '2026-08-01T12:20:33.397090+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 6bfba4dc-b650-4df8-abd0-c1bef7d41053
oompah.work_branch: epic-EXOCOMP-129--task-EXOCOMP-141
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-129--task-EXOCOMP-141
  base_branch: epic-EXOCOMP-129
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T11:50:42.087858+00:00'
---
## Summary

Plan: plans/mission-control.md, Organization and Operator Identity.

Deliverables:
- Add operator identity and role-binding schemas scoped to organization_id.
- Map configured OIDC claims/groups to viewer, operator, or admin.
- Add plugs/on_mount hooks and context-level authorization functions for read, operate, and administer actions.
- Add a helper that records the stable OIDC subject and correlation ID for mutations.

Acceptance:
- A role matrix test covers every allowed and denied operation.
- Removing a UI control does not bypass context authorization.
- Cross-organization role bindings fail closed.

Out of scope: feature-specific mutations and admin pages.
Quality gate: focused authorization tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 11:50
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 11:50
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
