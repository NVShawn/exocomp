---
id: EXOCOMP-204
type: task
status: Backlog
priority: 1
title: Verify Ceph daemon recovery and enforce cooldown
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T21:38:35.429036Z'
updated_at: '2026-07-30T21:38:35.429036Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Ceph recovery verification.

Deliverable: Add post-action verification and terminal audit behavior for the safe Ceph daemon restart.

Acceptance criteria:
- Recollect systemd and Ceph evidence after execution and across the configured stability window.
- Complete only when the daemon is running, mapped to the same topology identity, and cluster evidence is no worse.
- Verification failure enters cooldown and cannot trigger a second automatic restart in the same episode.
- Node or coordinator restart reconciles durable execution state without repeating the action.
- Emit correlated completed, failed, verification_failed, and cooldown evidence.

Tests: Cover successful recovery, systemd-only recovery, worsened Ceph health, identity change, flapping, process restart, cooldown expiry, and audit failure; run make test.

Out of scope: Mission Control rendering and additional Ceph repair actions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

