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
labels: []
assignee: null
created_at: '2026-07-23T23:01:08.149641Z'
updated_at: '2026-07-24T00:50:53.020162Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 3705bb5c-b21b-4bb0-bb3b-28a64db6b480
oompah.work_branch: epic-EXOCOMP-2
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
<!-- COMMENTS:END -->
