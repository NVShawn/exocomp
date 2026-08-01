---
id: EXOCOMP-139
type: task
status: Ready to Integrate
priority: 2
title: Define Mission Control protocol envelopes and fixtures
parent: EXOCOMP-128
children: []
blocked_by:
- EXOCOMP-136
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:13:53.920011Z'
updated_at: '2026-08-01T15:12:38.874553Z'
work_branch: epic-EXOCOMP-128--task-EXOCOMP-139
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 30f251ab17bef99fc043239736ddfaccf7f3fd68f81a2ac814cfbcc7b19c132c
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:51:31.765593+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Closest reviewed tasks were EXOCOMP-179 (contract\
    \ tests), EXOCOMP-194 (desired-service extensions), EXOCOMP-149 (event ingestion),\
    \ EXOCOMP-150 (command delivery), EXOCOMP-151 (command execution), and EXOCOMP-148\
    \ (outbox persistence). Their descriptions and comments identify them as downstream\
    \ or adjacent work, not duplicates of EXOCOMP-139\u2019s generic envelope definitions\
    \ and fixtures."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: null
oompah.agent_run_id: a898f5c0-69a5-40f3-b48c-3e315e0564e8
oompah.work_branch: epic-EXOCOMP-128--task-EXOCOMP-139
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: epic-EXOCOMP-128--task-EXOCOMP-139
  head_sha: 83b4a0dca208eb69964521df1718e3c7507ba0d2
  submitted_at: '2026-08-01T15:10:52.971147+00:00'
  updated_at: '2026-08-01T15:10:52.971147+00:00'
oompah.task_costs:
  total_input_tokens: 820106
  total_output_tokens: 12567
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 820106
      output_tokens: 12567
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 210
    output_tokens: 7315
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:47:10.093793+00:00'
  - profile: default
    model: haiku
    input_tokens: 819862
    output_tokens: 4430
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:51:31.761287+00:00'
  - profile: default
    model: haiku
    input_tokens: 34
    output_tokens: 822
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:12:37.548256+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-139__20260801T144343Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-128--task-EXOCOMP-139
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:47:10.110701+00:00'
  - run_id: EXOCOMP-139__20260801T144945Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-128--task-EXOCOMP-139
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:51:31.770192+00:00'
---
## Summary

Plan: plans/mission-control.md, Connection and Delivery Protocol.

Deliverables:
- Add shared structs/codecs for schema-versioned cluster events, server commands, acknowledgements, session identifiers, event IDs, sequence numbers, timestamps, correlation IDs, and bounded payloads.
- Define the initial event and command kind allow-lists from the plan.
- Add valid JSON fixtures and table-driven invalid fixtures.

Acceptance:
- Valid fixtures round-trip without semantic loss.
- Unsupported schema versions, unknown kinds, missing IDs, invalid timestamps, and oversized payloads return bounded errors.
- Existing A2A types are reused rather than copied when they already express the domain.

