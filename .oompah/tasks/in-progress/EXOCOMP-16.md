---
id: EXOCOMP-16
type: feature
status: In Progress
priority: 1
title: Implement coordinator CA initialization and enrollment tokens
parent: EXOCOMP-2
children: []
blocked_by:
- EXOCOMP-9
- EXOCOMP-14
labels: []
assignee: null
created_at: '2026-07-23T19:09:29.953540Z'
updated_at: '2026-07-23T22:51:27.281717Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 6a99ca5d-142c-452a-a83f-9e30857b08a9
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 731302
  total_output_tokens: 3656
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 731302
      output_tokens: 3656
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 731302
    output_tokens: 3656
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:51:10.284714+00:00'
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Implement coordinator CA initialization and enrollment tokens.

Implementation
Add coordinator-local initialization that creates a protected offline root export, online intermediate, coordinator leaf identity, and separate approval-signing key; implement ten-minute one-use enrollment tokens bound to inventory node IDs; enforce key permissions and explicit backup output.

Testing
Test initialization idempotency, secure permissions, missing/corrupt key material, token expiry, node mismatch, token replay, and secrets absent from logs.

Acceptance Criteria
- [ ] PKI initialization produces valid separated root/intermediate material.
- [ ] Online state does not retain an unprotected root key.
- [ ] Enrollment tokens are node-bound, expiring, and single-use.
- [ ] Private material is protected and redacted.
- [ ] Focused PKI tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 22:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:49
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:51
---
Agent completed successfully in 108s (734958 tokens)
---
author: oompah
created: 2026-07-23 22:51
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 10
- Tokens: 731.3K in / 3.7K out [735.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 48s
- Log: EXOCOMP-16__20260723T224925Z.jsonl
---
author: oompah
created: 2026-07-23 22:51
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-2`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 22:51
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:51
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
