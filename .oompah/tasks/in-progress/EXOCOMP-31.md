---
id: EXOCOMP-31
type: feature
status: In Progress
priority: 1
title: Implement automatic recovery of an already-failed service
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-25
- EXOCOMP-27
- EXOCOMP-29
- EXOCOMP-30
labels: []
assignee: null
created_at: '2026-07-23T19:10:47.061070Z'
updated_at: '2026-07-25T02:02:34.713423Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: d5de278d-fa9c-4090-a05a-25b973eacf34
oompah.work_branch: epic-EXOCOMP-4
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Implement automatic recovery of an already-failed service.

Implementation
Connect fresh service evidence, structured restart proposal, deterministic policy, audit-before-action, exact executor, systemd verification, application health check, stability window, terminal artifact, and one-attempt cooldown for a failed allow-listed service.

Testing
Test happy path, service self-recovers before execution, state changes to active/degraded, restart command failure, active-but-unhealthy result, health timeout, audit failure, and stable completion.

Acceptance Criteria
- [ ] Only a currently inactive/failed allow-listed service restarts automatically.
- [ ] Exactly one restart occurs per recovery episode.
- [ ] Success requires systemd plus application health stability.
- [ ] Failure enters cooldown/escalation with complete audit.
- [ ] Focused recovery tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 02:02
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 02:02
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