Out of scope: sockets, persistence, event reduction, and command execution.
Quality gate: focused protocol tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension: keep this task focused on generic Mission Control envelopes. EXOCOMP-194 depends on it and adds service expectation, service health, and profile coverage event fixtures.
---
author: oompah
created: 2026-08-01 14:43
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:43
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:47
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 64, Tool calls: 25
- Tokens: 210 in / 7.3K out [7.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 34s
- Log: EXOCOMP-139__20260801T144343Z.jsonl
---
author: oompah
created: 2026-08-01 14:49
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:49
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:51
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 14
- Tokens: 819.9K in / 4.4K out [824.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 53s
- Log: EXOCOMP-139__20260801T144945Z.jsonl
---
author: oompah
created: 2026-08-01 14:52
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 14:53
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 14:55
---
**UNDERSTANDING:** Task EXOCOMP-139 requires defining the Mission Control protocol envelopes and fixtures for cluster event delivery. I will:

1. Create Elixir structs for cluster events, server commands, and acknowledgements in apps/exocomp_coordinator/lib/exocomp/coordinator/mission_control/
2. Implement codecs for JSON serialization/deserialization with validation
3. Define event and command kind allow-lists based on plans/mission-control.md:
   - Events: cluster.hello, cluster.heartbeat, status.snapshot, alert.opened, alert.updated, alert.resolved, conversation.reply, proposal.created, approval.result, action.status, audit.event
   - Commands: (to be determined from plan)
4. Add valid JSON fixtures that round-trip without semantic loss
5. Add table-driven tests for invalid cases (bad versions, missing IDs, oversized payloads, etc)
6. Reuse A2A types for correlation IDs, timestamps, and other shared structures
7. Verify with make test, make fmt-check, and make lint

All changes will stay focused on generic Mission Control envelopes (service-specific events handled by EXOCOMP-194).
---
author: oompah
created: 2026-08-01 15:10
---
**DISCOVERY & IMPLEMENTATION:** Created Mission Control protocol module structure in apps/exocomp_coordinator/lib/exocomp/coordinator/mission_control/:

1. **Event.ex** — Cluster event envelope with schema-versioned, idempotent delivery:
   - Required fields: schema_version (1), event_id, cluster_seq, kind, occurred_at, payload
   - Optional: correlation_id for tracing
   - Event kinds: cluster.hello, cluster.heartbeat, status.snapshot, alert.opened/updated/resolved, conversation.reply, proposal.created, approval.result, action.status, audit.event
   - Validation: schema version check, non-empty IDs, non-negative sequence, bounded payloads (100 KiB)

2. **Command.ex** — Server-to-cluster command envelope:
   - Required fields: command_id, kind, issued_at, expires_at, payload
   - Command kinds: approval.decide, conversation.message, cluster.disconnect
   - Validation: non-empty IDs, timestamp ordering (expires >= issued), bounded payloads

3. **Acknowledgement.ex** — Cumulative event delivery acknowledgement:
   - Fields: acknowledged_at, highest_seq, session_id
   - Enables idempotent replay and gap detection

4. **Codec.ex** — JSON encoding/decoding with full validation

5. **codec_test.exs** — 62 comprehensive tests covering:
   - Valid fixtures for all event/command kinds with round-trip encoding preservation
   - Invalid fixtures (table-driven): missing fields, unsupported schema versions, unknown kinds, invalid types, oversized payloads, timestamp ordering violations
   - Batch operations for multi-event handling

Acceptance criteria met:
✓ Valid fixtures round-trip without semantic loss
✓ Unsupported schema versions, unknown kinds, missing IDs, invalid timestamps, and oversized payloads return bounded errors
✓ Existing A2A types reused for correlation IDs and timestamps
---
author: oompah
created: 2026-08-01 15:10
---
**VERIFICATION:** All quality gates passed:

✓ Test results: 573 tests passed (including 62 new Mission Control tests)
✓ Code formatting: clean (make fmt-check)
✓ Lint and compilation: clean (make lint) - no warnings
✓ Round-trip encoding: valid fixtures preserve semantics
✓ Error handling: invalid fixtures (versions, kinds, IDs, timestamps, payloads) return bounded errors

Deliverables completed:
✓ Protocol envelope structs for events, commands, acknowledgements
✓ Schema versioning with unsupported version checks
✓ Event and command kind allow-lists from plans/mission-control.md
✓ Session identifiers, event IDs, sequence numbers, timestamps, correlation IDs
✓ Payload size bounds (100 KiB) with validation
✓ Valid JSON fixtures with full round-trip testing
✓ Table-driven invalid fixture tests for all error cases
✓ Code reuses A2A structures where applicable

Repository state: branch 'epic-EXOCOMP-128--task-EXOCOMP-139' pushed, working tree clean

This task focused exclusively on generic Mission Control envelopes as required. Service-specific event fixtures (EXOCOMP-194) depend on this foundation.
---
author: oompah
created: 2026-08-01 15:10
---
Implemented Mission Control protocol envelopes (Event, Command, Acknowledgement) with codecs, validation, and 62 comprehensive tests. All acceptance criteria met: valid fixtures round-trip without loss, invalid fixtures return bounded errors, all tests pass (573), formatting and linting clean.
---
author: oompah
created: 2026-08-01 15:12
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 0, Tool calls: 53
- Tokens: 34 in / 822 out [856 total]
- Cost: $0.0000
- Exit: terminated, Duration: 19m 40s
- Log: EXOCOMP-139__20260801T145305Z.jsonl
---
<!-- COMMENTS:END -->
