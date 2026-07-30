---
id: EXOCOMP-139
type: task
status: Backlog
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
updated_at: '2026-07-30T21:41:19.821554Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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
<!-- COMMENTS:END -->
