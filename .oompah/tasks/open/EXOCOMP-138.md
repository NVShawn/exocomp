---
id: EXOCOMP-138
type: task
status: Open
priority: 2
title: Add organizations and mandatory organization scoping
parent: EXOCOMP-128
children: []
blocked_by:
- EXOCOMP-137
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:13:52.527968Z'
updated_at: '2026-08-01T14:41:27.354085Z'
work_branch: epic-EXOCOMP-128--task-EXOCOMP-138
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: b57985a586a1fecab1d858a2031f9281b4717e71f7474e35c4c224a033076109
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: da31f2cc-b585-4e3b-b09a-614664364aa8
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:41:17.168162+00:00'
  claim_expires_at: '2026-08-01T15:11:17.168162+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 4005d60b-9a0d-4897-8883-921a94cd9b05
oompah.work_branch: epic-EXOCOMP-128--task-EXOCOMP-138
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-128--task-EXOCOMP-138
  base_branch: epic-EXOCOMP-128
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:41:24.669330+00:00'
---
## Summary

Plan: plans/mission-control.md, Organization and Operator Identity.

Deliverables:
- Add the organizations table and schema with a stable generated identifier.
- Add a test/dev seed for the initial organization.
- Add a small reusable scoping helper that requires organization_id for tenant-owned queries and inserts.
- Add foreign-key and unique-constraint examples used by later contexts.

Acceptance:
- Inserts without an organization fail closed.
- Tests prove records from one organization cannot be read, updated, or deleted through another organization scope.
- No global unscoped list function is exposed.

Out of scope: tenant administration UI and billing.
Quality gate: focused Ecto tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:41
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:41
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
