---
id: EXOCOMP-206
type: task
status: Open
priority: 2
title: Qualify three-path monitoring and Ceph safe restart in VMs
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-194
- EXOCOMP-204
- EXOCOMP-205
- EXOCOMP-155
- EXOCOMP-166
labels: []
assignee: null
created_at: '2026-07-30T21:38:38.730648Z'
updated_at: '2026-08-01T11:52:36.329005Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, desired-state and Ceph qualification.

Deliverable: Add a disposable VM qualification scenario covering manual, automatic, and cluster-derived service expectations plus one safe failed Ceph daemon restart.

Acceptance criteria:
- Declare the Ceph profile once on the coordinator and do not maintain per-node Ceph service lists.
- Discover roles across a three-node Ceph cluster and report complete coverage.
- Demonstrate manual and automatic expectations composing with Ceph-derived expectations.
- Fail one expected daemon, open one deduplicated incident, restart exactly once, verify stable Ceph health, and record the full audit timeline.
- Exercise disconnect/replay without duplicate incidents or actions and qualify shipped helper artifacts on amd64 and arm64.

Tests: Add a Make target for the scenario and publish bounded qualification evidence using existing release conventions.

Out of scope: Performance soak and broad Ceph repair operations.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

