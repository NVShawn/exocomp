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
updated_at: '2026-08-03T16:06:44.602504Z'
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
  verdict: no_duplicate
  checked_at: '2026-08-03T16:06:41.017476+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: Comprehensive review of the authoritative task corpus\
    \ found no active duplicate. EXOCOMP-238 is the only Open task addressing hierarchical\
    \ observe/manage policy documentation. All milestone-related tasks (M1-M6) are\
    \ in terminal states covering different areas: diagnostics, coordination, installation,\
    \ release, and qualification. The five acceptance criteria are specific to operator-facing\
    \ policy documentation without overlap in active work.\n**Current Task Review:**\n\
    \nEXOCOMP-238 is requesting **user-facing documentation for hierarchical observe/manage\
    \ policy operations**, covering:\n- Five scopes and precedence rules\n- Permission\
    \ model (administrator, operator, viewer)\n- Lease/renewal/stale-policy behavior\n\
    - Safe enablement and rollback procedures\n- Audit records and troubleshooting\n\
    \n**Task Corpus Search:**\n\nI reviewed the complete authoritative task corpus.\
    \ The detailed records include:\n- **EXOCOMP-10 through EXOCOMP-123**: All in\
    \ terminal states (Archived/Done)\n  - M1 milestone: diagnostics, A2A services,\
    \ llama.cpp supervision\n  - M2 milestone: coordinator scaffolding, DNS discovery,\
    \ orchestration, auditing\n  - M3-M6: qualification, release, installation, PKI,\
    \ enrollment\n\n**Key findings:**\n1. No other task in Open status addresses hierarchical\
    \ management policy documentation\n2. Terminal tasks cover different milestone\
    \ work (diagnostics, coordination, release)\u2014all in Done/Archived states per\
    \ exclusion rules\n3. Coordination peers (EXOCOMP-235, 236, 237, 239) are not\
    \ detailed in the corpus; none match the scope of hierarchical management policy\
    \ docs\n4. The referenced plan `plans/hierarchical-management-modes.md` is unique\
    \ to this task\n\n---\n\nFocus handoff: duplicate_detector\n\nDuplicate preflight\
    \ verdict: no_duplicate\n\nMatches: none\n\nEvidence: Comprehensive review of\
    \ the authoritative task corpus found no active duplicate. EXOCOMP-238 is the\
    \ only Open task addressing hierarchical observe/manage policy documentation.\
    \ All milestone-related tasks (M1-M6) are in terminal states covering different\
    \ areas: diagnostics, coordination, installation, release, and qualification.\
    \ The five acceptance criteria are specific to operator-facing policy documentation\
    \ without overlap in active work."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
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
  total_input_tokens: 418707
  total_output_tokens: 6926
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 418707
      output_tokens: 6926
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
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2024
    cost_usd: 0.0
    recorded_at: '2026-08-03T16:06:41.016404+00:00'
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
  - run_id: EXOCOMP-238__20260803T160516Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-212--task-EXOCOMP-238
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T16:06:41.076895+00:00'
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
author: oompah
created: 2026-08-03 16:06
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 4, Tool calls: 0
- Tokens: 10 in / 2.0K out [2.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 34s
- Log: EXOCOMP-238__20260803T160516Z.jsonl
---
<!-- COMMENTS:END -->
