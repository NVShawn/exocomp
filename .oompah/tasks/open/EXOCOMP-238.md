---
id: EXOCOMP-238
type: task
status: Open
priority: null
title: Document hierarchical management policy operations
parent: EXOCOMP-212
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-218
- EXOCOMP-224
- EXOCOMP-234
- EXOCOMP-237
labels: []
assignee: null
created_at: '2026-08-03T14:28:21.152567Z'
updated_at: '2026-08-03T16:05:13.708036Z'
work_branch: epic-EXOCOMP-212--task-EXOCOMP-238
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 823f0f33e1c4a77b6db10f8c58ca0ace1142ccd17a26efaddc495abaac9fb769
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 1d9862f6-bd18-41a4-8abd-ffa74ebd8f0a
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T16:05:00.077732+00:00'
  claim_expires_at: '2026-08-03T16:35:00.077732+00:00'
  retry_count: 2
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: c02da682-1d95-4fa7-99b0-153d995b8d64
oompah.work_branch: epic-EXOCOMP-212--task-EXOCOMP-238
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-212--task-EXOCOMP-238
  base_branch: epic-EXOCOMP-212
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T16:05:11.269282+00:00'
oompah.task_costs:
  total_input_tokens: 418697
  total_output_tokens: 4902
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 418697
      output_tokens: 4902
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 418687
    output_tokens: 3199
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:58:07.460095+00:00'
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1703
    cost_usd: 0.0
    recorded_at: '2026-08-03T16:01:56.992200+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-238__20260803T155646Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-212--task-EXOCOMP-238
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:58:07.473804+00:00'
  - run_id: EXOCOMP-238__20260803T160042Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-212--task-EXOCOMP-238
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T16:01:57.006313+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable:
Write user-facing documentation for configuring, reviewing, troubleshooting, and safely rolling back hierarchical observe/manage policy.

Acceptance criteria:
- Explain all five scopes, precedence, the same-rank disagreement rule, and the implicit observe default with examples.
- Document administrator, operator, and viewer permissions for enabling or restricting manage mode.
- Describe lease duration, renewal, stale-policy behavior, and the status fields operators should inspect.
- Provide safe enablement, emergency restrict-to-observe, and rollback procedures.
- Document audit records and troubleshooting for rejected or unavailable actions.
- Link to the relevant Mission Control and node installation documentation without duplicating task tracking.

Tests:
- Run make check-links and make test-compliance.
- Verify every documented command and configuration key against the implemented interfaces.

Out of scope:
- Internal implementation design, which remains in the linked plan.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:56
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:56
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:58
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 4
- Tokens: 418.7K in / 3.2K out [421.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 36s
- Log: EXOCOMP-238__20260803T155646Z.jsonl
---
author: oompah
created: 2026-08-03 16:00
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 16:00
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 16:01
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 1.7K out [1.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 24s
- Log: EXOCOMP-238__20260803T160042Z.jsonl
---
author: oompah
created: 2026-08-03 16:05
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 16:05
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
