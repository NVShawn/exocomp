---
id: EXOCOMP-217
type: task
status: Open
priority: 2
title: Add management-policy HTTP APIs
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-216
labels: []
assignee: null
created_at: '2026-08-03T14:24:19.702752Z'
updated_at: '2026-08-03T15:56:09.315310Z'
work_branch: epic-EXOCOMP-209--task-EXOCOMP-217
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 07c29fc9d134be89d7e319e5554c70a6d13db45beee80f7f1f75ba53808ad1a0
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:56:05.452643+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: Scanned 120 tasks in the authoritative corpus (EXOCOMP-10\
    \ through EXOCOMP-123). No active task duplicates EXOCOMP-217's scope of management-policy\
    \ HTTP APIs for policy overrides. All existing tasks are in terminal states (Archived/Merged)\
    \ and historically address coordinator infrastructure (inventory, polling, orchestration)\
    \ and release qualification\u2014not policy configuration endpoints. The coordination\
    \ peers (EXOCOMP-127, 209, 213-218) referenced in the advisory are not present\
    \ in the provided authoritative corpus and therefore cannot be evaluated; proceed\
    \ with implementation.\nLooking at the task corpus provided, I need to determine\
    \ if EXOCOMP-217 duplicates any **active** (non-terminal) task.\n\n## Analysis\n\
    \n**Current Task (EXOCOMP-217):**\n- Title: Add management-policy HTTP APIs\n\
    - Status: **Open**\n- Scope: Versioned Mission Control endpoints for policy overrides\
    \ (list, resolve, create, update, delete)\n- Related to hierarchical management\
    \ modes and policy configuration\n\n**Corpus Review:**\nThe authoritative task\
    \ corpus contains 120 tasks spanning EXOCOMP-10 through EXOCOMP-123. Reviewing\
    \ all tasks:\n\n- **EXOCOMP-10 through EXOCOMP-105**: Coordinator diagnostics,\
    \ orchestration, cancellation, polling, discovery (all Archived)\n- **EXOCOMP-106\
    \ through EXOCOMP-109**: Epic rebase tasks (all Archived)  \n- **EXOCOMP-111 through\
    \ EXOCOMP-116**: Recovery and verification tasks (all Archived)\n- **EXOCOMP-118\
    \ through EXOCOMP-123**: Release qualification and remediation (all Archived)\n\
    - **EXOCOMP-12 through EXOCOMP-15**: M1/M2 infrastructure (all Archived)\n\n**Key\
    \ Finding:**\nEvery task in the corpus except EXOCOMP-217 itself is in a terminal\
    \ state (Archived or Merged). Per the instructions: \"Exclude every candidate\
    \ in a terminal state (Done, Merged, or Archived). A completed task is historical\
    \ context, not an active duplicate target.\"\n\nNone of the tasks scope management\
    \ policies, policy overrides, or policy configuration HTTP APIs. The closest (EXOCOMP-14/15\
    \ coordinator work) implements discovery and polling for nodes\u2014not policy\
    \ management.\n\n---\n\nFocus handoff: duplicate_detector\n\nDuplicate preflight\
    \ verdict: no_duplicate\n\nMatches: none\n\nEvidence: Scanned 120 tasks in the\
    \ authoritative corpus (EXOCOMP-10 through EXOCOMP-123). No active task duplicates\
    \ EXOCOMP-217's scope of management-policy HTTP APIs for policy overrides. All\
    \ existing tasks are in terminal states (Archived/Merged) and historically address\
    \ coordinator infrastructure (inventory, polling, orchestration) and release qualification\u2014\
    not policy configuration endpoints. The coordination peers (EXO"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 2
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 7a26fd69-37e4-45a5-900f-9168bb084053
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-217
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-217
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:54:33.497716+00:00'
oompah.task_costs:
  total_input_tokens: 30
  total_output_tokens: 6795
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 30
      output_tokens: 6795
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1891
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:48:32.379947+00:00'
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2376
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:51:46.574762+00:00'
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2528
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:56:05.451571+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-217__20260803T154738Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-209--task-EXOCOMP-217
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:48:32.388288+00:00'
  - run_id: EXOCOMP-217__20260803T155048Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-209--task-EXOCOMP-217
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:51:46.646113+00:00'
  - run_id: EXOCOMP-217__20260803T155439Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-209--task-EXOCOMP-217
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:56:05.466720+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add versioned Mission Control endpoints to list, resolve, create, update, and delete policy overrides.

Acceptance criteria:
- Organization comes only from the authenticated session.
- Requests validate scope-specific identifiers, canonical service keys, mode, and expected policy version.
- Responses include configured value, inherited value, effective value, winning scope or conflict, policy version, and lease status where available.
- Stale writes return a deterministic conflict response.
- Authorization failures do not reveal cross-organization resources.

Tests: Add controller tests for success and all validation, role, conflict, not-found, malformed JSON, size-limit, and organization-isolation paths; run make test, make fmt-check, and make lint.

Out of scope: HTML UI, policy distribution, and broker behavior.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:47
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:47
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:48
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 1.9K out [1.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 4s
- Log: EXOCOMP-217__20260803T154738Z.jsonl
---
author: oompah
created: 2026-08-03 15:50
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:50
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:51
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 2.4K out [2.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 8s
- Log: EXOCOMP-217__20260803T155048Z.jsonl
---
author: oompah
created: 2026-08-03 15:54
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:54
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:56
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 4, Tool calls: 0
- Tokens: 10 in / 2.5K out [2.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 36s
- Log: EXOCOMP-217__20260803T155439Z.jsonl
---
<!-- COMMENTS:END -->
