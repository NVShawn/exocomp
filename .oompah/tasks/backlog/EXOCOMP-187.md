---
id: EXOCOMP-187
type: task
status: Backlog
priority: 1
title: Integrate the three-path desired-state design into project plans
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T21:36:56.896701Z'
updated_at: '2026-07-30T21:36:56.896701Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md.

Deliverable: Update the internal roadmap documents so manual host services, automatic enabled-service discovery, and coordinator-declared cluster profiles form one coherent design.

Acceptance criteria:
- plans/exocomp.md summarizes all three paths.
- Milestone 2 owns inventory, discovery, and reconciliation behavior.
- Milestone 4 owns profile-authorized safe recovery.
- Mission Control owns reporting, persistence, incidents, and UI but not desired-state authority.
- The documents state that broader Ceph repairs remain a separate roadmap.

Tests: Run make check-links and make test-compliance.

Out of scope: Source-code, configuration-template, or tracker changes beyond documenting the approved design.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

