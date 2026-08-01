---
id: EXOCOMP-139
type: task
status: Open
priority: 2
title: Define Mission Control protocol envelopes and fixtures
parent: EXOCOMP-128
children: []
blocked_by:
- EXOCOMP-136
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:13:53.920011Z'
updated_at: '2026-08-01T14:43:42.792551Z'
work_branch: epic-EXOCOMP-128--task-EXOCOMP-139
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 30f251ab17bef99fc043239736ddfaccf7f3fd68f81a2ac814cfbcc7b19c132c
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 744464c1-54a1-42d0-a603-442826be5391
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:43:32.161356+00:00'
  claim_expires_at: '2026-08-01T15:13:32.161356+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 0d494ae8-7e89-4d17-9c45-d8ddb9f18fab
oompah.work_branch: epic-EXOCOMP-128--task-EXOCOMP-139
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-128--task-EXOCOMP-139
  base_branch: epic-EXOCOMP-128
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:43:40.444135+00:00'
---
## Summary

Plan: plans/mission-control.md, Connection and Delivery Protocol.

Deliverables:
- Add shared structs/codecs for schema-versioned cluster events, server commands, acknowledgements, session identifiers, event IDs, sequence numbers, timestamps, correlation IDs, and bounded payloads.
- Define the initial event and command kind allow-lists from the plan.
- Add valid JSON fixtures and table-driven invalid fixtures.

Acceptance:
- Valid fixtures round-trip without semantic loss.
- Unsupported schema versions, unknown kinds, missing IDs, invalid timestamps, and oversized payloads return bounded errors.
- Existing A2A types are reused rather than copied when they already express the domain.

Out of scope: sockets, persistence, event reduction, and command execution.
Quality gate: focused protocol tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension: keep this task focused on generic Mission Control envelopes. EXOCOMP-194 depends on it and adds service expectation, service health, and profile coverage event fixtures.
---
author: oompah
created: 2026-08-01 14:43
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:43
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
