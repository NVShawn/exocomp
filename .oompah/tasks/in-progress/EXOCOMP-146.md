---
id: EXOCOMP-146
type: task
status: In Progress
priority: 1
title: Connect coordinators over an outbound mTLS WebSocket
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-145
- EXOCOMP-144
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:02.496448Z'
updated_at: '2026-08-01T12:15:19.300951Z'
work_branch: epic-EXOCOMP-130--task-EXOCOMP-146
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: e89e27b3fcf6b07f45d8bc5633fc0ace9c4e108c95db7a100a80b4ac8266591a
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:14:39.386053+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active EXOCOMP-144, EXOCOMP-145, EXOCOMP-147, EXOCOMP-149,
    EXOCOMP-150, EXOCOMP-180, EXOCOMP-181, and EXOCOMP-143. Each covers adjacent PKI,
    configuration, heartbeat, delivery, integration, security testing, or enrollment
    scope; EXOCOMP-143 explicitly excludes WebSocket authentication. The exact outbound
    mTLS WebSocket upgrade/session-replacement scope appears only in EXOCOMP-146 and
    `plans/mission-control.md`.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: f9a51151-476f-4930-82ab-b57021b5a8a3
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-146
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-146
  base_branch: epic-EXOCOMP-130
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:14:59.554141+00:00'
oompah.task_costs:
  total_input_tokens: 467252
  total_output_tokens: 4252
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 467252
      output_tokens: 4252
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 467252
    output_tokens: 4252
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:14:39.385281+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-146__20260801T121119Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-130--task-EXOCOMP-146
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:14:39.452481+00:00'
---
## Summary

Plan: plans/mission-control.md, Cluster Enrollment and Connection Protocol.

Deliverables:
- Implement the coordinator WebSocket client for GET /api/v1/clusters/connect using TLS 1.3, server trust validation, and its enrolled client certificate.
- Implement the Mission Control upgrade endpoint, extract organization/cluster identity only from the validated certificate, reject revoked certificates, and create a random session ID.
- Enforce one live session per cluster; a newer authenticated session supersedes the old one.

Acceptance:
- Integration tests cover success, missing/wrong certificate, wrong trust root, revoked identity, payload identity spoofing, and session replacement.
- No inbound listener is added to the coordinator.

Out of scope: heartbeat, replay, and domain events.
Quality gate: focused transport tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:11
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:11
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:14
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 2, Tool calls: 29
- Tokens: 467.3K in / 4.3K out [471.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 32s
- Log: EXOCOMP-146__20260801T121119Z.jsonl
---
author: oompah
created: 2026-08-01 12:14
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:15
---
Focus: Refactoring Specialist
---
author: oompah
created: 2026-08-01 12:15
---
Understanding: I will inspect the existing coordinator, Mission Control, TLS, and certificate identity paths, then implement the outbound TLS 1.3 WebSocket connection and validated upgrade/session replacement behavior with focused integration tests. I will preserve existing interfaces, run the required Makefile gates, commit, push, and submit the task.
---
<!-- COMMENTS:END -->
