---
id: EXOCOMP-189
type: task
status: In Progress
priority: 1
title: Define desired-service types and deterministic merge rules
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-188
labels: []
assignee: null
created_at: '2026-07-30T21:36:59.020887Z'
updated_at: '2026-08-01T14:19:36.249399Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-189
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 6d5af8d008d883ef9e3cf0c6756e1516e15bef843eea0d9378bdf7f813142c14
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:45:48.758021+00:00'
  matched_identifiers: []
  evidence: "Acknowledged. This coordination message confirms EXOCOMP-187 is a peer\
    \ epic-sibling with dependency integration noted. My duplicate investigation remains\
    \ valid:\n\n**My verdict stands: `no_duplicate`**\n\nThe coordination message\
    \ does not identify EXOCOMP-189 as overlapping active work. Even though EXOCOMP-187\
    \ has been integrated (as indicated in the subsequent message), it falls under\
    \ \"terminal state (Done, Merged, or Archived)\" per the Duplicate Investigator\
    \ guidelines and cannot be flagged as an active duplicate target. \n\nMy thorough\
    \ codebase search found no existing implementations of the desired-service types,\
    \ merge resolvers, or recovery-authority rules that EXOCOMP-189 requires\u2014\
    whether from EXOCOMP-187 or any other source in the current branch state.\n\n\
    ---\n\n**Focus handoff: duplicate_detector**\n\n**Duplicate preflight verdict:\
    \ no_duplicate**\n\n**Matches: none**\n\n**Evidence:** Comprehensive search across\
    \ code, tests, and plans yields no implementations of desired-service types, deterministic\
    \ merge rules, recovery-authority distinction, or three-path desired-state extension.\
    \ EXOCOMP-187, noted as an integrated epic-sibling, is in terminal state and excluded\
    \ from active duplicate detection per project guidelines. The task EXOCOMP-189\
    \ is not a duplicate of any active work and can proceed independently."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: caef73ca-1dfc-414c-a784-f41a63261e52
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-189
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-189
  base_branch: epic-EXOCOMP-185
  base_sha: 0f7969a22949a49ab4ff8cc3a169cc77c2810b21
  updated_at: '2026-08-01T14:11:25.694852+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 2595
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 2595
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2595
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:45:48.757124+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-189__20260801T134112Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-185--task-EXOCOMP-189
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:45:48.761690+00:00'
---
## Summary

Plan: plans/mission-control.md, three-path desired-state extension.

Deliverable: Add shared data types and a pure resolver that combines manual, automatic, and cluster-profile expectations for one node and service.

Acceptance criteria:
- The result records node, unit, sorted source set, required probes, expected state, profile context, and recovery-authority source.
- Duplicate services become one effective expectation.
- Automatic discovery alone never grants recovery authority.
- Manual allow-list and shipped-profile authority remain distinguishable.
- Output ordering is deterministic.

Tests: Add table-driven unit tests for each source alone, all source combinations, duplicate probes, stable ordering, and authority merging; run make test.

Out of scope: I/O, polling, incident creation, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:41
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:41
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:45
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 84, Tool calls: 38
- Tokens: 10 in / 2.6K out [2.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 4m 43s
- Log: EXOCOMP-189__20260801T134112Z.jsonl
---
author: oompah
created: 2026-08-01 14:11
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 14:11
---
Focus: Software Engineer
---
author: oompah
created: 2026-08-01 14:11
---
Understanding: add shared desired-service data types and a pure deterministic resolver for one node/service. I will preserve source provenance and authority distinctions, merge duplicate expectations/probes predictably, add table-driven coverage for every source combination and ordering, then run the Makefile test gate.
---
author: oompah
created: 2026-08-01 14:13
---
Discovery: after reconciling the integrated EXOCOMP-187/188/190 commits, inventory v2 supplies manual monitoring services and a cluster_profile identifier, while automatic discovery remains an observation path. No existing shared desired-state API exists. I will add it in exocomp_core as pure source contributions plus canonical effective expectations, keeping manual allow-list and shipped-profile authority as distinct values and automatic non-authority explicit.
---
author: oompah
created: 2026-08-01 14:19
---
Implementation: added exocomp_core desired-service types and resolver. SourceExpectation constructors model manual, automatic, and cluster-profile inputs; resolve/1 groups duplicate node/unit contributions, merges unique sorted probes, retains sorted provenance/profile context, applies deterministic expected-state precedence, and derives authority as manual_allow_list > shipped_profile > nil. Automatic source is structurally non-authoritative. Added table-driven source/combinations, duplicate, ordering, authority, and conflict tests.
---
author: oompah
created: 2026-08-01 14:19
---
Verification: focused compile of both new core modules plus ExUnit execution passed (6 tests, 0 failures); local format check and git diff --check passed. make test completed its offline builder/package checks (13 builder checks plus Python suites) but could not enter the Elixir test/release container because Podman failed to chmod /run/user/1000/libpod on the read-only host filesystem.
---
<!-- COMMENTS:END -->
