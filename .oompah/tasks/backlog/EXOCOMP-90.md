---
id: EXOCOMP-90
type: feature
status: Backlog
priority: 1
title: Implement poll scheduling, backoff, and registry state transitions
parent: EXOCOMP-15
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T02:43:03.724012Z'
updated_at: '2026-07-24T02:43:03.724012Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Implement deterministic scheduling and node-state transition logic for the coordinator poller. Default to a 30-second interval with bounded configurable jitter; track last_attempted_contact, last_successful_contact, consecutive_failures, and next_eligible_poll_at in Exocomp.Coordinator.Registry; apply bounded exponential backoff for repeated unreachable/time-out/authentication failures; reset failures/backoff on recovery; and map probe results consistently to unknown, healthy, degraded, stale, or unreachable. Define and test the freshness thresholds that distinguish degraded/stale/unreachable, using injected clock/randomness so tests do not sleep. Ensure stale callbacks cannot overwrite a newer observation and emit transition audit events without exposing secrets. Add table-driven unit tests for initial scheduling, jitter bounds, every transition, timestamps, backoff cap, repeated failures, recovery, and late-result handling; run focused and affected Make gates.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

