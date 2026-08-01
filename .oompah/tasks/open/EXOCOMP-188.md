---
id: EXOCOMP-188
type: task
status: Open
priority: 1
title: Add coordinator inventory v2 service-monitoring fields
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-187
labels: []
assignee: null
created_at: '2026-07-30T21:36:57.890248Z'
updated_at: '2026-08-01T11:50:10.266760Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, three-path desired-state extension.

Deliverable: Extend the coordinator inventory parser with optional per-node manual service entries, optional automatic-mode enablement, and a root cluster-profile declaration.

Acceptance criteria:
- Version 2 validates exact .service names, boolean automatic enablement, and loopback HTTP health checks.
- Version 1 inventories still load with empty monitoring and profile defaults.
- Invalid replacements leave the active inventory unchanged and emit the existing rejection audit path.
- Parsed values are available through typed inventory structures.

Tests: Add focused parser tests for valid v1/v2 files and malformed names, URLs, booleans, profiles, duplicates, and atomic rejection; run make test.

Out of scope: Polling, systemd collection, Ceph logic, and Mission Control persistence.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

