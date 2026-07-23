---
id: EXOCOMP-21
type: feature
status: In Progress
priority: 1
title: Define action, evidence, risk, and data-classification types
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-8
labels: []
assignee: null
created_at: '2026-07-23T19:10:07.361533Z'
updated_at: '2026-07-23T21:54:27.377258Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 218f6886-6b22-4b8c-8cdb-47453711f489
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 30
  total_output_tokens: 6927
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 30
      output_tokens: 6927
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 30
    output_tokens: 6927
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:54:15.837606+00:00'
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Define action, evidence, risk, and data-classification types.

Implementation
Implement versioned types and JSON schemas for action definitions, proposals, evidence, validator results, risk ranks, reversibility, data classification, execution, and verification; reject unknown fields/versions where security-relevant; default unknown data to protected user data.

Testing
Add table/property tests for valid schemas, malformed values, unknown versions, missing evidence, risk ordering primitives, and every data-classification default.

Acceptance Criteria
- [ ] All security-relevant inputs are bounded and schema-versioned.
- [ ] Unknown data is always classified as protected user data.
- [ ] User-data deletion is unrepresentable as an eligible action.
- [ ] Focused type/schema tests pass.

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
created: 2026-07-23 21:51
---
Understanding: Investigating whether EXOCOMP-21 ('Define action, evidence, risk, and data-classification types') is a duplicate of an existing task. Will search for related tasks covering type definitions for actions, evidence, risk ranks, reversibility, data classification, and schema versioning before any implementation proceeds.
---
author: oompah
created: 2026-07-23 21:54
---
Duplicate screening found no duplicate.

Closest reviewed task: EXOCOMP-61 (Done, parent EXOCOMP-11) — 'Define versioned proposal schema module'. This adds Exocomp.Node.ProposalSchema which validates LLM proposal output (closed proposal_id set, required fields, schema version, forbidden shell-command indicators). It is a Milestone 1/inference-client task that validates *what the LLM proposes*. EXOCOMP-21 is a Milestone 3/safety task that defines the *action catalog types, evidence structure, risk ranks, reversibility, and data classification* consumed by the policy engine. Scope and domain are distinct.

All other candidate tasks reviewed: EXOCOMP-3 (M3 parent epic), EXOCOMP-8 (A2A protocol types, Done), EXOCOMP-22–28 (M3 siblings that *depend on* EXOCOMP-21). None define action/evidence/risk/data-classification types.

Evidence: searched git log, plans/milestone-3-safety-validation.md, all .oompah/tasks/ entries in origin/oompah/state/proj-c260b117, and commit diffs for EXOCOMP-61.

Conclusion: EXOCOMP-21 is a unique task. Handing off to feature implementation focus.
---
author: oompah
created: 2026-07-23 21:54
---
Agent completed successfully in 165s (6957 tokens)
---
author: oompah
created: 2026-07-23 21:54
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 62, Tool calls: 49
- Tokens: 30 in / 6.9K out [7.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 45s
- Log: EXOCOMP-21__20260723T215134Z.jsonl
---
author: oompah
created: 2026-07-23 21:54
---
Focus handoff required before leaving `duplicate_detector`. Add a comment headed `Focus handoff: duplicate_detector` with outcome, evidence, remaining work, and next focus.
---
author: oompah
created: 2026-07-23 21:54
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:54
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
