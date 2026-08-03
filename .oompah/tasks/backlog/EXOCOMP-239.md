---
id: EXOCOMP-239
type: task
status: Backlog
priority: null
title: Qualify two clusters on amd64 and arm64
parent: EXOCOMP-212
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-235
- EXOCOMP-236
- EXOCOMP-237
- EXOCOMP-238
labels: []
assignee: null
created_at: '2026-08-03T14:28:24.686582Z'
updated_at: '2026-08-03T14:32:29.390506Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable:
Run final acceptance qualification against two Mission Control-connected clusters, including amd64 and arm64 nodes, and retain evidence for every plan acceptance criterion.

Acceptance criteria:
- Exercise global, cluster, cluster/service, node, and node/service settings on both architectures.
- Demonstrate precedence and the node versus cluster/service observe-wins disagreement rule.
- Demonstrate that observe permits status, diagnostics, chat, and proposals while blocking actual mutations.
- Demonstrate at least one permitted typed systemd action and one permitted shipped cluster-profile action in manage mode.
- Interrupt connectivity long enough to expire a lease and verify every layer returns to observe.
- Verify policy source, effective mode, lease state, and denial reasons are visible in Mission Control.
- Attach repeatable commands, logs, and results to the task and record any failures as oompah follow-up tasks.

Tests:
- Run the documented qualification Makefile target or VM workflow on both architectures.
- Run make test, make fmt-check, make lint, make check-links, and make test-compliance before recording final results.

Out of scope:
- Fixing unrelated defects discovered during qualification; file them as separate oompah tasks.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

