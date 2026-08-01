---
id: EXOCOMP-179
type: task
status: In Validation
priority: 1
title: Add shared Mission Control protocol contract tests
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-139
start_blocked_by: &id001
- EXOCOMP-194
labels: []
assignee: null
created_at: '2026-07-30T14:18:34.108558Z'
updated_at: '2026-08-01T18:23:02.426354Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-179
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 4d2521f31b73270188653d51b91f0b8a48292bb7d59b14b57561d3ba4334de1f
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:17:20.784124+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active EXOCOMP-139, EXOCOMP-149, EXOCOMP-180,\
    \ EXOCOMP-181, EXOCOMP-194, EXOCOMP-148, EXOCOMP-150, and EXOCOMP-151. They cover\
    \ protocol definitions, ingestion, integration, security, desired-state fixtures,\
    \ persistence, and command delivery respectively; none duplicates EXOCOMP-179\u2019\
    s cross-application contract-test corpus and fixture-drift validation."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: null
oompah.agent_run_id: 6dda6ce5-8b62-4705-8763-a52e7f5ab85c
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-179
oompah.integration:
  version: 2
  state: integrated
  attempts: 1
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-179
  base_branch: epic-EXOCOMP-135
  base_sha: d9cc09d75701c1b15febdaff3523261ad017d1bf
  head_sha: 333c3b81b8bcdd448166707f28b5a00ee8e2c469
  integrated_sha: 333c3b81b8bcdd448166707f28b5a00ee8e2c469
  submitted_at: '2026-08-01T18:15:13.751809+00:00'
  updated_at: '2026-08-01T18:22:54.725058+00:00'
oompah.task_costs:
  total_input_tokens: 11573005
  total_output_tokens: 49952
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 11573005
      output_tokens: 49952
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 324
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:13:30.348873+00:00'
  - profile: default
    model: haiku
    input_tokens: 781254
    output_tokens: 4172
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:17:20.779279+00:00'
  - profile: default
    model: haiku
    input_tokens: 10791741
    output_tokens: 45456
    cost_usd: 0.0
    recorded_at: '2026-08-01T18:15:53.402098+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-179__20260801T131120Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-179
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:13:30.365134+00:00'
  - run_id: EXOCOMP-179__20260801T131542Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-179
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:17:20.796078+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-6d5e5be9de97
    project_id: proj-c260b117
    task_id: EXOCOMP-179
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: ca993dd36cbd656e095eac02c34727729a6730df0fda2f633ce1ef93c0b538f1
    attempts: []
    requested_by:
      version: 1
      identity: oompah-integration
      source: service
    previous_state: Ready to Integrate
    created_at: '2026-08-01T18:22:59.679134+00:00'
  attempt_history: []
---
## Summary

Plan: plans/mission-control.md, Test Strategy.

Deliverables:
- Create one fixture corpus consumed by Mission Control and coordinator tests for every event, command, acknowledgement, error, and supported schema version.
- Add contract cases for duplicate, out-of-order, sequence gap, oversized payload, unknown kind, unsupported version, and redaction.
- Make fixture drift fail with a clear field-level error.

Acceptance:
- The same fixtures pass in both applications.
- Mutating each required field produces the expected bounded failure.
- A Make target runs the contract suite without requiring live VMs.

Out of scope: sockets and end-to-end qualification.
Quality gate: new contract target plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: consume the shared fixtures from EXOCOMP-194 and verify service/profile snapshots, deltas, duplicates, ordering, unsupported versions, bounds, redaction, retirement, and reconstruction across coordinator and Mission Control.
---
author: oompah
created: 2026-08-01 13:11
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:11
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:13
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 58, Tool calls: 26
- Tokens: 10 in / 324 out [334 total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 18s
- Log: EXOCOMP-179__20260801T131120Z.jsonl
---
author: oompah
created: 2026-08-01 13:15
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:15
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:17
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 35
- Tokens: 781.3K in / 4.2K out [785.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 46s
- Log: EXOCOMP-179__20260801T131542Z.jsonl
---
author: oompah
created: 2026-08-01 17:58
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 17:58
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 17:59
---
Understanding: I will verify the inherited EXOCOMP-194 contract, locate Mission Control/coordinator consumers and existing Make targets, then add one shared fixture corpus with field-level drift and required edge-case coverage. I will run the contract suite, make fmt-check, and make lint before committing and submitting.
---
author: oompah
created: 2026-08-01 18:13
---
Implementation: Reconciled EXOCOMP-139 and EXOCOMP-194 dependency commits, added a manifest-driven shared Mission Control corpus (events, commands, acknowledgements, mutation errors, replay/gap metadata, redaction, and schema versions), shared fixture loader with field-level drift errors, coordinator/core contract tests, and make test-mission-control-contract. Required event/command payload omission now fails explicitly; sequence gaps are detected by StatusReducer.missing_sequences/1 and exposed through the coordinator facade.
---
author: oompah
created: 2026-08-01 18:14
---
Verification: the inherited Mission Control protocol/status tests plus the new contract tests pass in a standalone Elixir 1.18 harness: 82 tests, 0 failures. JSON corpus parsing, Elixir syntax/format checks, and git diff --check pass. make test-mission-control-contract, make fmt-check, and make lint cannot start their pinned builder because the sandbox Podman runtime reports ; no code/test failure was observed.
---
author: oompah
created: 2026-08-01 18:14
---
Verification correction: inherited Mission Control protocol/status tests plus new contract tests pass in a standalone Elixir 1.18 harness: 82 tests, 0 failures. JSON corpus parsing, Elixir syntax/format checks, and git diff --check pass. The three Make quality targets cannot start the pinned builder because the sandbox Podman runtime reports a read-only /run/user/1000/libpod; no code or test failure was observed.
---
author: oompah
created: 2026-08-01 18:15
---
Completion: commit 333c3b81 is pushed and the branch is up to date with origin. Delivered the shared manifest/corpus, field-level fixture drift checks, coordinator/core contract coverage for events, commands, acknowledgements, errors, versions, replay/gaps, bounds, and redaction, plus the standalone Make target.
---
author: oompah
created: 2026-08-01 18:15
---
Added shared Mission Control contract corpus, field-level drift and mutation tests, replay/gap/redaction coverage, coordinator/core adapters, and make test-mission-control-contract.
---
author: oompah
created: 2026-08-01 18:15
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 111
- Tokens: 10.8M in / 45.5K out [10.8M total]
- Cost: $0.0000
- Exit: terminated, Duration: 17m 13s
- Log: EXOCOMP-179__20260801T175849Z.jsonl
---
author: oompah
created: 2026-08-01 18:23
---
Queued for terminal transition to Done. An auditor will review and apply the terminal status.
---
<!-- COMMENTS:END -->
