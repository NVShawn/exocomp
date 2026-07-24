---
id: EXOCOMP-99
type: feature
status: Done
priority: 1
title: Implement coordinator diagnostic A2A client adapter
parent: EXOCOMP-18
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T04:29:25.236002Z'
updated_at: '2026-07-24T16:19:43.961087Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: e8327ec2-3eea-4ba9-8a1c-df6d6ac3657d
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 35
  total_output_tokens: 8120
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 35
      output_tokens: 8120
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 35
    output_tokens: 8120
    cost_usd: 0.0
    recorded_at: '2026-07-24T16:00:00.910348+00:00'
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
<!-- COMMENTS:END -->
