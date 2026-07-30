---
id: EXOCOMP-180
type: task
status: Backlog
priority: 1
title: Add reconnect and multi-replica integration tests
parent: EXOCOMP-135
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:18:37.798315Z'
updated_at: '2026-07-30T14:18:37.798315Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Test Strategy.

Deliverables:
- Build an integration harness with PostgreSQL, one coordinator, and two Mission Control replicas.
- Test disconnect/reconnect, durable event replay, command replay, duplicate delivery, sequence gap, certificate revocation, and connection-owner replica termination.
- Assert no lost durable event and no duplicate command execution.

Acceptance:
- The harness is deterministic, noninteractive, bounded by timeouts, and leaves no background processes.
- It proves WebSocket affinity is not required for correctness.
- A Make target runs it in CI-capable containers.

Out of scope: model inference and UI workflows.
Quality gate: focused integration target plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

