---
id: EXOCOMP-148
type: task
status: In Validation
priority: 1
title: Persist the coordinator event outbox
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-145
- EXOCOMP-139
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:04.648480Z'
updated_at: '2026-08-03T18:04:47.209035Z'
work_branch: epic-EXOCOMP-130--task-EXOCOMP-148
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: f59fe47a4d808fae3f7bde52d11c9cebc550871a749779803f03f675c00a91dd
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:22:31.859429+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active EXOCOMP-145, EXOCOMP-139, EXOCOMP-147,\
    \ EXOCOMP-149, EXOCOMP-150, EXOCOMP-151, and EXOCOMP-180. Their scopes cover configuration,\
    \ envelopes, reconnect behavior, server ingestion/commands, and integration testing;\
    \ none duplicates EXOCOMP-148\u2019s coordinator event outbox persistence."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 92ee7e48-f765-427a-9547-3c75ccb876c1
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-148
oompah.integration:
  version: 2
  state: integrated
  attempts: 1
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-148
  base_branch: epic-EXOCOMP-130
  base_sha: eaeeaf0872984e655611d0092397e9c800e1bf6b
  head_sha: 8400a54a72025d415f60d00e4e22540626702567
  integrated_sha: 8400a54a72025d415f60d00e4e22540626702567
  submitted_at: '2026-08-01T12:41:03.439762+00:00'
  updated_at: '2026-08-03T17:41:44.088917+00:00'
  dependency_heads:
    EXOCOMP-145: b0d047ea97d00deb5c9b83054ddfb6de1491f0a9
oompah.task_costs:
  total_input_tokens: 11794156
  total_output_tokens: 64047
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 11794104
      output_tokens: 62208
      cost_usd: 0.0
    unknown:
      input_tokens: 52
      output_tokens: 1839
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 739579
    output_tokens: 11575
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:22:31.858542+00:00'
  - profile: default
    model: haiku
    input_tokens: 11054525
    output_tokens: 50633
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:41:32.539413+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 52
    output_tokens: 1839
    cost_usd: 0.0
    recorded_at: '2026-08-03T18:03:56.197702+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-148__20260801T121725Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-130--task-EXOCOMP-148
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:22:31.884686+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-d79586978613
    project_id: proj-c260b117
    task_id: EXOCOMP-148
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 92bf545d74b9fc5173e5747812d1db03e35d469f672dab8b840d101b0fca75d3
    attempts:
    - version: 1
      attempt_id: attempt-95bf8dff885e
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 92bf545d74b9fc5173e5747812d1db03e35d469f672dab8b840d101b0fca75d3
      created_at: '2026-08-03T17:43:30.654201+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-03T17:43:30.654201+00:00'
      branch_key: epic-EXOCOMP-130--task-EXOCOMP-148
      failure_classification: policy_incompatibility
      ended_at: '2026-08-03T18:03:57.951553+00:00'
      failure_reason: 'read-only auditor exceeded the policy-denial limit (3): Error:
        auditor capability policy permits only read-only repository inspection and
        configured test commands; command denied'
      next_retry_at: '2026-08-03T18:04:07.951530+00:00'
    - version: 1
      attempt_id: attempt-640a0b455ae3
      target_state: Done
      request_state: in_progress
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 92bf545d74b9fc5173e5747812d1db03e35d469f672dab8b840d101b0fca75d3
      created_at: '2026-08-03T18:04:32.417674+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-08-03T18:04:32.417674+00:00'
      branch_key: epic-EXOCOMP-130--task-EXOCOMP-148
      candidate_rotation_count: 1
    requested_by:
      version: 1
      identity: oompah-integration
      source: service
    previous_state: Ready to Integrate
    created_at: '2026-08-03T17:41:51.024336+00:00'
    updated_at: '2026-08-03T18:04:32.417674+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-95bf8dff885e
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 92bf545d74b9fc5173e5747812d1db03e35d469f672dab8b840d101b0fca75d3
    created_at: '2026-08-03T17:43:30.654201+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-03T17:43:30.654201+00:00'
    branch_key: epic-EXOCOMP-130--task-EXOCOMP-148
    failure_classification: policy_incompatibility
    ended_at: '2026-08-03T18:03:57.951553+00:00'
    failure_reason: 'read-only auditor exceeded the policy-denial limit (3): Error:
      auditor capability policy permits only read-only repository inspection and configured
      test commands; command denied'
    next_retry_at: '2026-08-03T18:04:07.951530+00:00'
  - version: 1
    attempt_id: attempt-640a0b455ae3
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 92bf545d74b9fc5173e5747812d1db03e35d469f672dab8b840d101b0fca75d3
    created_at: '2026-08-03T18:04:32.417674+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-08-03T18:04:32.417674+00:00'
    branch_key: epic-EXOCOMP-130--task-EXOCOMP-148
    candidate_rotation_count: 1
