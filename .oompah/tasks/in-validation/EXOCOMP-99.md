---
id: EXOCOMP-99
type: feature
status: In Validation
priority: 1
title: Implement coordinator diagnostic A2A client adapter
parent: EXOCOMP-18
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T04:29:25.236002Z'
updated_at: '2026-08-01T01:44:01.783747Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: e8327ec2-3eea-4ba9-8a1c-df6d6ac3657d
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 106
  total_output_tokens: 10311
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 106
      output_tokens: 10311
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 35
    output_tokens: 8120
    cost_usd: 0.0
    recorded_at: '2026-07-24T16:00:00.910348+00:00'
  - profile: standard
    model: unknown
    input_tokens: 71
    output_tokens: 2191
    cost_usd: 0.0
    recorded_at: '2026-07-24T16:19:55.047934+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    no-auditor-audit-e57dccbb6b4b-3: '2026-07-31T21:16:04.249406+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-99
    target_state: Archived
    evidence_fingerprint: b0e62630a4b564120ae6c051dbfd737340cf70c55554351c64eb5112f80c3aca
    audit_ids:
    - audit-e57dccbb6b4b
    kind: result
    applied: true
    retired_at: '2026-07-31T21:16:04.249418+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-99
    audit_id: audit-e57dccbb6b4b
    attempt_id: no-auditor-audit-e57dccbb6b4b-3
    target_state: Archived
    evidence_fingerprint: b0e62630a4b564120ae6c051dbfd737340cf70c55554351c64eb5112f80c3aca
    status: Needs Human
    audit_ids:
    - audit-e57dccbb6b4b
    applied: true
    created_at: '2026-07-31T21:16:04.249435+00:00'
    applied_at: '2026-07-31T21:16:06.345270+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-e57dccbb6b4b
    project_id: proj-c260b117
    task_id: EXOCOMP-99
    target_state: Archived
    request_state: superseded
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b0e62630a4b564120ae6c051dbfd737340cf70c55554351c64eb5112f80c3aca
    attempts:
    - version: 1
      attempt_id: attempt-829671ba824e
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: b0e62630a4b564120ae6c051dbfd737340cf70c55554351c64eb5112f80c3aca
      created_at: '2026-07-31T21:13:18.056898+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-31T21:13:18.056898+00:00'
      branch_key: epic-EXOCOMP-2
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T21:13:23.574891+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T21:13:33.574866+00:00'
    - version: 1
      attempt_id: attempt-eff0481df7d6
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: b0e62630a4b564120ae6c051dbfd737340cf70c55554351c64eb5112f80c3aca
      created_at: '2026-07-31T21:14:07.576065+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-07-31T21:14:07.576065+00:00'
      branch_key: epic-EXOCOMP-2
      candidate_rotation_count: 1
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T21:14:12.777177+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T21:14:32.777151+00:00'
    - version: 1
      attempt_id: attempt-af1aa72f4c87
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: b0e62630a4b564120ae6c051dbfd737340cf70c55554351c64eb5112f80c3aca
      created_at: '2026-07-31T21:14:40.929518+00:00'
      provider_id: prov-651d553c
      model: haiku
      started_at: '2026-07-31T21:14:40.929518+00:00'
      branch_key: epic-EXOCOMP-2
      candidate_rotation_count: 2
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T21:14:45.759752+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T21:15:25.759725+00:00'
    - version: 1
      attempt_id: no-auditor-audit-e57dccbb6b4b-3
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: b0e62630a4b564120ae6c051dbfd737340cf70c55554351c64eb5112f80c3aca
      verdict: fail
      failure_classification: no_auditor
      created_at: '2026-07-31T21:16:04.249253+00:00'
      completed_at: '2026-07-31T21:16:04.249253+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-31T20:47:08.256317+00:00'
    updated_at: '2026-08-01T01:43:59.686471+00:00'
  - version: 1
    audit_id: audit-702a5e4f4441
    project_id: proj-c260b117
    task_id: EXOCOMP-99
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b0e62630a4b564120ae6c051dbfd737340cf70c55554351c64eb5112f80c3aca
    attempts: []
    requested_by:
      version: 1
      identity: oompah-cli
      source: api
    previous_state: Merged
    created_at: '2026-08-01T01:43:59.686471+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-829671ba824e
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b0e62630a4b564120ae6c051dbfd737340cf70c55554351c64eb5112f80c3aca
    created_at: '2026-07-31T21:13:18.056898+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-31T21:13:18.056898+00:00'
    branch_key: epic-EXOCOMP-2
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T21:13:23.574891+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T21:13:33.574866+00:00'
  - version: 1
    attempt_id: attempt-eff0481df7d6
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b0e62630a4b564120ae6c051dbfd737340cf70c55554351c64eb5112f80c3aca
    created_at: '2026-07-31T21:14:07.576065+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-07-31T21:14:07.576065+00:00'
    branch_key: epic-EXOCOMP-2
    candidate_rotation_count: 1
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T21:14:12.777177+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T21:14:32.777151+00:00'
  - version: 1
    attempt_id: attempt-af1aa72f4c87
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b0e62630a4b564120ae6c051dbfd737340cf70c55554351c64eb5112f80c3aca
    created_at: '2026-07-31T21:14:40.929518+00:00'
    provider_id: prov-651d553c
    model: haiku
    started_at: '2026-07-31T21:14:40.929518+00:00'
    branch_key: epic-EXOCOMP-2
    candidate_rotation_count: 2
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T21:14:45.759752+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T21:15:25.759725+00:00'
---
## Summary

