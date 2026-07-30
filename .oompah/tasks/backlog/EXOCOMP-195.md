---
id: EXOCOMP-195
type: task
status: Backlog
priority: 1
title: Add the shipped cluster-profile registry and version contract
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T21:38:14.294893Z'
updated_at: '2026-07-30T21:38:14.294893Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, cluster service path.

Deliverable: Add a behavior and registry for versioned cluster profiles compiled into signed Exocomp releases.

Acceptance criteria:
- A profile exposes ID, version, node-discovery capability, expected-service derivation, health reduction, supported typed actions, and redaction metadata.
- Unknown or unsupported profile versions return structured coverage errors.
- Local files and caller-supplied commands cannot register profiles.
- Node and coordinator Agent Cards advertise supported profile IDs and versions.

Tests: Add registry, duplicate-ID, unknown-version, capability-advertisement, and non-shipped-profile rejection tests; run make test.

Out of scope: Ceph parsing, systemd discovery, privileged execution, and Mission Control storage.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

