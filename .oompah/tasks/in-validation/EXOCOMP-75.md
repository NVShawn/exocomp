---
id: EXOCOMP-75
type: feature
status: In Validation
priority: 1
title: Implement secure coordinator PKI bootstrap and state validation
parent: EXOCOMP-16
children: []
blocked_by:
- EXOCOMP-14
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T23:01:08.149641Z'
updated_at: '2026-07-31T21:12:45.788310Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: e502ec22-c6c8-4484-9b9f-7e60f0ce708d
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 18
  total_output_tokens: 4017
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 18
      output_tokens: 4017
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 18
    output_tokens: 4017
    cost_usd: 0.0
    recorded_at: '2026-07-24T00:52:39.021232+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    no-auditor-audit-09b89e576d5e-3: '2026-07-31T21:12:45.248960+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-75
    target_state: Archived
    evidence_fingerprint: 898363c6b8d2571f058db8da29c53e71a60b5d6bd91d1296a402b03d2f48859c
    audit_ids:
    - audit-09b89e576d5e
    kind: result
    applied: true
    retired_at: '2026-07-31T21:12:45.248972+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-75
    audit_id: audit-09b89e576d5e
    attempt_id: no-auditor-audit-09b89e576d5e-3
    target_state: Archived
    evidence_fingerprint: 898363c6b8d2571f058db8da29c53e71a60b5d6bd91d1296a402b03d2f48859c
    status: Needs Human
    audit_ids:
    - audit-09b89e576d5e
    applied: false
    created_at: '2026-07-31T21:12:45.248988+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-09b89e576d5e
    project_id: proj-c260b117
    task_id: EXOCOMP-75
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 898363c6b8d2571f058db8da29c53e71a60b5d6bd91d1296a402b03d2f48859c
    attempts:
    - version: 1
      attempt_id: attempt-2313c5c61c6a
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 898363c6b8d2571f058db8da29c53e71a60b5d6bd91d1296a402b03d2f48859c
      created_at: '2026-07-31T21:10:26.910309+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-31T21:10:26.910309+00:00'
      branch_key: epic-EXOCOMP-2
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T21:10:32.135039+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T21:10:42.135015+00:00'
    - version: 1
      attempt_id: attempt-7887729ea808
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 898363c6b8d2571f058db8da29c53e71a60b5d6bd91d1296a402b03d2f48859c
      created_at: '2026-07-31T21:11:02.607809+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-07-31T21:11:02.607809+00:00'
      branch_key: epic-EXOCOMP-2
      candidate_rotation_count: 1
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T21:11:07.736884+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T21:11:27.736860+00:00'
    - version: 1
      attempt_id: attempt-accbb1439ea1
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 898363c6b8d2571f058db8da29c53e71a60b5d6bd91d1296a402b03d2f48859c
      created_at: '2026-07-31T21:11:43.825361+00:00'
      provider_id: prov-651d553c
      model: haiku
      started_at: '2026-07-31T21:11:43.825361+00:00'
      branch_key: epic-EXOCOMP-2
      candidate_rotation_count: 2
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T21:11:50.226676+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T21:12:30.226649+00:00'
    - version: 1
      attempt_id: no-auditor-audit-09b89e576d5e-3
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 898363c6b8d2571f058db8da29c53e71a60b5d6bd91d1296a402b03d2f48859c
      verdict: fail
      failure_classification: no_auditor
      created_at: '2026-07-31T21:12:45.248815+00:00'
      completed_at: '2026-07-31T21:12:45.248815+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-31T20:46:51.226099+00:00'
    updated_at: '2026-07-31T21:12:45.248815+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-2313c5c61c6a
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 898363c6b8d2571f058db8da29c53e71a60b5d6bd91d1296a402b03d2f48859c
    created_at: '2026-07-31T21:10:26.910309+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-31T21:10:26.910309+00:00'
    branch_key: epic-EXOCOMP-2
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T21:10:32.135039+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T21:10:42.135015+00:00'
  - version: 1
    attempt_id: attempt-7887729ea808
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 898363c6b8d2571f058db8da29c53e71a60b5d6bd91d1296a402b03d2f48859c
    created_at: '2026-07-31T21:11:02.607809+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-07-31T21:11:02.607809+00:00'
    branch_key: epic-EXOCOMP-2
    candidate_rotation_count: 1
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T21:11:07.736884+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T21:11:27.736860+00:00'
  - version: 1
    attempt_id: attempt-accbb1439ea1
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 898363c6b8d2571f058db8da29c53e71a60b5d6bd91d1296a402b03d2f48859c
    created_at: '2026-07-31T21:11:43.825361+00:00'
    provider_id: prov-651d553c
    model: haiku
    started_at: '2026-07-31T21:11:43.825361+00:00'
    branch_key: epic-EXOCOMP-2
    candidate_rotation_count: 2
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T21:11:50.226676+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T21:12:30.226649+00:00'
---
## Summary

