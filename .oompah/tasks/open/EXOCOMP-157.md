---
id: EXOCOMP-157
type: task
status: Open
priority: 2
title: Group related incidents deterministically
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-154
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:42.626270Z'
updated_at: '2026-08-01T14:56:22.406212Z'
work_branch: epic-EXOCOMP-131--task-EXOCOMP-157
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 60e13a034173ec19764a3b705480fc7b6e53f9c2be98d31ebc428ce7f94b9ed7
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 6f7b5015-7d40-4e06-8169-b40f946367fd
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:56:14.542374+00:00'
  claim_expires_at: '2026-08-01T15:26:14.542374+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 8a3c3e96-b237-491d-9776-a306a9e84ed9
oompah.work_branch: epic-EXOCOMP-131--task-EXOCOMP-157
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-131--task-EXOCOMP-157
  base_branch: epic-EXOCOMP-131
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:56:20.580621+00:00'
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Add a pure grouping module using alert type, service, software version, and configured time window.
- Return group keys and display summaries without changing incident identity or state.
- Add query helpers for fetching related open/recent incidents within an organization.

Acceptance:
- Tests cover matching/nonmatching attributes, window boundaries, missing version/service, organization isolation, and deterministic ordering.
- No central inference call or causal claim is introduced.

Out of scope: incident UI and model-generated summaries.
Quality gate: focused grouping tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:56
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:56
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
