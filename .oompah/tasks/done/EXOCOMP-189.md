---
id: EXOCOMP-189
type: task
status: Done
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
updated_at: '2026-08-01T14:30:20.688623Z'
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
  state: integrated
  attempts: 1
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-189
  base_branch: epic-EXOCOMP-185
  base_sha: 0f7969a22949a49ab4ff8cc3a169cc77c2810b21
  head_sha: c3eeb34abbb045e4dcbe3e4703952b1053791cb3
  integrated_sha: c3eeb34abbb045e4dcbe3e4703952b1053791cb3
  submitted_at: '2026-08-01T14:20:30.117288+00:00'
  updated_at: '2026-08-01T14:21:50.506728+00:00'
oompah.task_costs:
  total_input_tokens: 4335316
  total_output_tokens: 28719
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 4335316
      output_tokens: 28719
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2595
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:45:48.757124+00:00'
  - profile: default
    model: haiku
    input_tokens: 4335306
    output_tokens: 26124
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:21:12.882315+00:00'
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
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-86084bb0a154: '2026-08-01T14:30:18.293782+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-189
    target_state: Done
    evidence_fingerprint: f528e484080e6faff2777d2b89b44a2394bda9ff113e97f65ae452f7df526c8e
    audit_ids:
    - audit-a278593d6f38
    kind: result
    applied: true
    retired_at: '2026-08-01T14:30:18.293793+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-189
    audit_id: audit-a278593d6f38
    attempt_id: attempt-86084bb0a154
    target_state: Done
    evidence_fingerprint: f528e484080e6faff2777d2b89b44a2394bda9ff113e97f65ae452f7df526c8e
    status: Done
    audit_ids:
    - audit-a278593d6f38
    applied: false
    created_at: '2026-08-01T14:30:18.293809+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-a278593d6f38
    project_id: proj-c260b117
    task_id: EXOCOMP-189
    target_state: Done
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: f528e484080e6faff2777d2b89b44a2394bda9ff113e97f65ae452f7df526c8e
    attempts:
    - version: 1
      attempt_id: attempt-86084bb0a154
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: f528e484080e6faff2777d2b89b44a2394bda9ff113e97f65ae452f7df526c8e
      created_at: '2026-08-01T14:21:57.073396+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T14:21:57.073396+00:00'
      branch_key: epic-EXOCOMP-185--task-EXOCOMP-189
      verdict: pass
      completed_at: '2026-08-01T14:30:18.293552+00:00'
      ended_at: '2026-08-01T14:30:18.293552+00:00'
    requested_by:
      version: 1
      identity: oompah-integration
      source: service
    previous_state: Ready to Integrate
    created_at: '2026-08-01T14:21:51.749067+00:00'
    updated_at: '2026-08-01T14:30:18.293552+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-86084bb0a154
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: f528e484080e6faff2777d2b89b44a2394bda9ff113e97f65ae452f7df526c8e
    created_at: '2026-08-01T14:21:57.073396+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T14:21:57.073396+00:00'
    branch_key: epic-EXOCOMP-185--task-EXOCOMP-189
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
author: oompah
created: 2026-08-01 14:20
---
Completion: delivered and pushed c3eeb34a on epic-EXOCOMP-185--task-EXOCOMP-189. The shared core resolver now produces one deterministic effective expectation per node/unit, preserving sorted sources/probes/profile context and distinguishable manual/profile authority while excluding automatic authority. Focused tests pass; make test's offline checks pass and its containerized Elixir stage is host-blocked by Podman configuration.
---
author: oompah
created: 2026-08-01 14:20
---
Added shared desired-service source types, deterministic three-path resolver, and table-driven unit coverage; pushed c3eeb34a. Focused tests pass, while make test's containerized Elixir stage is blocked by host Podman configuration.
---
author: oompah
created: 2026-08-01 14:21
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 61
- Tokens: 4.3M in / 26.1K out [4.4M total]
- Cost: $0.0000
- Exit: terminated, Duration: 9m 51s
- Log: EXOCOMP-189__20260801T141128Z.jsonl
---
author: oompah
created: 2026-08-01 14:21
---
Queued for terminal transition to Done. An auditor will review and apply the terminal status.
---
author: oompah
created: 2026-08-01 14:21
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 14:21
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-01 14:30
---
Audit PASS — Done

[REDACTED]

Safe evidence:
- commit: c3eeb34abbb045e4dcbe3e4703952b1053791cb3
- commit_subject: EXOCOMP-189: add deterministic desired-service resolver
- pushed_branch: origin/epic-EXOCOMP-185--task-EXOCOMP-189
- head_matches_remote: true
- diffstat: apps/exocomp_core/lib/exocomp/desired_service.ex +187; apps/exocomp_core/lib/exocomp/desired_service/source_expectation.ex +54; apps/exocomp_core/test/exocomp/desired_service_test.exs +121
- test_file_test_count: 6
- make_test-builders: 13 passed, 0 failed
- make_test-deps: 9 passed, 0 failed
- make_test_containerized_stage: not runnable in auditor sandbox (podman/docker denied); implementer reports focused mix test 6/6 pass and host podman runroot chmod is broken
- ac1_fields_present: node, unit, sources, required_probes, expected_state, profile_context, recovery_authority_source
- ac2_duplicate_collapse: Enum.group_by({node,unit}) + Enum.uniq/Enum.sort on sources and probes
- ac3_automatic_no_authority: authority_for(:automatic) -> nil (structural)
- ac4_distinguishable_authority: :manual_allow_list vs :shipped_profile atoms retained separately
- ac5_deterministic_ordering: sort by {node,unit}; unique_sorted; source_rank+term_to_binary tiebreak
---
<!-- COMMENTS:END -->
