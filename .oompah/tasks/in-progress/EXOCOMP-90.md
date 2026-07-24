---
id: EXOCOMP-90
type: feature
status: In Progress
priority: 1
title: Implement poll scheduling, backoff, and registry state transitions
parent: EXOCOMP-15
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T02:43:03.724012Z'
updated_at: '2026-07-24T02:52:59.227575Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: c958afc9-f12d-4a01-8f3d-b9c5ce7f61f2
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Implement deterministic scheduling and node-state transition logic for the coordinator poller. Default to a 30-second interval with bounded configurable jitter; track last_attempted_contact, last_successful_contact, consecutive_failures, and next_eligible_poll_at in Exocomp.Coordinator.Registry; apply bounded exponential backoff for repeated unreachable/time-out/authentication failures; reset failures/backoff on recovery; and map probe results consistently to unknown, healthy, degraded, stale, or unreachable. Define and test the freshness thresholds that distinguish degraded/stale/unreachable, using injected clock/randomness so tests do not sleep. Ensure stale callbacks cannot overwrite a newer observation and emit transition audit events without exposing secrets. Add table-driven unit tests for initial scheduling, jitter bounds, every transition, timestamps, backoff cap, repeated failures, recovery, and late-result handling; run focused and affected Make gates.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:52
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:52
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 02:52
---
Understanding: This run is limited to duplicate screening. I will search task history and design/docs for coordinator polling, scheduling, backoff, registry transitions, stale callbacks, and audit events; read plausible task candidates in full; then archive only if the same deliverable is already covered, otherwise hand off with evidence to an implementation focus.
---
<!-- COMMENTS:END -->
