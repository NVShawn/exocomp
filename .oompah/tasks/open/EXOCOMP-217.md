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
updated_at: '2026-08-03T15:48:35.751192Z'
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
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: inconclusive\n\
    Matches: none\nEvidence: ** The provided task corpus covers EXOCOMP-1 through\
    \ EXOCOMP-123, but EXOCOMP-217 is part of epic EXOCOMP-209 with related tasks\
    \ (EXOCOMP-213-218) that lie outside the corpus bounds. No task in the available\
    \ corpus addresses Mission Control policy override endpoints or hierarchical policy\
    \ management. The referenced plan (plans/hierarchical-management-modes.md) and\
    \ coordination peers necessary for definitive duplicate assessment are not available\
    \ in this corpus. Duplicate screening cannot be conclusively completed without\
    \ access to EXOCOMP-209 epic tasks or their prior duplicate investigation records.\n\
    # Duplicate Screening for EXOCOMP-217\n\nI'll analyze whether this issue is a\
    \ duplicate of any existing tracked work.\n\n## Task Analysis\n\n**EXOCOMP-217\
    \ Scope:**\n- Title: \"Add management-policy HTTP APIs\"\n- Deliverable: Versioned\
    \ Mission Control endpoints for policy override CRUD operations\n- Focus: HTTP\
    \ controller layer with authorization, conflict handling, multi-scope resolution\n\
    - Plan reference: `plans/hierarchical-management-modes.md`\n- Status: Open (first\
    \ dispatch for duplicate screening)\n\n**Key Characteristics:**\n- Mission Control\
    \ endpoints (list, resolve, create, update, delete)\n- Policy override management\n\
    - Scope resolution (configured, inherited, effective values)\n- Conflict detection\
    \ and stale-write handling\n- Organization isolation\n- Controller tests required\n\
    \n## Corpus Review\n\nI searched the provided task corpus (EXOCOMP-1 through EXOCOMP-123)\
    \ for related work:\n\n**Examined categories:**\n- Coordinator tasks (EXOCOMP-14-20,\
    \ EXOCOMP-88-105): Orchestration, diagnostics, enrollment, PKI \u2014 not policy\
    \ management\n- Node tasks (EXOCOMP-7-13): Collectors, A2A service, llama.cpp\
    \ \u2014 not policy endpoints\n- Release/verification (EXOCOMP-106-123): Bundle\
    \ assembly, qualification, installation \u2014 not policy APIs\n\n**Finding:**\
    \ No task in the provided corpus addresses Mission Control policy override HTTP\
    \ endpoints.\n\n## Critical Data Gap\n\nThe coordination advisory notes reference:\n\
    - Epic parent: **EXOCOMP-209** (not in corpus)\n- Siblings: **EXOCOMP-213, 214,\
    \ 215, 216, 218** (not in corpus)\n- Dependencies: **EXOCOMP-127, 216, 218** (not\
    \ in corpus)\n\nThe provided corpus terminates at EXOCOMP-123. EXOCOMP-217 belongs\
    \ to the EXOCOMP-209 epic tier, which is significantly higher-numbered and completely\
    \ absent from the reference data. This suggests the corpus does not include the\
    \ task family most relevant for duplicate screening.\n\n---\n\nFocus handoff:\
    \ duplicate_detector\n\nDuplicate preflight verdict: inconclusive\n\nMatches:\
    \ none\n\n**Evidence:** The provided task corpus covers EXOCOMP-1 thr"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: '2026-08-03T15:49:32.381429+00:00'
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 585fc0c2-4847-4afb-be29-2f13499e817a
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-217
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-217
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:47:32.372059+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 1891
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 1891
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1891
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:48:32.379947+00:00'
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
<!-- COMMENTS:END -->
