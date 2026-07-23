---
id: EXOCOMP-22
type: feature
status: In Progress
priority: 1
title: Implement deterministic least-impact policy selection
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-21
labels: []
assignee: null
created_at: '2026-07-23T19:10:08.344504Z'
updated_at: '2026-07-23T22:15:10.047191Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: b3570ab0-f81a-461d-b621-5de3437d066e
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 698111
  total_output_tokens: 2886
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 698111
      output_tokens: 2886
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 698111
    output_tokens: 2886
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:14:50.632593+00:00'
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
<!-- COMMENTS:END -->
