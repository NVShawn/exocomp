---
id: EXOCOMP-186
type: epic
status: Open
priority: 1
title: 'M7J: Cluster profiles and Ceph v1'
parent: EXOCOMP-127
children:
- EXOCOMP-195
- EXOCOMP-196
- EXOCOMP-197
- EXOCOMP-198
- EXOCOMP-199
- EXOCOMP-200
- EXOCOMP-201
- EXOCOMP-202
- EXOCOMP-203
- EXOCOMP-204
- EXOCOMP-205
- EXOCOMP-206
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T21:35:55.625186Z'
updated_at: '2026-08-01T11:51:11.248772Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md and the approved three-path service desired-state extension from 2026-07-30.

Outcome: Add a package-shipped cluster-profile framework and a Ceph profile that is declared once on the coordinator, discovers node roles, evaluates authoritative cluster health with a read-only cephx identity, and safely restarts one already-failed expected daemon.

Required behavior:
- Only versioned profiles shipped in signed Exocomp packages are executable.
- Nodes require no operator-maintained Ceph service list.
- Missing support, credentials, or topology mappings degrade coverage and alert explicitly.
- The first remedy is limited to one failed-daemon restart with evidence, policy, audit, verification, and cooldown.
- Work is decomposed into focused child tasks suitable for a junior developer.

Out of scope: Active-daemon disruption, PG repair, OSD reweighting, maintenance flags, and arbitrary Ceph commands.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

