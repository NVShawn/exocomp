---
id: EXOCOMP-22
type: feature
status: Needs Human
priority: 1
title: Implement deterministic least-impact policy selection
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-21
labels: []
assignee: null
created_at: '2026-07-23T19:10:08.344504Z'
updated_at: '2026-07-23T22:33:03.652702Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: fdfe8db6-7c28-494d-b526-659908c22fda
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 2629627
  total_output_tokens: 16541
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 2629627
      output_tokens: 16541
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 698111
    output_tokens: 2886
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:14:50.632593+00:00'
  - profile: standard
    model: unknown
    input_tokens: 454739
    output_tokens: 2963
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:16:30.350033+00:00'
  - profile: deep
    model: unknown
    input_tokens: 478089
    output_tokens: 2859
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:18:25.652836+00:00'
  - profile: default
    model: unknown
    input_tokens: 41
    output_tokens: 1177
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:28:41.044506+00:00'
  - profile: standard
    model: unknown
    input_tokens: 586736
    output_tokens: 3726
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:31:14.487337+00:00'
  - profile: deep
    model: unknown
    input_tokens: 411911
    output_tokens: 2930
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:32:57.786689+00:00'
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Implement deterministic least-impact policy selection.

Implementation
Filter unauthorized, unsafe, stale, inapplicable, cooldown, and retry-exhausted actions; produce deny/allow/approval_required decisions; order eligible actions lexicographically by data loss, work loss, disruption, and scope; require proof before escalation.

Testing
Use table/property tests for stable ordering, ties, stale evidence, validator errors, unavailable policy, safer remaining candidates, and deterministic repeated evaluation.

Acceptance Criteria
- [ ] Validator ambiguity or error fails closed.
- [ ] A higher-impact action cannot win while a safer eligible action remains.
- [ ] Decisions include auditable reasons and ordering evidence.
- [ ] Repeated inputs produce the same decision.
- [ ] Focused policy tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 22:13
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:13
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:14
---
Agent completed successfully in 92s (700997 tokens)
---
author: oompah
created: 2026-07-23 22:14
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 11
- Tokens: 698.1K in / 2.9K out [701.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 32s
- Log: EXOCOMP-22__20260723T221321Z.jsonl
---
author: oompah
created: 2026-07-23 22:14
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-3`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 22:15
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:15
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:16
---
Agent completed successfully in 82s (457702 tokens)
---
author: oompah
created: 2026-07-23 22:16
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 8
- Tokens: 454.7K in / 3.0K out [457.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 22s
- Log: EXOCOMP-22__20260723T221510Z.jsonl
---
author: oompah
created: 2026-07-23 22:16
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-3`. Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
author: oompah
created: 2026-07-23 22:16
---
Retrying (attempt #2, agent: deep)
---
author: oompah
created: 2026-07-23 22:16
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:18
---
Agent completed successfully in 91s (480948 tokens)
---
author: oompah
created: 2026-07-23 22:18
---
Run #3 [attempt=3, profile=deep, role=deep -> Codex/default]
- Turns: 1, Tool calls: 15
- Tokens: 478.1K in / 2.9K out [480.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 31s
- Log: EXOCOMP-22__20260723T221657Z.jsonl
---
author: oompah
created: 2026-07-23 22:18
---
Agent completed 3 times without closing this issue. Human action required: review the agent run history and task state, then either close the task if the work is done or add specific guidance and move it back to Open.
---
author: oompah
created: 2026-07-23 22:26
---
[watchdog:stalled_task] Stalled-task watchdog audit (run #7)

**State audited:** `Needs Human`
**Classification:** `actionable`
**Action:** `reopen`
**Evidence:** Last agent comment signals completion without a human question; the Needs Human transition appears accidental.

*This comment is posted automatically by the oompah stalled-task watchdog. No human action required unless the classification above is incorrect.*
---
author: oompah
created: 2026-07-23 22:27
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:27
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:28
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 27
- Tokens: 41 in / 1.2K out [1.2K total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 25s
- Log: EXOCOMP-22__20260723T222718Z.jsonl
---
author: oompah
created: 2026-07-23 22:28
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:28
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:31
---
Agent completed successfully in 139s (590462 tokens)
---
author: oompah
created: 2026-07-23 22:31
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 16
- Tokens: 586.7K in / 3.7K out [590.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 19s
- Log: EXOCOMP-22__20260723T222856Z.jsonl
---
author: oompah
created: 2026-07-23 22:31
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-3`. Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
author: oompah
created: 2026-07-23 22:31
---
Retrying (attempt #2, agent: deep)
---
author: oompah
created: 2026-07-23 22:31
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:32
---
Agent completed successfully in 77s (414841 tokens)
---
author: oompah
created: 2026-07-23 22:33
---
Run #3 [attempt=3, profile=deep, role=deep -> Codex/default]
- Turns: 1, Tool calls: 7
- Tokens: 411.9K in / 2.9K out [414.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 17s
- Log: EXOCOMP-22__20260723T223142Z.jsonl
---
author: oompah
created: 2026-07-23 22:33
---
Agent completed 3 times without closing this issue. Human action required: review the agent run history and task state, then either close the task if the work is done or add specific guidance and move it back to Open.
---
<!-- COMMENTS:END -->
