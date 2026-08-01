---
id: EXOCOMP-179
type: task
status: Open
priority: 1
title: Add shared Mission Control protocol contract tests
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-139
start_blocked_by: &id001
- EXOCOMP-194
labels: []
assignee: null
created_at: '2026-07-30T14:18:34.108558Z'
updated_at: '2026-08-01T11:49:57.756879Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, Test Strategy.

Deliverables:
- Create one fixture corpus consumed by Mission Control and coordinator tests for every event, command, acknowledgement, error, and supported schema version.
- Add contract cases for duplicate, out-of-order, sequence gap, oversized payload, unknown kind, unsupported version, and redaction.
- Make fixture drift fail with a clear field-level error.

Acceptance:
- The same fixtures pass in both applications.
- Mutating each required field produces the expected bounded failure.
- A Make target runs the contract suite without requiring live VMs.

Out of scope: sockets and end-to-end qualification.
Quality gate: new contract target plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: consume the shared fixtures from EXOCOMP-194 and verify service/profile snapshots, deltas, duplicates, ordering, unsupported versions, bounds, redaction, retirement, and reconstruction across coordinator and Mission Control.
---
<!-- COMMENTS:END -->
