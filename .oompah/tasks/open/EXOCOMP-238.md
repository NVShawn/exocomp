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
updated_at: '2026-08-03T15:58:12.037466Z'
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
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: inconclusive\n\
    Matches: none\nEvidence: The supplied corpus lacks the active hierarchical-management\
    \ peer task descriptions and comments (including EXOCOMP-212 and sibling/dependency\
    \ tasks), so duplicate status cannot be determined without guessing. No files\
    \ or tracker state were changed.\nFocus handoff: duplicate_detector  \nDuplicate\
    \ preflight verdict: inconclusive  \nMatches: none  \n\nEvidence: The supplied\
    \ corpus lacks the active hierarchical-management peer task descriptions and comments\
    \ (including EXOCOMP-212 and sibling/dependency tasks), so duplicate status cannot\
    \ be determined without guessing. No files or tracker state were changed."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: '2026-08-03T15:59:07.464351+00:00'
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: c2845f01-779d-42ca-8a15-466ee8a38538
oompah.work_branch: epic-EXOCOMP-212--task-EXOCOMP-238
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-212--task-EXOCOMP-238
  base_branch: epic-EXOCOMP-212
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:56:37.140065+00:00'
oompah.task_costs:
  total_input_tokens: 418687
  total_output_tokens: 3199
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 418687
      output_tokens: 3199
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 418687
    output_tokens: 3199
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:58:07.460095+00:00'
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
<!-- COMMENTS:END -->
