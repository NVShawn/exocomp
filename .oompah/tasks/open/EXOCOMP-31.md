---
id: EXOCOMP-31
type: feature
status: Open
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
updated_at: '2026-07-23T19:17:18.898736Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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

