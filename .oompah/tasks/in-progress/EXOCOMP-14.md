---
id: EXOCOMP-14
type: feature
status: In Progress
priority: 1
title: Scaffold coordinator inventory, registry, and audit
parent: EXOCOMP-2
children: []
blocked_by:
- EXOCOMP-7
- EXOCOMP-8
labels: []
assignee: null
created_at: '2026-07-23T19:09:28.257166Z'
updated_at: '2026-07-23T21:53:06.695201Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 3b23a6f4-e12b-4c5e-9484-5128bd508f8e
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 566847
  total_output_tokens: 3085
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 566847
      output_tokens: 3085
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 566847
    output_tokens: 3085
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:53:03.192207+00:00'
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Scaffold coordinator inventory, registry, and audit.

Implementation
Implement coordinator supervision; versioned JSON inventory parsing; atomic inventory replacement; ETS node registry; configured journald or bounded JSON-lines audit sink; structured health and error reporting.

Testing
Test malformed inventory, duplicate IDs and certificate identities, failed replacement retaining prior state, registry reconstruction, sink redaction, and audit outage behavior.

Acceptance Criteria
- [ ] Valid inventory loads atomically.
- [ ] Invalid replacement leaves prior inventory active.
- [ ] Registry is reconstructible after restart.
- [ ] Audit output is correlated and redacted.
- [ ] Focused tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:51
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:51
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:53
---
Agent completed successfully in 95s (569932 tokens)
---
author: oompah
created: 2026-07-23 21:53
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 9
- Tokens: 566.8K in / 3.1K out [569.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 35s
- Log: EXOCOMP-14__20260723T215131Z.jsonl
---
author: oompah
created: 2026-07-23 21:53
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-2`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
<!-- COMMENTS:END -->