Implement the coordinator-side A2A 1.0 client boundary used only for diagnostic skills. Add send, task-status/result retrieval, and cancel operations with protocol version negotiation, mTLS node identity/address handling from the EXOCOMP-14/15 registry, per-request timeout behavior, and normalized transport/protocol errors. Keep remediation/executor paths impossible. Add focused unit tests with deterministic fake transports covering successful task creation, terminal results, timeout, malformed responses, and cancellation support/unsupported responses. Relevant design: plans/milestone-2-coordinator.md Coordinator Task Flow and A2A Interface. Start from a branch containing the completed EXOCOMP-14 and EXOCOMP-15 foundations.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 15:52
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 15:53
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 15:57
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 15:57
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 15:59
---
Understanding: Duplicate Investigator pass. I will search the full task tracker (done, open, in-progress, archived, merged) and repository code for any existing task that implements the coordinator-side outbound A2A 1.0 HTTP client used for sending diagnostic tasks to nodes — covering send, status/result retrieval, cancel, version negotiation, mTLS registry integration, per-request timeouts, and normalized error handling.
---
author: oompah
created: 2026-07-24 15:59
---
Discovery: No duplicate confirmed. Full search across all task states (done, open, in-progress, archived, merged) and codebase finds no existing implementation or task covering the coordinator-side outbound A2A 1.0 diagnostic client.

Closest candidates reviewed:
- EXOCOMP-89 (Done): NodeProber — mTLS identity verification and address adoption for health polling. Scope is health-check probing only; does not implement A2A protocol message send/status/cancel to dispatch diagnostic tasks.
- EXOCOMP-14 (Done): Coordinator inventory registry and audit scaffold — the registry foundation EXOCOMP-99 will read addresses from, but not the A2A client itself.
- EXOCOMP-15 (Done): DNS discovery and concurrent node polling — orchestrates health poll cycles, not diagnostic A2A task dispatch.
- EXOCOMP-78/81 (Merged): Authenticated A2A router and message endpoint wiring — these are the NODE-SIDE server, not the coordinator-side client.

No code in apps/exocomp_coordinator/ or apps/exocomp_node/ implements an outbound A2A client for diagnostic task dispatch. The apps/exocomp_coordinator/ directory currently contains only application.ex.

EXOCOMP-101 explicitly blocks on EXOCOMP-99 (fan-out orchestrator depends on this client adapter), confirming this is a unique, unimplemented feature.

Focus handoff: duplicate_detector

Outcome: No duplicate confirmed. EXOCOMP-99 is a distinct, unimplemented coordinator-side A2A client adapter for diagnostic skills. No repository files changed.

Evidence: Reviewed all task files in done, open, in-progress, archived, and merged buckets via git show on oompah/state/proj-c260b117. Searched codebase for A2A client/adapter patterns — none found in coordinator app. Reviewed plans/milestone-2-coordinator.md A2A Interface section confirming this is a distinct required boundary.

