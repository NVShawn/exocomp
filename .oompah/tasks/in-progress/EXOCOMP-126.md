---
id: EXOCOMP-126
type: task
status: In Progress
priority: 1
title: Complete failed-service recovery through the A2A workflow
parent: null
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-27T16:09:25.749059Z'
updated_at: '2026-07-27T16:16:06.327227Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: f4011013-6a4f-4a33-a9df-45d3fefea971
---
## Summary

Triggered by: EXOCOMP-124

Close M4-CRIT-2. The recovery engine, restricted systemd execution, live fixture recovery, verification, and audit are on main, but the accepted recovery is invoked directly rather than through a complete authenticated A2A task workflow. Wire detection/diagnosis/recovery through the node and coordinator A2A surfaces, add end-to-end coverage using the fixture service, run relevant Make gates, and merge the evidence to main.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-27 16:15
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-27 16:15
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-27 16:16
---
Understanding: duplicate screening only. I will search tracker/docs for existing failed-service recovery and authenticated A2A workflow work, then inspect each plausible task's full description/comments before deciding whether EXOCOMP-126 duplicates prior scope. I will not implement code during this focus.
---
<!-- COMMENTS:END -->