---
## Summary

Plan: plans/mission-control.md, Connection and Delivery Protocol.

Deliverables:
- Add a durable coordinator event outbox under /var/lib/exocomp-coordinator with monotonic per-cluster sequence allocation and stable event IDs.
- Persist before send and delete only after a committed contiguous acknowledgement.
- Permit replacement of an older unsent status snapshot only; never discard alert, chat, proposal, approval, action, or audit events.
- Enforce schema, size, and redaction checks before persistence.

Acceptance:
- Tests cover process restart, host-state reopen, duplicate enqueue, snapshot coalescing, full/corrupt storage, and acknowledgement.
- Durable event kinds survive reconnect without loss.

Out of scope: server ingestion and command delivery.
Quality gate: focused persistence tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:17
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:17
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:22
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 2, Tool calls: 29
- Tokens: 739.6K in / 11.6K out [751.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 5m 14s
- Log: EXOCOMP-148__20260801T121725Z.jsonl
---
author: oompah
created: 2026-08-01 12:22
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:22
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 12:23
---
Understanding: implement a durable coordinator event outbox with monotonic per-cluster sequencing, stable IDs, atomic persistence/acknowledgement, snapshot-only coalescing, validation/redaction, and restart/corruption tests; first I am locating the coordinator protocol and existing storage patterns.
---
author: oompah
created: 2026-08-01 12:29
---
Discovery: no existing Mission Control transport/outbox exists in the coordinator. The implementation boundary is a new Exocomp.Coordinator.EventOutbox module plus supervised startup/config; existing Audit.redact provides the project redaction policy, and the protocol plan requires sequence continuity across snapshot replacement.
---
author: oompah
created: 2026-08-01 12:36
---
Implementation: added EventOutbox with versioned atomic JSON persistence, per-cluster monotonic counters, stable generated/supplied event IDs, duplicate idempotency, unsent status.snapshot coalescing with sequence reuse, sent marking, contiguous acknowledgements, size/schema/redaction validation, corrupt/full-storage handling, supervised startup, and production/test path configuration. Added focused ExUnit coverage for restart, duplicates, coalescing, durable kinds, acknowledgements, redaction/schema, full storage, and corruption.
---
author: oompah
created: 2026-08-01 12:39
---
Verification: focused EventOutbox tests ran in a local Elixir harness with the OTP JSON adapter (8 tests, 0 failures), and mix format --check-formatted plus syntax parsing pass. make test and make lint completed offline checks but their pinned Elixir container steps were blocked by the environment's read-only podman configuration; make fmt-check was blocked for the same reason. Host mix cannot run the project because it is Elixir 1.18.3 versus the declared 1.20.2.
---
author: oompah
created: 2026-08-01 12:40
---
Completion: commit 6e22ba09 adds and wires the durable EventOutbox, configures /var/lib/exocomp-coordinator/event_outbox.json with runtime cluster identity, and adds focused persistence coverage. Branch was pulled/rebased, pushed, and is clean and up to date with origin. Focused tests pass; containerized make test/fmt-check/lint were attempted and blocked only by the read-only podman configuration.
---
author: oompah
created: 2026-08-01 12:41
---
Implemented durable coordinator event outbox with atomic persistence, monotonic per-cluster sequences, stable IDs, snapshot coalescing, validation/redaction, contiguous acknowledgements, restart/corruption/capacity coverage, and supervised production configuration.
---
author: oompah
created: 2026-08-01 12:41
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 102
- Tokens: 11.1M in / 50.6K out [11.1M total]
- Cost: $0.0000
- Exit: terminated, Duration: 18m 45s
- Log: EXOCOMP-148__20260801T122254Z.jsonl
---
author: oompah
created: 2026-08-03 17:41
---
Queued for terminal transition to Done. An auditor will review and apply the terminal status.
---
author: oompah
created: 2026-08-03 17:43
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-03 17:43
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-03 18:03
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 0, Tool calls: 35
- Tokens: 52 in / 1.8K out [1.9K total]
- Cost: $0.0000
- Exit: terminated, Duration: 20m 22s
- Log: EXOCOMP-148__20260803T174343Z.jsonl
---
author: oompah
created: 2026-08-03 18:04
---
Auditor attempt was stopped after repeated policy denials; a different independent candidate will be tried.
---
author: oompah
created: 2026-08-03 18:04
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-08-03 18:04
---
Focus: Completion Auditor
---
<!-- COMMENTS:END -->
