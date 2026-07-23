---
id: EXOCOMP-10
type: feature
status: Backlog
priority: 1
title: Implement Linux and systemd diagnostic collectors
parent: EXOCOMP-1
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T19:08:55.388617Z'
updated_at: '2026-07-23T19:14:21.486928Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Implement Linux and systemd diagnostic collectors.

Implementation
Implement versioned CPU, memory, disk, uptime, and allow-listed systemd service collectors using /proc, /sys, filesystem APIs, and argv-only systemctl show; add explicit units, timestamps, partial errors, output limits, and timeouts; never use a shell.

Testing
Use fixture proc/sys files and stubbed process execution to test valid, partial, malformed, unavailable, timeout, large-output, and all relevant service states.

Acceptance Criteria
- [ ] Collectors return bounded versioned observations with explicit units.
- [ ] Partial failures preserve successful measurements.
- [ ] No caller or model input becomes a shell command or arbitrary service.
- [ ] Focused collector tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

