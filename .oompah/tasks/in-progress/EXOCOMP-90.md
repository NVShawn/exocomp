---
id: EXOCOMP-90
type: feature
status: In Progress
priority: 1
title: Implement poll scheduling, backoff, and registry state transitions
parent: EXOCOMP-15
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T02:43:03.724012Z'
updated_at: '2026-07-24T02:54:11.973463Z'
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
author: oompah
created: 2026-07-24 02:53
---
Discovery: No duplicate confirmed. The closest reviewed tasks were EXOCOMP-15 (parent epic), EXOCOMP-14 (completed Registry/Audit scaffold), EXOCOMP-89 (mTLS probe boundary and typed outcomes), EXOCOMP-91 (bounded concurrent poll execution), and EXOCOMP-92 (cross-component integration coverage). EXOCOMP-90 is the intentionally decomposed child that uniquely owns deterministic scheduling, backoff, freshness/state transitions, timestamps, stale-result protection, and transition-audit unit behavior. The milestone plan's Node State/Audit/Test Strategy sections match that boundary.
---
author: oompah
created: 2026-07-24 02:54
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no duplicate; EXOCOMP-90 remains a distinct implementation child of EXOCOMP-15.

Evidence: Repository search covered poll/scheduling/backoff/registry-state/timestamp/stale-callback/audit terms across the available plans/docs; this checkout has no .oompah/tasks directory, so full candidate descriptions/comments were read through tracker views. EXOCOMP-14 provides the existing ETS Registry and redacted Audit infrastructure but no poll scheduling/state machine. EXOCOMP-89 produces typed authenticated probe outcomes and safely adopts addresses. EXOCOMP-91 consumes EXOCOMP-90's scheduling/state-transition API while owning worker concurrency/timeouts/isolation. EXOCOMP-92 verifies the combined system. plans/milestone-2-coordinator.md Node State specifies the exact EXOCOMP-90 fields, 30-second jittered interval, exponential backoff, and reachability states; Audit/Test Strategy requires redacted poll-transition events and unit state/schedule coverage.

Relevant files/decisions: plans/milestone-2-coordinator.md sections Node State, Audit, and Test Strategy; implementation should extend Exocomp.Coordinator.Registry and reuse Exocomp.Coordinator.Audit from EXOCOMP-14. Keep scheduling deterministic through injected clock/randomness and reject late observations with an ordering token or attempt timestamp.

Remaining work/risks: Implement and test scheduling, bounded jitter/backoff, freshness thresholds, all state/timestamp transitions, recovery, stale-result rejection, and redacted audit emissions. Coordinate the public outcome contract with EXOCOMP-89 and the due-node/concurrency consumer with EXOCOMP-91. Recommended next focus: feature.
---
<!-- COMMENTS:END -->