Implement the cryptographic and storage foundation described in plans/milestone-2-coordinator.md Bootstrap PKI. Base the work on the coordinator scaffold from EXOCOMP-14. Add a coordinator-local initialization API that accepts explicit online-state and offline-backup destinations plus a non-logging root-key protection input. Generate a long-lived root CA, export its certificate and protected private key only to the explicit backup destination, generate an online intermediate CA, issue the initial coordinator leaf identity, and generate a separate Ed25519 approval-signing key that is never reused for CA or enrollment-token signing. Persist all online material atomically with restrictive directory and private-file modes; online state must contain the root certificate but never the root private key. On repeat initialization, validate the complete certificate chain, key/certificate correspondence, key roles, paths, and permissions and return the existing fingerprint without rotating material. Missing, partial, corrupt, mismatched, or insecure state must fail closed with actionable errors and must not silently regenerate. Return explicit backup-path and root-fingerprint metadata without exposing secrets. Add focused tests for valid chain separation, root absence from online state, protected backup output, distinct approval key, idempotency, secure modes, partial/corrupt material, atomic failure cleanup, and redacted errors/logs. Use existing Make targets for format, test, and lint. Relevant files: apps/exocomp_coordinator/lib/exocomp/coordinator/pki/*, application/config integration points, apps/exocomp_coordinator/mix.exs, and coordinator tests. Acceptance: valid separated root/intermediate/leaf material; no root private key in online state; private material protected and permission-checked; repeated init is stable; invalid state fails closed; focused tests pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 00:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 00:50
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 00:50
---
Understanding: I am investigating EXOCOMP-75 as a Duplicate Investigator. The issue requests implementing secure coordinator PKI bootstrap and state validation — including root CA generation, intermediate CA, leaf identity, approval-signing key (Ed25519), atomic persistence with restrictive permissions, idempotent re-initialization with chain validation, and focused tests. Before any implementation, I need to search for existing tasks covering the same ground.
---
author: oompah
created: 2026-07-24 00:50
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 00:50
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 00:51
---
Understanding: I am the Duplicate Investigator for EXOCOMP-75. The issue requests implementing secure coordinator PKI bootstrap and state validation — root CA generation, intermediate CA, coordinator leaf identity, Ed25519 approval-signing key, atomic persistence with restrictive permissions, idempotent re-initialization with chain validation, and focused tests. I will search for existing tasks covering this same ground before any implementation.
---
author: oompah
created: 2026-07-24 00:52
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-75 is a unique, intentionally-created child task with no overlap with any other existing task.

**Evidence reviewed:**
- EXOCOMP-16 (parent, Open): 'Implement coordinator CA initialization and enrollment tokens' — EXOCOMP-75 was explicitly created as a child by the EXOCOMP-16 Epic Planner (comment #19-23 in EXOCOMP-16's history). The scope is different from the parent — EXOCOMP-75 covers only PKI bootstrap/state validation, not enrollment tokens or integration.
- EXOCOMP-14 (Done): 'Scaffold coordinator inventory, registry, audit' — covers OTP supervisor tree, inventory parser, ETS registry, audit sink. Zero PKI/certificate content. This is the blocker for EXOCOMP-75, not a duplicate.
- EXOCOMP-76 (Open, sibling): 'Implement durable node-bound enrollment token service' — enrollment tokens only, not PKI bootstrap. Complementary, not duplicate.
- EXOCOMP-77 (Open, sibling): 'Integrate coordinator PKI initialization and enrollment operations' — OTP/operator wiring and end-to-end verification. Depends on EXOCOMP-75.
- EXOCOMP-17 (Open): Node enrollment/renewal — node-side process consuming tokens issued by EXOCOMP-76, not coordinator PKI bootstrap.
- Searched plans/milestone-2-coordinator.md — Bootstrap PKI section defines root/intermediate/leaf/approval-key split that maps exclusively to EXOCOMP-75's scope.

**Relevant files for feature agent:**
- plans/milestone-2-coordinator.md — Bootstrap PKI section (root/intermediate/leaf/approval-signing key design, permission requirements, idempotency behavior)
- apps/exocomp_coordinator/lib/exocomp/coordinator/ — existing coordinator modules from EXOCOMP-14 (Inventory, Registry, Audit, Health, Application)
- apps/exocomp_coordinator/mix.exs — add PKI deps (Erlang :public_key or x509 hex package)
- apps/exocomp_coordinator/test/ — existing test patterns to follow
- Branch EXOCOMP-75 is based on EXOCOMP-14 work; confirm EXOCOMP-14 is merged or rebase if needed

**Remaining work (for feature agent):**
1. Add PKI dependency to apps/exocomp_coordinator/mix.exs (Erlang :public_key stdlib for X.509 + Ed25519 via :crypto)
2. Implement Exocomp.Coordinator.PKI.Bootstrap module: generate root CA (long-lived), export cert+protected private key to explicit offline backup destination, generate online intermediate CA, issue coordinator leaf cert, generate separate Ed25519 approval-signing key
3. Implement atomic persistence with restrictive dir/file modes (0700 dir, 0600 key files)
4. Implement idempotent re-init: on repeat call, validate full chain, key/cert correspondence, key roles, paths, permissions; return existing fingerprint without rotating material
5. Fail closed on missing/partial/corrupt/mismatched/insecure state — never silently regenerate
6. Return backup-path and root-fingerprint metadata (no secrets)
7. Tests: valid chain separation, root key absent from online state, protected backup output, distinct approval key purpose, idempotency, secure modes, partial/corrupt material, atomic failure cleanup, redacted errors/logs
8. Run make test && make lint && make fmt-check

**Risks:**
- EXOCOMP-14 is Done on branch EXOCOMP-14 but may not be on main; the feature agent should check git log and rebase/merge as needed
- Erlang :public_key API for X.509 cert generation is low-level; the x509 hex package provides a friendlier interface — consider adding as a dependency
- Ed25519 for approval-signing: Erlang :crypto OTP 22+ supports Ed25519 via :crypto.generate_key(:eddh, :ed25519) — verify OTP version in .tool-versions
- Protected private key for offline backup: must use passphrase-based PEM encryption (PKCS#8 EncryptedPrivateKeyInfo), not plaintext PEM
- The feature agent must not log or return the root private key or passphrase at any point

**Recommended next focus:** feature
---
author: oompah
created: 2026-07-24 00:52
---
Agent completed successfully in 108s (4035 tokens)
---
author: oompah
created: 2026-07-24 00:52
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 23, Tool calls: 15
- Tokens: 18 in / 4.0K out [4.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 48s
- Log: EXOCOMP-75__20260724T005053Z.jsonl
---
author: oompah
created: 2026-07-24 00:52
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 00:52
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 00:52
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 00:52
---
Understanding: Implement coordinator-local secure PKI bootstrap with explicit online/offline destinations and non-logging root protection input; generate separated root/intermediate/leaf and Ed25519 approval keys, persist atomically with strict modes, validate existing state without rotation, fail closed on invalid state, and cover all security/idempotency cases with focused tests before running Make quality gates.
---
author: oompah
created: 2026-07-24 00:53
---
Discovery: Coordinator PKI does not yet exist. The worktree was incorrectly on epic-EXOCOMP-16; created EXOCOMP-75 from current main and cherry-picked the completed EXOCOMP-14 scaffold. Design will stage sibling directories and atomically rename complete online/offline trees, with a versioned manifest binding canonical paths and fingerprint; repeat init validates both trees, modes, certificate roles/signatures/key matches, encrypted root backup, and Ed25519 approval-key separation before returning metadata.
---
author: oompah
created: 2026-07-24 01:02
---
Implementation: Added Exocomp.Coordinator.PKI.Bootstrap and x509/public_key dependencies. The API requires absolute separate destinations plus {:passphrase, value}; creates P-384 root/intermediate CAs, P-256 30-day coordinator TLS identity, and separate raw Ed25519 approval key; writes versioned path/role manifests through protected sibling staging directories and atomic renames. Repeat calls validate exact trees/modes, manifests, encrypted backup root key, key/cert matches, CA/key usages, RFC 5280 path/signatures/validity, approval signing capability, and fingerprint. Invalid state returns redacted structured errors without rotation.
---
author: oompah
created: 2026-07-24 01:04
---
Verification: focused PKI suite passes 10/10; full coordinator suite passes 25/25; make lint, make fmt-check, and make build (including both production releases) pass. make test reaches 129 passing tests overall but fails 2 pre-existing node LlamaServer crash tests because they hard-code /usr/bin/kill, absent in the pinned Alpine builder; filed EXOCOMP-83 for that unrelated portability defect. No PKI/coordinator failures.
---
author: oompah
created: 2026-07-24 01:04
---
Completion: Delivered and pushed commit 7ceead4 on EXOCOMP-75. Coordinator initialization now securely bootstraps separated CA/leaf/approval material, keeps the protected root key offline, atomically persists strict-mode state, returns only path/fingerprint metadata, and performs comprehensive fail-closed repeat validation. Added 10 focused security/idempotency/storage tests and dependency/release integration. Quality evidence: focused 10/10, coordinator 25/25, lint/fmt/build pass; unrelated full-suite Alpine kill-path defect tracked as EXOCOMP-83.
---
author: oompah
created: 2026-07-24 01:05
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 0, Tool calls: 39
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 12m 22s
- Log: EXOCOMP-75__20260724T005247Z.jsonl
---
author: oompah
created: 2026-07-24 01:05
---
Implemented secure coordinator PKI bootstrap, atomic protected storage, comprehensive existing-state validation, and focused tests; pushed commit 7ceead4.
---
author: oompah
created: 2026-07-31 20:46
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-07-31 21:10
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-07-31 21:10
---
Run #1 [attempt=1, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 4s
---
author: oompah
created: 2026-07-31 21:10
---
Auditor attempt ended: git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-07-31 21:11
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-07-31 21:11
---
Run #2 [attempt=2, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 3s
---
author: oompah
created: 2026-07-31 21:11
---
Auditor attempt ended: git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-07-31 21:11
---
Auditor dispatched (attempt #3, candidate: prov-651d553c/haiku)
---
author: oompah
created: 2026-07-31 21:11
---
Run #3 [attempt=3, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 3s
---
author: oompah
created: 2026-07-31 21:11
---
Auditor attempt ended: git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2. A different independent auditor will be tried on the next scheduler tick.
---
<!-- COMMENTS:END -->
