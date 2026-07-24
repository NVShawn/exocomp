---
id: EXOCOMP-101
type: feature
status: Backlog
priority: 1
title: Orchestrate bounded diagnostic fan-out and partial results
parent: EXOCOMP-18
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T04:29:36.504474Z'
updated_at: '2026-07-24T04:29:36.504474Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Build the coordinator orchestrator that selects inventory nodes, dispatches one idempotent diagnostic A2A task per node through the client adapter, and collects terminal results under bounded concurrency and an overall/per-node deadline. Aggregate an explicit success or failure entry for every targeted node; slow, unreachable, rejected, malformed, or failed nodes must not erase successful observations. Persist all lifecycle updates through the volatile task store and cap returned artifacts/output. Add focused tests for three-node success, partial node failure, unavailable node, timeout, concurrency limits, and late-result handling.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

