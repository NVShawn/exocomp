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
updated_at: '2026-08-03T15:51:57.960338Z'
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
    Matches: none\nEvidence: Duplicate preflight verdict: inconclusive\nMatches: none\n\
    **Focus handoff: duplicate_detector**\n\n**Duplicate preflight verdict: inconclusive**\n\
    \n**Matches: none**\n\n**Evidence:**\n\nThe current task corpus does not include\
    \ the coordination peer tasks explicitly listed in the advisory coordination message\
    \ for EXOCOMP-217. The coordination message identifies the following peers:\n\
    - EXOCOMP-127 (dependency)\n- EXOCOMP-213, EXOCOMP-214, EXOCOMP-215 (epic-siblings)\n\
    - EXOCOMP-216, EXOCOMP-218 (dependency, epic-sibling)\n\nThese tasks are absent\
    \ from the provided corpus, which ends at EXOCOMP-123 (all tasks in terminal Archived\
    \ states). Since EXOCOMP-217's scope is \"Add management-policy HTTP APIs\" with\
    \ a plan in `plans/hierarchical-management-modes.md`, and its parent epic is EXOCOMP-209,\
    \ the most likely duplicate candidates would be among these unincluded epic-siblings\
    \ and dependencies, which may cover overlapping management or policy API surfaces.\n\
    \nWithin the provided corpus (EXOCOMP-10 through EXOCOMP-123, all Archived), no\
    \ task describes policy override HTTP APIs, management-policy endpoints, or hierarchical\
    \ management modes. The corpus covers diagnostics, infrastructure, release qualification,\
    \ and coordinator foundation work\u2014distinct scopes from policy management\
    \ APIs.\n\n**Reason for inconclusive verdict:** The coordination message warns\
    \ that interfaces may overlap with peers, but those specific peers are not visible\
    \ in the reference task corpus. A conclusive no-duplicate verdict would require\
    \ access to EXOCOMP-213 through EXOCOMP-218 and EXOCOMP-127 to confirm their scopes\
    \ do not duplicate EXOCOMP-217's policy API work."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 2
  retry_after: '2026-08-03T15:53:46.576173+00:00'
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 9c22c570-28c0-4aec-b431-cfbcb787bc9b
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-217
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-217
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:50:42.351401+00:00'
oompah.task_costs:
  total_input_tokens: 20
  total_output_tokens: 4267
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 20
      output_tokens: 4267
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
<!-- COMMENTS:END -->
