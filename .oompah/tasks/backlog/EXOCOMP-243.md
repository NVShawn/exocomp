---
id: EXOCOMP-243
type: bug
status: Backlog
priority: 2
title: Remove peer-completion race from discovery polling test
parent: null
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T17:22:52.388724Z'
updated_at: '2026-08-03T17:22:52.388724Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
---
## Summary

Triggered by: EXOCOMP-92

The full make test gate is nondeterministic in apps/exocomp_coordinator/test/exocomp/coordinator/multi_node_discovery_polling_test.exs. The test 'unreachable node retains previously verified addresses and increments failure counter' waits only for the unreachable echo result, then immediately asserts that independently scheduled foxtrot is healthy. Under valid task interleavings foxtrot remains :unknown for that instant and the gate fails. Synchronize on the peer outcome (or complete poller drain) before asserting it, while retaining assertions that the unreachable node preserves its verified address and increments its failure counter. Reproduce with repeated focused runs and verify make test and make lint pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

