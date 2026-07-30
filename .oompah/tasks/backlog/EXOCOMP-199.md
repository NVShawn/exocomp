---
id: EXOCOMP-199
type: task
status: Backlog
priority: 1
title: Correlate Ceph topology with coordinator inventory nodes
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T21:38:23.958273Z'
updated_at: '2026-07-30T21:38:23.958273Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Ceph topology reconciliation.

Deliverable: Map authoritative Ceph daemon topology to node discoveries using stable inventory hostnames and reported daemon identities.

Acceptance criteria:
- Produce one deterministic mapping or a structured missing, ambiguous, conflicting-FSID, or orphan-daemon result.
- Nodes that support the profile but contain no Ceph units remain valid non-members.
- Older nodes that cannot inspect the declared profile degrade coverage explicitly.
- Derived daemon services enter the shared desired-service resolver with source cluster:ceph.

Tests: Cover exact and case-normalized hostname matches, missing hosts, duplicate matches, FSID mismatch, orphan local units, non-member nodes, and unsupported nodes; run make test.

Out of scope: Health severity, incident creation, credentials, and recovery.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

