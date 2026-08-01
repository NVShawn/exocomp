---
id: EXOCOMP-183
type: task
status: In Progress
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
updated_at: '2026-08-01T16:08:45.429306Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-183
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 97a3e3d01c88265a4ca9802e4afe577642ac1e4aaba3d68a062229b16c1fcbfa
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T16:08:16.921921+00:00'
  matched_identifiers: []
  evidence: "Based on my thorough investigation, I can now provide my final verdict.\n\
    \n## Investigation Summary\n\nI've searched the codebase and documentation for\
    \ any existing tasks or work that might duplicate EXOCOMP-183 (Add the Mission\
    \ Control scale and soak qualification). Here's what I found:\n\n### Key Findings:\n\
    \n1. **Existing M5 Performance Qualification**: Milestone 5 has already completed\
    \ performance testing for the node and coordinator control planes (via EXOCOMP-125).\
    \ This includes soak analysis, but it's specifically for:\n   - Node agent resource\
    \ consumption\n   - Coordinator control-plane resource consumption\n   - Excluding\
    \ model inference\n\n2. **Release Qualification Matrix**: Covers build reproducibility\
    \ and clean-host startup for node/coordinator releases, not performance testing.\n\
    \n3. **Mission Control Status**: The mission-control.md plan indicates M7 is in\
    \ \"Proposed\" status. There is:\n   - No `exocomp_mission_control` application\
    \ implemented yet\n   - No existing Mission Control qualification tests\n   -\
    \ No existing load driver for Mission Control\n\n### Distinction from EXOCOMP-183:\n\
    \nEXOCOMP-183 is specifically for **Mission Control** (the Phoenix LiveView web\
    \ application with PostgreSQL backend), which is:\n- A **different component**\
    \ than the node/coordinator control plane\n- Designed to handle **100 persistent\
    \ cluster connections** and **10,000 node records**\n- Requires different testing\
    \ infrastructure (web load, database performance, LiveView latency)\n- Not covered\
    \ by existing M5 or release qualification gates\n\n**Conclusion:** This is a unique,\
    \ standalone qualification task for the Mission Control application that has no\
    \ active duplicate.\n\n---\n\nFocus handoff: duplicate_detector\n\nDuplicate preflight\
    \ verdict: no_duplicate\n\nMatches: none\n\nEvidence: Searched `.oompah/tasks`,\
    \ `plans/`, `docs/`, and `apps/` for existing Mission Control-specific or parallel\
    \ scale/soak qualification work. Found M5 performance gate (completed, node/coordinator\
    \ only) and release qualification"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 2
  retry_after: null
oompah.agent_run_id: 09052065-824e-401b-b7b4-9d3618cb0e95
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-183
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-183
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T16:08:43.492455+00:00'
oompah.task_costs:
  total_input_tokens: 470342
  total_output_tokens: 16198
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 470342
      output_tokens: 16198
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
  - profile: default
    model: haiku
    input_tokens: 178
    output_tokens: 5818
    cost_usd: 0.0
    recorded_at: '2026-08-01T16:08:16.920423+00:00'
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
  - run_id: EXOCOMP-183__20260801T160522Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-183
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T16:08:16.935907+00:00'
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
author: oompah
created: 2026-08-01 16:08
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 63, Tool calls: 28
- Tokens: 178 in / 5.8K out [6.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 0s
- Log: EXOCOMP-183__20260801T160522Z.jsonl
---
author: oompah
created: 2026-08-01 16:08
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 16:08
---
Focus: Software Engineer
---
<!-- COMMENTS:END -->
