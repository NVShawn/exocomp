---
id: EXOCOMP-147
type: task
status: In Progress
priority: 1
title: Add heartbeat, disconnect detection, and reconnect backoff
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-146
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:03.538393Z'
updated_at: '2026-08-01T12:19:09.433447Z'
work_branch: epic-EXOCOMP-130--task-EXOCOMP-147
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 1212be6e326192fc087f66ee0a620f8a497b62faca881250125e5e9dc98afa87
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:17:12.270779+00:00'
  matched_identifiers: []
  evidence: 'Thank you for the coordination message. This provides important context
    that confirms my investigation findings.


    The coordination from EXOCOMP-146 stating **"dependency, epic-sibling"** relationship
    confirms that EXOCOMP-147 and EXOCOMP-146 are **not duplicates** but rather **dependent
    sequential tasks** within the same epic (EXOCOMP-130).


    The "Blocked by" relationship in the issue description further confirms:

    - EXOCOMP-146 is preparatory/foundational work that EXOCOMP-147 depends on

    - They have a clearly defined dependency order, not overlapping scope

    - Both are parts of the larger Mission Control implementation epic


    My investigation conclusion remains unchanged:


    ---


    **Focus handoff: duplicate_detector**


    **Duplicate preflight verdict: no_duplicate**


    **Matches: none**


    **Evidence:** No existing heartbeat, disconnect detection, or reconnect backoff
    implementation exists in the codebase. The mission-control.md plan defines these
    requirements, and EXOCOMP-147 is a fresh task with a confirmed dependency relationship
    (not duplicate relationship) to EXOCOMP-146. Coordination confirms they are dependent
    epic-sibling tasks with sequential work order, not overlapping implementations
    of the same feature.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 8af4d723-db3d-4a36-adc8-856baf3c6e17
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-147
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-147
  base_branch: epic-EXOCOMP-130
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:17:32.026020+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 1180
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 1180
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1180
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:17:12.270035+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-147__20260801T121453Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-130--task-EXOCOMP-147
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:17:12.275545+00:00'
---
## Summary

Plan: plans/mission-control.md, Connection and Delivery Protocol.

Deliverables:
- Send a cluster heartbeat every 30 seconds through the active session.
- Mark a session disconnected after 90 seconds without a valid heartbeat.
- Reconnect with full-jitter exponential backoff from one second to 60 seconds.
- Reset backoff only after a stable authenticated connection.

Acceptance:
- Deterministic clock/randomness tests cover heartbeat cadence, missed heartbeats, reconnect bounds, reset, and duplicate timers.
- Connection loss does not crash the coordinator or block local work.
- Mission Control publishes connected/disconnected state only after committing it.

Out of scope: event persistence and UI.
Quality gate: focused state-machine tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:14
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:14
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:17
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 64, Tool calls: 27
- Tokens: 10 in / 1.2K out [1.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 27s
- Log: EXOCOMP-147__20260801T121453Z.jsonl
---
author: oompah
created: 2026-08-01 12:17
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:17
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 12:19
---
**Understanding**: Task requires implementing heartbeat protocol for coordinator-to-Mission Control connection: (1) Send heartbeat every 30s, (2) Mark disconnected after 90s without heartbeat, (3) Reconnect with full-jitter exponential backoff (1s-60s), (4) Reset backoff after stable auth connection. Acceptance requires deterministic tests covering heartbeat cadence, missed heartbeats, reconnect bounds, and no crash/blocking on connection loss.

**Assigned Focus**: Frontend Developer - mismatch detected. This is coordinator connection infrastructure work (state machines, timers, network resilience), not UI. Exploring if frontend component exists or if handoff needed to backend focus.
---
<!-- COMMENTS:END -->
