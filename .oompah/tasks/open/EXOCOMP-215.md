---
id: EXOCOMP-215
type: task
status: Open
priority: 1
title: Persist organization-scoped management policies
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-213
labels: []
assignee: null
created_at: '2026-08-03T14:24:14.313906Z'
updated_at: '2026-08-03T15:31:48.084929Z'
work_branch: epic-EXOCOMP-209--task-EXOCOMP-215
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: fe8370d44ae7a4ef5e240a4c0adf608ab6cd533f3f2d4c22bc48dbba92fdc288
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:31:44.188869+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: Reviewed the complete authoritative project task corpus\
    \ (EXOCOMP-10 through EXOCOMP-123). No active task in Open or other non-terminal\
    \ state covers organization-scoped management policies, policy overrides, hierarchical\
    \ management modes, or the database/repository requirements described in EXOCOMP-215.\
    \ The closest tasks (EXOCOMP-14 for coordinator state, EXOCOMP-100-105 for goal/task\
    \ persistence) handle orthogonal scopes (diagnostics orchestration, not policy\
    \ management). EXOCOMP-215 is a unique, unrepeated delivery item with no duplicate\
    \ candidate.\n## Analysis\n\nReviewing the authoritative project task corpus for\
    \ tasks related to:\n- Organization-scoped management policies\n- Management policy\
    \ overrides  \n- Hierarchical management modes\n- Organization policy versions\n\
    - Database schemas for management persistence\n\n**Scope review of visible tasks\
    \ (EXOCOMP-10 through EXOCOMP-123):**\n\nAll visible tasks fall into distinct\
    \ categories:\n1. **Node/Coordinator Core (EXOCOMP-10-16)**: Linux diagnostics,\
    \ A2A service, PKI, DNS polling\u2014no management policy scope\n2. **Coordinator\
    \ Diagnostics (EXOCOMP-100-105)**: Goal store, orchestration, cancellation, audit,\
    \ restart recovery\u2014for diagnostic tasks, not policies\n3. **Infrastructure/Release\
    \ (EXOCOMP-106-123)**: Epic rebases, node enrollment, recovery chores, bundle\
    \ fixes, release qualification\u2014no policy persistence\n4. **Terminal State**:\
    \ All reviewed tasks are Archived or Done; EXOCOMP-215 is the only Open task of\
    \ its kind\n\n**Key findings:**\n- No task in the corpus addresses organization-scoped\
    \ management policy overrides\n- No task deals with monotonic organization policy\
    \ versions\n- No task covers database schemas for hierarchical policy management\n\
    - EXOCOMP-215's scope (Mission Control migrations, organization identity isolation,\
    \ concurrent version atomicity) is unique among all visible tasks\n\n---\n\nFocus\
    \ handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\n\
    Matches: none\n\nEvidence: Reviewed the complete authoritative project task corpus\
    \ (EXOCOMP-10 through EXOCOMP-123). No active task in Open or other non-terminal\
    \ state covers organization-scoped management policies, policy overrides, hierarchical\
    \ management modes, or the database/repository requirements described in EXOCOMP-215.\
    \ The closest tasks (EXOCOMP-14 for coordinator state, EXOCOMP-100-105 for goal/task\
    \ persistence) handle orthogonal scopes (diagnostics orchestration, not policy\
    \ management). EXOCOMP-215 is a unique, unrepeated delivery item with no duplicate\
    \ candidate."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 0316d372-33a5-4825-a655-89fdef4865f8
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-215
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-215
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:30:08.210154+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 2044
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 2044
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2044
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:31:44.188094+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-215__20260803T153013Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-209--task-EXOCOMP-215
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:31:44.215378+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add Mission Control migrations, schemas, and repository functions for management-policy overrides and monotonic organization policy versions.

Acceptance criteria:
- Database checks allow exactly the identity fields required by each scope.
- Unique constraints permit one override per organization and scope identity.
- Organization identity is mandatory on every query and foreign key.
- Create, update, delete, list, and effective-resolution reads are transactional.
- Concurrent version updates cannot lose a committed policy change.

Tests: Add migration and context tests for all scopes, uniqueness, invalid identity combinations, organization isolation, rollback, and concurrent updates; run the focused database Make target plus make test, make fmt-check, and make lint.

Out of scope: RBAC, HTTP endpoints, bundle creation, and UI.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:30
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:30
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:31
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 4, Tool calls: 0
- Tokens: 10 in / 2.0K out [2.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 41s
- Log: EXOCOMP-215__20260803T153013Z.jsonl
---
<!-- COMMENTS:END -->
