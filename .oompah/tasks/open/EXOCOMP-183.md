---
id: EXOCOMP-183
type: task
status: Open
priority: 2
title: Add the Mission Control scale and soak qualification
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-165
- EXOCOMP-177
- EXOCOMP-180
- EXOCOMP-182
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:18:53.481557Z'
updated_at: '2026-08-01T16:05:21.527607Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-183
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 97a3e3d01c88265a4ca9802e4afe577642ac1e4aaba3d68a062229b16c1fcbfa
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 36a8098f-eac1-46a5-8ff1-707c11004686
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T16:05:13.967240+00:00'
  claim_expires_at: '2026-08-01T16:35:13.967240+00:00'
  retry_count: 2
  retry_after: null
oompah.agent_run_id: c3ee3b30-0044-4aff-a1c6-c800ca817db3
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-183
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-183
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T16:05:19.742800+00:00'
oompah.task_costs:
  total_input_tokens: 470164
  total_output_tokens: 10380
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 470164
      output_tokens: 10380
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 469994
    output_tokens: 4832
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:52:58.223772+00:00'
  - profile: default
    model: haiku
    input_tokens: 170
    output_tokens: 5548
    cost_usd: 0.0
    recorded_at: '2026-08-01T16:02:32.900698+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-183__20260801T155111Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-183
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T15:52:58.237422+00:00'
  - run_id: EXOCOMP-183__20260801T155840Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-183
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T16:02:32.907587+00:00'
---
## Summary

Plan: plans/mission-control.md, Test Strategy.

Deliverables:
- Build a deterministic load driver for 100 persistent clusters, 10,000 current nodes, and a burst of 100 events per second.
- Measure committed-event-to-LiveView p95 latency and event loss excluding local model inference.
- Run a four-hour soak and report connection count, BEAM processes/mailboxes, memory, file descriptors, database pool/queue, outbox depth, and webhook/retention workers.

Acceptance:
- p95 is under three seconds with zero event loss at the target load.
- Soak analysis finds no sustained unbounded growth after warm-up.
- Raw samples, summary, host profile, and exact artifact identity are retained.

Out of scope: performance optimization not required to meet the gate.
Quality gate: dedicated short and full Make targets.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:51
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:51
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 15:52
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 24
- Tokens: 470.0K in / 4.8K out [474.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 53s
- Log: EXOCOMP-183__20260801T155111Z.jsonl
---
author: oompah
created: 2026-08-01 15:58
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:58
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 16:02
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 47, Tool calls: 24
- Tokens: 170 in / 5.5K out [5.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 59s
- Log: EXOCOMP-183__20260801T155840Z.jsonl
---
author: oompah
created: 2026-08-01 16:05
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 16:05
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
