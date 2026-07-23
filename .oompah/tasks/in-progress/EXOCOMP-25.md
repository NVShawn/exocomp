---
id: EXOCOMP-25
type: feature
status: In Progress
priority: 1
title: Implement unprivileged systemd executor and exact sudoers policy
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-21
labels: []
assignee: null
created_at: '2026-07-23T19:10:11.402376Z'
updated_at: '2026-07-23T22:15:01.475395Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 0e7858e8-d480-4722-b13d-041b53e156dd
oompah.work_branch: epic-EXOCOMP-3
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Implement unprivileged systemd executor and exact sudoers policy.

Implementation
Implement action execution under a dedicated unprivileged account; generate exact per-service sudoers entries; map installed action IDs to fixed executable/argv/environment/timeouts; serialize per target; capture bounded output; invoke post-action verification; expose no generic command.

Testing
Test service allow-list, unknown units, shell metacharacters, argv/environment injection, executable path changes, timeout, oversized output, sudo denial, concurrent targets, and generated policy snapshots.

Acceptance Criteria
- [ ] Node release does not run as root.
- [ ] Only installed allow-listed services can reach systemctl.
- [ ] No request/model field becomes shell syntax or arbitrary argv.
- [ ] Privilege policy is minimal and deterministic.
- [ ] Focused executor tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 22:14
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:15
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
