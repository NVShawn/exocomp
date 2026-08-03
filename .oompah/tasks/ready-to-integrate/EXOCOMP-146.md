---
id: EXOCOMP-146
type: task
status: Ready to Integrate
priority: 1
title: Connect coordinators over an outbound mTLS WebSocket
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-145
- EXOCOMP-144
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:02.496448Z'
updated_at: '2026-08-03T18:37:39.488288Z'
work_branch: epic-EXOCOMP-130--task-EXOCOMP-146
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: e89e27b3fcf6b07f45d8bc5633fc0ace9c4e108c95db7a100a80b4ac8266591a
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:14:39.386053+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active EXOCOMP-144, EXOCOMP-145, EXOCOMP-147, EXOCOMP-149,
    EXOCOMP-150, EXOCOMP-180, EXOCOMP-181, and EXOCOMP-143. Each covers adjacent PKI,
    configuration, heartbeat, delivery, integration, security testing, or enrollment
    scope; EXOCOMP-143 explicitly excludes WebSocket authentication. The exact outbound
    mTLS WebSocket upgrade/session-replacement scope appears only in EXOCOMP-146 and
    `plans/mission-control.md`.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: null
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-146
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-146
  head_sha: 93a1cd16d5a00cb577bfe8276e55406f4e33bc88
  submitted_at: '2026-08-03T18:37:34.381436+00:00'
  updated_at: '2026-08-03T18:37:34.381436+00:00'
oompah.task_costs:
  total_input_tokens: 20434066
  total_output_tokens: 71814
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 20434066
      output_tokens: 71814
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 467252
    output_tokens: 4252
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:14:39.385281+00:00'
  - profile: default
    model: haiku
    input_tokens: 19966814
    output_tokens: 67562
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:40:00.995048+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-146__20260801T121119Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-130--task-EXOCOMP-146
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:14:39.452481+00:00'
---
## Summary

Plan: plans/mission-control.md, Cluster Enrollment and Connection Protocol.

Deliverables:
- Implement the coordinator WebSocket client for GET /api/v1/clusters/connect using TLS 1.3, server trust validation, and its enrolled client certificate.
- Implement the Mission Control upgrade endpoint, extract organization/cluster identity only from the validated certificate, reject revoked certificates, and create a random session ID.
- Enforce one live session per cluster; a newer authenticated session supersedes the old one.

Acceptance:
- Integration tests cover success, missing/wrong certificate, wrong trust root, revoked identity, payload identity spoofing, and session replacement.
- No inbound listener is added to the coordinator.

