---
id: EXOCOMP-213
type: task
status: Open
priority: 1
title: Define management-policy types and resolver
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
labels: []
assignee: null
created_at: '2026-08-03T14:24:08.702871Z'
updated_at: '2026-08-03T15:30:55.613731Z'
work_branch: epic-EXOCOMP-209--task-EXOCOMP-213
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 32cbdb1c1b24703e141b54caf1d9a151a63f8bab4261a8d561033e5c031732b7
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:30:48.070684+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: ** The authoritative project task corpus (current project\
    \ tracker) shows EXOCOMP-213 as the only Open task. All other tasks visible in\
    \ the corpus (EXOCOMP-10\u2013EXOCOMP-123) are in terminal states (Archived or\
    \ Merged) and therefore excluded as duplicate candidates per policy. No active\
    \ task in the corpus covers management-policy type definition or hierarchical\
    \ resolver implementation. The coordination peers (EXOCOMP-127, 209, 214\u2013\
    219, 225, 228) are listed but not present in the authoritative corpus, so cannot\
    \ be evaluated as duplicates from available data.\nLooking at this duplicate investigation\
    \ for **EXOCOMP-213** (Define management-policy types and resolver), I need to\
    \ search the authoritative project task corpus for any active duplicate.\n\n##\
    \ Investigation\n\n**Task Description:** EXOCOMP-213 calls for adding shared observe/manage\
    \ policy types and a pure deterministic resolver for hierarchical management modes\
    \ across global, cluster, cluster/service, node, and node/service scopes.\n\n\
    **Search Scope:** I've reviewed the provided authoritative project task corpus\
    \ (EXOCOMP-10 through EXOCOMP-123) looking for:\n- Tasks about management policies\n\
    - Tasks about policy resolution\n- Tasks about mode/scope-based rules\n- Any task\
    \ covering observe/manage policy types\n\n**Findings:**\n\nThe corpus shows:\n\
    - **Only 1 Open task:** EXOCOMP-213 (the current task)\n- **All other tasks in\
    \ corpus:** Terminal states (Archived or Merged)\n  - EXOCOMP-10 through EXOCOMP-16\
    \ (various milestone tasks): Archived\n  - EXOCOMP-100 through EXOCOMP-123 (coordinator,\
    \ recovery, remediation): Archived\n\nExcluded per instructions (terminal states):\n\
    - All Archived tasks\n- All Merged tasks\n\n**Peer coordination tasks mentioned\
    \ but not in corpus:**\n- EXOCOMP-127, 209, 214\u2013219, 225, 228 (listed as\
    \ dependencies/siblings) do not appear in the provided authoritative corpus\n\n\
    Since the authoritative task corpus shows no active (non-terminal) duplicate candidates\
    \ for the management-policy resolver scope, and all other tasks visible are in\
    \ terminal states:\n\n---\n\nFocus handoff: duplicate_detector\n\nDuplicate preflight\
    \ verdict: no_duplicate\n\nMatches: none\n\n**Evidence:** The authoritative project\
    \ task corpus (current project tracker) shows EXOCOMP-213 as the only Open task.\
    \ All other tasks visible in the corpus (EXOCOMP-10\u2013EXOCOMP-123) are in terminal\
    \ states (Archived or Merged) and therefore excluded as duplicate candidates per\
    \ policy. No active task in the corpus covers management-policy type definition\
    \ or hierarchical resolver implementation. The coordination peers (EXOCOMP-1"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: ca87d830-741b-4635-9174-06be73c3ddf9
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-213
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-213
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:29:45.162449+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 1813
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 1813
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1813
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:30:48.070481+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-213__20260803T153000Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-209--task-EXOCOMP-213
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:30:48.074361+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add shared observe/manage policy types and a pure deterministic resolver for global, cluster, cluster/service, node, and node/service scopes.

Acceptance criteria:
- Missing policy resolves to observe.
- Node/service overrides all other matching scopes.
- Node and cluster/service are peers; observe wins disagreement.
- Node-only and cluster-level action resolution follows the plan.
- Results contain effective mode, winning scope or conflict, matched rules, and policy version.
- Invalid scope/identity combinations fail closed without creating atoms from input.

Tests: Add exhaustive table-driven tests for every scope, agreement, disagreement, absent rule, inheritance, deletion result, ordering, and malformed identity; run make test, make fmt-check, and make lint.

Out of scope: Database access, service-key discovery, transport, UI, and execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:29
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:29
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:30
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 1.8K out [1.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 10s
- Log: EXOCOMP-213__20260803T153000Z.jsonl
---
<!-- COMMENTS:END -->
