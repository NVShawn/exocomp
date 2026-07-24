---
id: EXOCOMP-75
type: feature
status: In Progress
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
updated_at: '2026-07-24T00:53:55.550013Z'
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
<!-- COMMENTS:END -->
