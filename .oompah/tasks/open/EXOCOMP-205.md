---
id: EXOCOMP-205
type: task
status: Open
priority: 2
title: Document desired-state modes and Ceph profile operations
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-188
- EXOCOMP-195
- EXOCOMP-204
labels: []
assignee: null
created_at: '2026-07-30T21:38:37.688511Z'
updated_at: '2026-08-01T11:52:34.392163Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, operator documentation.

Deliverable: Add user-facing documentation for manual service lists, automatic enabled-service monitoring, Ceph profile activation, credential bootstrap, coverage errors, and safe restart behavior.

Acceptance criteria:
- Include validated configuration examples and v1-to-v2 upgrade guidance.
- Document the client.exocomp least-privilege cephx caps and secret-file permissions.
- Explain monitoring versus recovery authority and why automatic mode cannot broaden privileges.
- Include troubleshooting for unsupported nodes, topology mismatches, stale evidence, helper denial, and cooldown.
- State that broad Ceph repair remains unavailable.

Tests: Run make check-links, make test-compliance, and documentation fixture tests.

Out of scope: Implementing configuration, collectors, or repair actions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

