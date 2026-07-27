---
id: EXOCOMP-126
type: task
status: Backlog
priority: 1
title: Complete failed-service recovery through the A2A workflow
parent: null
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-27T16:09:25.749059Z'
updated_at: '2026-07-27T16:09:25.749059Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Triggered by: EXOCOMP-124

Close M4-CRIT-2. The recovery engine, restricted systemd execution, live fixture recovery, verification, and audit are on main, but the accepted recovery is invoked directly rather than through a complete authenticated A2A task workflow. Wire detection/diagnosis/recovery through the node and coordinator A2A surfaces, add end-to-end coverage using the fixture service, run relevant Make gates, and merge the evidence to main.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

