---
id: EXOCOMP-223
type: task
status: Open
priority: 1
title: Renew policy leases and fall back to observe on expiry
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-222
labels: []
assignee: null
created_at: '2026-08-03T14:25:17.678179Z'
updated_at: '2026-08-03T15:41:28.257067Z'
work_branch: epic-EXOCOMP-210--task-EXOCOMP-223
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 4aa594617a73fcff8ea1298cd2434863dbcb70c2bcc95f33feb06fe8b164e5e1
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: d94b58bb-38b5-4357-859e-a38c976eb688
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:41:13.553605+00:00'
  claim_expires_at: '2026-08-03T16:11:13.553605+00:00'
  retry_count: 1
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 8255d19a-c0b8-4e45-9d14-1400c0ec5602
oompah.work_branch: epic-EXOCOMP-210--task-EXOCOMP-223
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-210--task-EXOCOMP-223
  base_branch: epic-EXOCOMP-210
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:41:25.369428+00:00'
oompah.task_costs:
  total_input_tokens: 317977
  total_output_tokens: 1520
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 317977
      output_tokens: 1520
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 317977
    output_tokens: 1520
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:38:55.648375+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-223__20260803T153747Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-210--task-EXOCOMP-223
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:38:55.670617+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add Mission Control renewal and coordinator lease-timer behavior with a five-minute default and validated configuration.

Acceptance criteria:
- Lease configuration accepts 60 through 3600 seconds; renewal defaults to 60 seconds and must be below half the lease.
- Mission Control issues fresh signed bundles without changing policy version when only the lease changes.
- Coordinator timers use monotonic time while running and validated wall time after restart.
- Expiry atomically switches all effective policy to observe, invalidates pending execution, and writes durable audit state.
- Reconnect requires a fresh bundle before manage resumes.

Tests: Use injectable clocks for bounds, renewal, delayed delivery, disconnect, clock movement, restart before/after expiry, invalid configuration, pending-work invalidation, and reconnection; run make test, make fmt-check, and make lint.

Out of scope: Action execution and LiveView rendering.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:37
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:37
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:38
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 3
- Tokens: 318.0K in / 1.5K out [319.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 24s
- Log: EXOCOMP-223__20260803T153747Z.jsonl
---
author: oompah
created: 2026-08-03 15:41
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:41
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
