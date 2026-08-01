---
id: EXOCOMP-180
type: task
status: Open
priority: 1
title: Add reconnect and multi-replica integration tests
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-147
- EXOCOMP-148
- EXOCOMP-149
- EXOCOMP-150
- EXOCOMP-151
- EXOCOMP-179
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:18:37.798315Z'
updated_at: '2026-08-01T13:13:54.291638Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-180
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 75009ecfe2a90028fda3b6abed1de2ac849a1a206daf2fd9affa03d5a87c1791
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 50a0201f-76d0-47c9-b691-c602e7c9049a
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:13:44.728588+00:00'
  claim_expires_at: '2026-08-01T13:43:44.728588+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: f7d74e33-accc-41e0-9596-3255c4f08618
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-180
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-180
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:13:51.258456+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:13
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:13
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
