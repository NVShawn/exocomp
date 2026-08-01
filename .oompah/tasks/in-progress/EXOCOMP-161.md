---
id: EXOCOMP-161
type: task
status: In Progress
priority: 1
title: Store and validate typed remedy proposals
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-158
- EXOCOMP-160
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:19.626537Z'
updated_at: '2026-08-01T13:05:57.852866Z'
work_branch: epic-EXOCOMP-132--task-EXOCOMP-161
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 74088b2caf2a8431cc204ab33f3062713035a5d1363667b0b053a1bd79b56b70
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:55:54.283226+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active EXOCOMP-159, EXOCOMP-160, EXOCOMP-162,\
    \ EXOCOMP-163, EXOCOMP-169, EXOCOMP-171, EXOCOMP-175, and EXOCOMP-201. They cover\
    \ model output, command delivery, approval, execution, UI, audit, retention, or\
    \ restricted execution\u2014not organization-scoped proposal persistence and validation.\
    \ Archived EXOCOMP-61 and EXOCOMP-21 are historical and excluded."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: eeccde1a-3da5-43ad-8e64-ab5a30b51198
oompah.work_branch: epic-EXOCOMP-132--task-EXOCOMP-161
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-132--task-EXOCOMP-161
  base_branch: epic-EXOCOMP-132
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:56:34.268003+00:00'
oompah.task_costs:
  total_input_tokens: 411207
  total_output_tokens: 5101
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 411207
      output_tokens: 5101
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 411207
    output_tokens: 5101
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:55:54.276955+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-161__20260801T125219Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-132--task-EXOCOMP-161
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:55:54.294428+00:00'
---
## Summary

Plan: plans/mission-control.md, Typed Remedy Approval.

Deliverables:
- Add organization-scoped proposal records for IDs, cluster/node target, catalog action, validated parameters, evidence reference/hash, risk, expected disruption, rationale, policy result, and expiry.
- Validate proposals against the shared action catalog and immutable parameter schema before persistence.
- Link each proposal to its conversation message and correlation/task IDs.

Acceptance:
- Tests cover valid proposal, unknown action, caller-supplied command/path, invalid target/parameters, stale/missing evidence, duplicate ID, expiry, and organization mismatch.
- Persisting a proposal cannot execute it.

Out of scope: approval and coordinator execution.
Quality gate: focused schema/context tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:52
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:52
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:55
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 2, Tool calls: 25
- Tokens: 411.2K in / 5.1K out [416.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 45s
- Log: EXOCOMP-161__20260801T125219Z.jsonl
---
author: oompah
created: 2026-08-01 12:56
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:56
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 12:58
---
UNDERSTANDING: Task is to implement storage and validation of typed remedy proposals. Deliverables: (1) Add organization-scoped proposal records with IDs, cluster/node target, catalog action, validated parameters, evidence reference/hash, risk, expected disruption, rationale, policy result, and expiry. (2) Validate proposals against action catalog and parameter schema before persistence. (3) Link proposals to conversation messages and correlation/task IDs. Test coverage required for valid proposal, unknown action, caller-supplied command/path, invalid target/parameters, stale/missing evidence, duplicate ID, expiry, organization mismatch. Key constraint: persisting a proposal cannot execute it. Will explore existing codebase, particularly EXOCOMP-158 work on conversations to understand the structure.
---
author: oompah
created: 2026-08-01 12:59
---
DISCOVERY: Merged EXOCOMP-158 work on bounded conversations. Found existing RemediationLifecycle uses RemediationAdapter callback pattern for validate/decide. Plan: Create Proposal struct with organization scoping, cluster/node target, catalog action, validated parameters, evidence reference/hash, risk, disruption, rationale, policy result, and expiry. Implement Proposals context (GenServer store) following Conversations pattern with validation against action catalog and parameter schema. Link proposals to conversation messages and correlation/task IDs through attrs. Tests cover valid, unknown action, caller-supplied command/path, invalid target/params, stale/missing evidence, duplicate ID, expiry, org mismatch.
---
author: oompah
created: 2026-08-01 13:05
---
IMPLEMENTATION: Created Proposal struct and Proposals context for typed remedy proposal storage and validation.

Files added:
- apps/exocomp_mission_control/lib/exocomp/mission_control/proposal.ex (280 LOC): Struct with validation for proposal fields, risk levels, policy results, evidence staleness checking, expiry detection
- apps/exocomp_mission_control/lib/exocomp/mission_control/proposals.ex (247 LOC): GenServer store with catalog validation, organization scoping, list filtering
- apps/exocomp_mission_control/test/exocomp/mission_control/proposals_test.exs (660 LOC): Comprehensive test suite covering all acceptance criteria

Key features:
- Organization-scoped with cross-organization prevention
- Action catalog validation (unknown action rejection)
- Unsupported field rejection (no command/path parameters allowed)
- Parameter validation (must be map with string keys)
- Evidence reference support with staleness checking
- Proposal expiry with default 1-hour TTL
- Unique ID enforcement within organization
- Text field size limits (expected_disruption: 256B, rationale: 2048B)
- Automatic default values and field normalization
- Linked to conversation messages and correlation/task IDs

Tests pass: 511/511. Quality gates: fmt-check ✓, lint ✓, compile ✓
---
<!-- COMMENTS:END -->