Relevant files/decisions:
- plans/milestone-2-coordinator.md (Coordinator Task Flow and A2A Interface sections define the scope)
- apps/exocomp_coordinator/lib/exocomp/coordinator/application.ex (empty; coordinator app awaiting implementation)
- apps/exocomp_core/lib/exocomp/a2a/ (shared A2A protocol types to use)
- apps/exocomp_node/lib/exocomp/node/a2a/ (codec reference for wire format)
- EXOCOMP-14 and EXOCOMP-15 branches (registry foundations to read node addresses from)

Remaining work/risks:
- Implement Exocomp.Coordinator.A2A.DiagnosticClient (or similar) in apps/exocomp_coordinator/
- HTTP+mTLS transport with node identity from registry (EXOCOMP-14/15)
- send/status/cancel operations per A2A 1.0
- Protocol version negotiation
- Per-request timeout behavior
- Normalized transport/protocol error types
- Guard to prevent remediation/executor paths
- Focused unit tests with fake transports (successful creation, terminal results, timeout, malformed responses, cancel support/unsupported)

Recommended next focus: feature
---
author: oompah
created: 2026-07-24 16:00
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 70, Tool calls: 57
- Tokens: 35 in / 8.1K out [8.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 1s
- Log: EXOCOMP-99__20260724T155702Z.jsonl
---
author: oompah
created: 2026-07-24 16:00
---
Agent completed successfully in 181s (8155 tokens)
---
author: oompah
created: 2026-07-24 16:00
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 16:00
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 16:00
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 16:00
---
Understanding: Implement the coordinator-only outbound A2A 1.0 diagnostic client boundary. I will reuse the EXOCOMP-14/15 registry identity/address model and shared/node A2A codecs, enforce diagnostic-only requests, normalize timeout/transport/protocol failures, cover send/status-result/cancel plus version negotiation with deterministic fake-transport tests, run the relevant Makefile quality gate, then commit and push.
---
author: oompah
created: 2026-07-24 16:04
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:04
---
Focus: Feature Developer
---
author: oompah
created: 2026-07-24 16:10
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:10
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 16:11
---
Understanding: I will complete the coordinator-only outbound A2A 1.0 diagnostic adapter on the current managed worktree, preserving the two existing untracked coordinator model files. The implementation will use registry node identity/address and TLS data, expose only diagnostic send/status/result/cancel operations, negotiate protocol 1.0, normalize timeout/transport/protocol errors, and add deterministic fake-transport unit coverage before formatting, testing, committing, pushing, and closing the task.
---
author: oompah
created: 2026-07-24 16:15
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 0, Tool calls: 26
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 4m 21s
- Log: EXOCOMP-99__20260724T161046Z.jsonl
---
author: oompah
created: 2026-07-24 16:15
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 16:15
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 16:17
---
Understanding: All implementation files are already present as untracked files in the working tree from prior agent runs. The coordinator-side A2A diagnostic client (DiagnosticClient, ClientError, Codec, HTTPTransport, Transport behaviour) and focused unit tests (DiagnosticClientTest with FakeTransport, HTTPTransportTest) are complete. My job is to verify they compile and pass, then commit+push and close.
---
author: oompah
created: 2026-07-24 16:17
---
Verification: make test passes — 103 coordinator tests (including new DiagnosticClientTest and HTTPTransportTest), 66 core tests, 55 bench tests, 201 node tests, 10 excluded. Both releases build and smoke-test clean. Format check also clean.
---
author: oompah
created: 2026-07-24 16:19
---
Implementation: Added the coordinator A2A diagnostic boundary with send/get-task/cancel, strict allowlisting of system/service diagnostics, registry-based verified address plus hostname/certificate identity context, A2A 1.0 headers/version checks, typed response decoding, normalized errors, and an injectable transport. Added an :httpc mTLS transport and deterministic tests for creation, terminal artifacts, timeouts, malformed responses, version errors, cancellation supported/unsupported, and remediation rejection. During final review I corrected the real transport to use the configured hostname for SNI while independently verifying the registry certificate identity, and normalized nested timeout reasons.
---
author: oompah
created: 2026-07-24 16:19
---
Implementation: Committed and pushed coordinator-side A2A 1.0 diagnostic client adapter (3 commits on EXOCOMP-99 branch):

1. Core implementation: DiagnosticClient (send/get_task/cancel with version negotiation, per-request timeouts, diagnostic-only guard), ClientError (normalized error struct), Codec (encode_diagnostic/decode_task with artifact parts), Transport behaviour, HTTPTransport (:httpc with mTLS), DiagnosticGoal and NodeOutcome structs. Updated mix.exs with :inets/:ssl/:public_key and jason dep.

2. Unit tests with FakeTransport: 11 tests covering successful task creation (registry identity wired through), terminal artifact results, timeout, malformed JSON/task, cancel supported/unsupported, version negotiation failure, response version mismatch, unknown/unverified nodes. Plus HTTPTransport mTLS credential validation test.

3. Format fix: HTTPTransport verify_fun identity verification (SPIFFE URIs via uri_id, DNS hostnames via dns_id) and broadened timeout_reason? detection formatted per mix format.

All quality gates pass: make lint (format-check + compile --warnings-as-errors), make test (103 coordinator + 425 total, 10 excluded, both releases build and smoke-test).
---
author: oompah
created: 2026-07-24 16:19
---
Implemented coordinator-side A2A 1.0 diagnostic client adapter with send/get_task/cancel, version negotiation, mTLS identity/address from registry, per-request timeouts, normalized ClientError, diagnostic-only guard, and focused unit tests with FakeTransport covering all required scenarios. All quality gates pass.
---
author: oompah
created: 2026-07-24 16:19
---
Verification: The repository quality run passed: make test completed with 103 coordinator tests (including the new diagnostic client/HTTP transport tests), 66 core tests, 55 bench tests, and 201 node tests; 10 integration tests were excluded as expected. Release build/smoke checks and formatting also passed. Final transport review commits are formatted, git show --check is clean, and local HEAD a336b20 exactly matches origin/EXOCOMP-99.
---
author: oompah
created: 2026-07-24 16:19
---
Run #2 [attempt=2, profile=standard, role=standard -> Claude/default]
- Turns: 0, Tool calls: 47
- Tokens: 71 in / 2.2K out [2.3K total]
- Cost: $0.0000
- Exit: terminated, Duration: 4m 34s
- Log: EXOCOMP-99__20260724T161524Z.jsonl
---
author: oompah
created: 2026-07-24 16:20
---
Completion: Delivered and pushed the coordinator diagnostic A2A 1.0 client on EXOCOMP-99 (HEAD a336b20). The client supports diagnostic send, task status/result retrieval, and cancellation; consumes mTLS-verified registry addresses and expected identity; negotiates/validates version 1.0; enforces request timeouts; normalizes transport/protocol failures; and makes remediation/executor dispatch impossible through an explicit two-skill allowlist. Focused fake-transport tests and the full Make quality gate pass.
---
author: oompah
created: 2026-07-24 16:20
---
Implemented and pushed the coordinator-only A2A 1.0 diagnostic client adapter with registry/mTLS identity handling, protocol negotiation, per-request timeouts, normalized errors, send/get/cancel operations, remediation exclusion, and focused passing tests.
---
author: oompah
created: 2026-07-31 20:47
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-07-31 21:13
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-07-31 21:13
---
Run #1 [attempt=1, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 4s
---
author: oompah
created: 2026-07-31 21:13
---
Auditor attempt ended: git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-07-31 21:14
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-07-31 21:14
---
Run #2 [attempt=2, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 4s
---
author: oompah
created: 2026-07-31 21:14
---
Auditor attempt ended: git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-07-31 21:14
---
Auditor dispatched (attempt #3, candidate: prov-651d553c/haiku)
---
author: oompah
created: 2026-07-31 21:14
---
Run #3 [attempt=3, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 3s
---
author: oompah
created: 2026-07-31 21:14
---
Auditor attempt ended: git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-07-31 21:16
---
Needs Human — Archived audit requires operator input.

No independent auditor candidate is available for this audit (Audit reached the maximum of 3 attempts.). Configure the `auditor` role with at least one healthy provider/model that is independent of the task contributors, then move the task back to Open to retry.
---
author: oompah
created: 2026-08-01 00:59
---
Direct operator recovery claimed at the project owner's request. This is a failed Archived audit caused by deleted historical branch checkout, not incomplete implementation. Keep Needs Human as a scheduler hold until OOMPAH-671 is deployed; I will rearm and oversee the existing archive audit without reopening implementation.
---
author: oompah
created: 2026-08-01 01:44
---
Terminal audit rearmed by project owner after recovery: Detached historical audit workspace recovery is deployed; retry the existing Archived audit without reopening implementation.
---
<!-- COMMENTS:END -->