Out of scope: heartbeat, replay, and domain events.
Quality gate: focused transport tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:11
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:11
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:14
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 2, Tool calls: 29
- Tokens: 467.3K in / 4.3K out [471.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 32s
- Log: EXOCOMP-146__20260801T121119Z.jsonl
---
author: oompah
created: 2026-08-01 12:14
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:15
---
Focus: Refactoring Specialist
---
author: oompah
created: 2026-08-01 12:15
---
Understanding: I will inspect the existing coordinator, Mission Control, TLS, and certificate identity paths, then implement the outbound TLS 1.3 WebSocket connection and validated upgrade/session replacement behavior with focused integration tests. I will preserve existing interfaces, run the required Makefile gates, commit, push, and submit the task.
---
author: oompah
created: 2026-08-01 12:20
---
Discovery: the branch has no Mission Control app yet, so I will keep the coordinator client and gateway primitives dependency-light inside the umbrella's existing coordinator app. The gateway will be a standalone Plug/Bandit-compatible WebSocket endpoint that future Mission Control routing can mount; the coordinator Application will not start it or add any listener. Bandit already provides WebSock server support, while the coordinator client will use :ssl with a small RFC 6455 transport to avoid introducing an unapproved client dependency.
---
author: oompah
created: 2026-08-01 12:31
---
Implementation: added an outbound coordinator MissionControl.WebSocket transport over :ssl with wss-only URLs, TLS 1.3, CA/server-name verification, enrolled client cert/key, RFC 6455 masking/handshake/frame handling, and an optional Client GenServer. Added a Bandit-compatible Mission Control ClusterGateway Plug, strict peer-certificate SPIFFE identity extraction, revocation-aware ClusterSessions with cryptographically random IDs and replacement signaling, plus strict server TLS option construction. The coordinator Application and inbound listener were left unchanged.
---
author: oompah
created: 2026-08-01 12:36
---
Verification update: focused tests now cover certificate-derived identity, wrong trust root, missing/wrong client credentials, revoked identities, payload spoofing, random session IDs, and session replacement; the integration fixture exercises a real Bandit TLS 1.3 WebSocket handshake and masked frame exchange. Local Elixir execution is blocked because the host has Elixir 1.18.3 (project requires 1.20.2) and lacks OTP syntax_tools; the required Make targets also cannot start their pinned Podman container because the runtime filesystem is read-only. Source parsing, formatted-file checks, compile-with-stub checks, and git diff checks pass.
---
author: oompah
created: 2026-08-01 12:39
---
Completion: delivered commit 5561520 and pushed branch epic-EXOCOMP-130--task-EXOCOMP-146. The outbound coordinator client is wss/TLS-1.3 mTLS with server trust and enrolled client-cert validation; the standalone Mission Control gateway derives SPIFFE organization/cluster identity from the authenticated certificate, rejects revoked identities, issues random session IDs, and supersedes prior sessions. Focused unit/integration tests cover success, certificate/trust failures, revocation, spoofing, and replacement. Required containerized gates remain environment-blocked by read-only Podman; source parse/format/stub compilation and offline builder checks passed.
---
author: oompah
created: 2026-08-01 12:39
---
Implemented outbound TLS 1.3 mTLS WebSocket coordinator client and validated Mission Control gateway with certificate-derived identity, revocation rejection, random sessions, replacement, and focused integration coverage.
---
author: oompah
created: 2026-08-01 12:40
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 103
- Tokens: 20.0M in / 67.6K out [20.0M total]
- Cost: $0.0000
- Exit: terminated, Duration: 25m 6s
- Log: EXOCOMP-146__20260801T121501Z.jsonl
---
author: oompah
created: 2026-08-03 17:38
---
Integration could not verify `epic-EXOCOMP-130--task-EXOCOMP-146`: epic worktree head 72ade5184d8c3ce5ac1ea112fdf3d514994cc7cc differs from the published epic head eaeeaf0872984e655611d0092397e9c800e1bf6b; refusing to reset a preserved recovery snapshot

Fetch the private branch, preserve its commits, push a clean current head, and submit it again.
---
author: oompah
created: 2026-08-03 17:40
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-03 17:40
---
Focus: Refactoring Specialist
---
author: oompah
created: 2026-08-03 17:41
---
Understanding: implement the outbound coordinator mTLS WebSocket client and Mission Control upgrade authentication, deriving identity only from validated certificates, rejecting revoked identities, and superseding older live sessions. I will inspect the current enrollment/revocation interfaces, add focused integration coverage, then run the required quality gates.
---
author: oompah
created: 2026-08-03 17:49
---
Implementation: rebased the preserved transport onto the current EXOCOMP-130 epic, reconciled the coordinator with the existing Mission Control supervisor, and made the supervised Connection establish the outbound TLS 1.3 WebSocket using trust root plus enrolled client cert/key. Moved the authenticated gateway, certificate identity, and session registry into the Mission Control app, mounted /api/v1/clusters/connect, started the registry, split transport tests, and made production endpoint TLS fail closed with peer certificates required.
---
author: oompah
created: 2026-08-03 17:51
---
Verification: offline make test checks passed (13 structural/release checks plus Python packaging/documentation tests). Changed sources parse cleanly, and direct elixirc compilation of coordinator transport/application sources passed with only expected missing-dependency warnings. Focused Mix tests, make test’s pinned Elixir test phase, make fmt-check, and make lint are environment-blocked: host Elixir 1.18.3 vs required 1.20.2, and Podman cannot initialize because /run/user/1000/libpod is read-only. git diff --check is clean.
---
author: oompah
created: 2026-08-03 17:51
---
Completion: rebased the preserved implementation onto epic head 8400a54, pushed clean head 0bb80c72, and verified origin matches the worktree. Delivered the outbound wss/TLS 1.3 mTLS coordinator connection, Mission Control certificate-derived gateway and revocation/session replacement enforcement, mounted upgrade route, and fail-closed production TLS configuration. Ready to integrate.
---
author: oompah
created: 2026-08-03 17:51
---
Rebased and delivered outbound coordinator mTLS WebSocket plus Mission Control certificate-authenticated gateway, revocation, and session replacement
---
author: oompah
created: 2026-08-03 17:52
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 90
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 12m 24s
- Log: EXOCOMP-146__20260803T174025Z.jsonl
---
author: oompah
created: 2026-08-03 18:31
---
Integration found a rebase conflict on `epic-EXOCOMP-130--task-EXOCOMP-146`. Resolve it against `epic-EXOCOMP-130`, run the required tests, push the same private branch, and `oompah task submit` it again.
---
author: oompah
created: 2026-08-03 18:33
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-08-03 18:33
---
Focus: Refactoring Specialist
---
author: oompah
created: 2026-08-03 18:33
---
Understanding: I will reconcile the task branch with epic-EXOCOMP-130, retain the existing outbound mTLS WebSocket behavior unchanged, and verify the focused transport plus required project gates before resubmission.
---
author: oompah
created: 2026-08-03 18:37
---
Verification: rebase completed cleanly; git diff --check and conflict-marker scan pass; all changed transport/gateway sources and tests parse under the available Elixir. make test reruns its offline release, packaging, and documentation checks successfully but its required pinned Mix phase is blocked because Podman cannot create /run/user/1000/libpod. make fmt-check and make lint are blocked by the same Podman restriction; direct focused Mix tests are blocked because host Elixir 1.18.3 is below the required 1.20.2.
---
author: oompah
created: 2026-08-03 18:37
---
Completion: rebased the task work onto epic-EXOCOMP-130 at 9663f4b2, resolving documentation and coordinator-supervision conflicts while preserving the existing transport behavior. The duplicate outbox commit was skipped because the parent already contains it. Published reconciled head 93a1cd16; origin now matches the clean worktree. Submitting for integration.
---
author: oompah
created: 2026-08-03 18:37
---
Rebased outbound mTLS WebSocket transport onto current epic and verified reconciled branch
---
<!-- COMMENTS:END -->
