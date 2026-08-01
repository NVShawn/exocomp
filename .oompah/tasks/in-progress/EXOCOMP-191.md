---
id: EXOCOMP-191
type: task
status: In Progress
priority: 1
title: Implement bounded read-only service observation
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-188
labels: []
assignee: null
created_at: '2026-07-30T21:37:01.048654Z'
updated_at: '2026-08-01T14:11:59.187927Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-191
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: e3d50cc86992b2cc8acffc306a4cbabaabe5ea5be3e0a90fc80a66583e552ea1
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:54:24.097346+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active tasks EXOCOMP-188, 189, 190, 192, 193, and 194. EXOCOMP-190
    discovers enabled services; EXOCOMP-188 validates inventory inputs; EXOCOMP-189
    merges desired state; EXOCOMP-192 schedules polling. None implements bounded observation
    of coordinator-selected units and loopback probes. Terminal EXOCOMP-187 was excluded.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 5684be9d-6fdd-4ce7-935a-6c0f0bc44d39
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-191
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-191
  base_branch: epic-EXOCOMP-185
  base_sha: 0f7969a22949a49ab4ff8cc3a169cc77c2810b21
  updated_at: '2026-08-01T14:11:57.213977+00:00'
oompah.task_costs:
  total_input_tokens: 562588
  total_output_tokens: 2938
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 562588
      output_tokens: 2938
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 562588
    output_tokens: 2938
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:54:24.096487+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-191__20260801T135300Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-185--task-EXOCOMP-191
    source_sha: 6742aa13ef4dc7e3dafa1582cebb5e4550ba9a72
    completed_at: '2026-08-01T13:54:24.116526+00:00'
---
## Summary

Plan: plans/mission-control.md, manual and reconciled service observation.

Deliverable: Add the exocomp.service.observe node skill for strictly validated coordinator-selected unit names.

Acceptance criteria:
- Query systemd through fixed argv for exact validated .service names.
- Optionally execute only validated loopback HTTP probes supplied by desired state.
- Return systemd and probe evidence with timestamps, partial errors, and collector versions.
- Enforce service-count, response-size, and timeout limits.
- The skill cannot execute, enable, disable, or restart a unit and does not alter the recovery allow-list.

Tests: Cover valid observations, invalid names, non-loopback URLs, mixed partial results, timeout, and bounded responses; run make test.

Out of scope: Desired-state merging, scheduling, remediation, and Ceph-specific health.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:52
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:53
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:54
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 9
- Tokens: 562.6K in / 2.9K out [565.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 30s
- Log: EXOCOMP-191__20260801T135300Z.jsonl
---
author: oompah
created: 2026-08-01 14:11
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 14:11
---
Focus: Software Engineer
---
<!-- COMMENTS:END -->
