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
labels:
- needs:backend
- focus-complete:frontend
assignee: null
created_at: '2026-07-30T14:18:37.798315Z'
updated_at: '2026-08-01T13:17:56.370419Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-180
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 75009ecfe2a90028fda3b6abed1de2ac849a1a206daf2fd9affa03d5a87c1791
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:15:20.787104+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active EXOCOMP-127, EXOCOMP-147, EXOCOMP-179, EXOCOMP-181,
    EXOCOMP-182, EXOCOMP-183, and delivery dependencies EXOCOMP-145/146/148/149/150/151.
    Their scopes are distinct; EXOCOMP-180 uniquely covers cross-replica end-to-end
    reconnect and replay integration.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: f16e91bc-b1ec-4c8c-850c-0280f6ad6dc0
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-180
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-180
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:15:33.867633+00:00'
oompah.task_costs:
  total_input_tokens: 536064
  total_output_tokens: 3827
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 536064
      output_tokens: 3827
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 536064
    output_tokens: 3827
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:15:20.786434+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-180__20260801T131355Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-180
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:15:20.792775+00:00'
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
author: oompah
created: 2026-08-01 13:15
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 24
- Tokens: 536.1K in / 3.8K out [539.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 34s
- Log: EXOCOMP-180__20260801T131355Z.jsonl
---
author: oompah
created: 2026-08-01 13:15
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 13:15
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 13:16
---
UNDERSTANDING: Task requires building an integration harness to test Mission Control reconnection, multi-replica failover, and durable event handling. Deliverables include a deterministic test harness with PostgreSQL + 1 coordinator + 2 Mission Control replicas, tests for disconnect/reconnect scenarios, a Make target for CI, and validation that WebSocket affinity is not required. This appears to be backend/integration testing work, not frontend UI work. Currently investigating whether there's frontend involvement or if this needs a backend focus.
---
author: oompah
created: 2026-08-01 13:17
---
FOCUS HANDOFF: This task requires building backend integration tests for Mission Control reconnection and multi-replica failover scenarios. The work involves:

(1) Building an integration harness with PostgreSQL, one coordinator, and two Mission Control replicas
(2) Creating deterministic test scenarios for disconnect/reconnect, durable event replay, command idempotency, sequence gap handling, and replica termination
(3) Implementing a Make target for running tests in CI containers
(4) Proving WebSocket affinity is not required for correctness

This is infrastructure/backend testing work, not user-facing UI development. My focus as a Frontend Developer is not appropriate for this task. A backend or test specialist should handle this work.

Blockers: EXOCOMP-147, EXOCOMP-148, EXOCOMP-149, EXOCOMP-150, EXOCOMP-151 (dependency chain), EXOCOMP-179 (epic sibling). The git history shows these tasks have active branches but are not yet merged to the epic parent or main.

Recommendation: Route to needs:backend or needs:test focus.
---
<!-- COMMENTS:END -->
