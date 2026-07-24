---
id: EXOCOMP-23
type: feature
status: Open
priority: 1
title: Implement signed task-bound approval issuance
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-16
- EXOCOMP-21
labels:
- focus-complete:duplicate_detector
- needs:feature
assignee: null
created_at: '2026-07-23T19:10:09.330640Z'
updated_at: '2026-07-24T02:30:55.820225Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: a24369b8-5e26-4588-a07e-2d4c1cc12528
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 18
  total_output_tokens: 4698
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 18
      output_tokens: 4698
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 18
    output_tokens: 4698
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:30:51.459414+00:00'
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Implement signed task-bound approval issuance.

Implementation
Implement canonical versioned approval payloads and Ed25519 signatures using the coordinator approval key; bind nonce, task/correlation, node, action, parameter hash, evidence hash, issue/expiry time, and operator identity; add coordinator-local approve/deny commands.

Testing
Test canonical encoding, signature verification vectors, tampering of every binding, expiry, operator audit, missing keys, and approval refusal for forbidden actions.

Acceptance Criteria
- [ ] Approval is short-lived and bound to exact current action/evidence.
- [ ] Changing any bound field invalidates the signature.
- [ ] Approval cannot authorize user-data deletion or unknown actions.
- [ ] Operator and issuance are audited without secrets.
- [ ] Focused crypto/command tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:28
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:29
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 02:30
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-23 is a unique task with no overlap in the existing task graph.

**Evidence reviewed:**

- **EXOCOMP-75** (Done, child of EXOCOMP-16): Implements coordinator PKI bootstrap including *generating* the Ed25519 approval-signing key and storing it securely. Scope is key/certificate creation and atomic protected persistence — not token issuance. EXOCOMP-23 *uses* the key created by EXOCOMP-75 to sign tokens.

- **EXOCOMP-76** (Done, child of EXOCOMP-16): Implements durable node-bound *enrollment* tokens (not approval tokens). Enrollment tokens authenticate new nodes joining the coordinator, using a digest-only store and high-entropy opaque values. Approval tokens (EXOCOMP-23) are Ed25519-signed and bind task/action/evidence/expiry — different protocol, different purpose, different key.

- **EXOCOMP-24** (Open, sibling): Verifies approval tokens and prevents replay — that is the *node-side* receiver. EXOCOMP-23 is the *coordinator-side* issuer. Complementary, not duplicate.

- **EXOCOMP-22** (Done): Deterministic least-impact policy selection — outputs deny/allow/approval_required decisions. EXOCOMP-23 turns an approval_required outcome + operator command into a signed token.

- **EXOCOMP-21** (Done): Action/evidence/risk/data-classification types — prerequisite type definitions consumed by EXOCOMP-23's payload encoding.

- No other task in the project issues Ed25519-signed canonical approval payloads binding nonce, task/correlation, node, action, parameter hash, evidence hash, issue/expiry time, and operator identity, or provides coordinator-local approve/deny CLI commands.

**Key files for feature agent:**
- `plans/milestone-3-safety-validation.md` — Approval Tokens section (canonical payload fields, Ed25519, single-use, replay prevention)
- `apps/exocomp_coordinator/lib/exocomp/coordinator/pki/` — PKI Bootstrap output including Ed25519 approval-signing key (from EXOCOMP-75)
- `apps/exocomp_coordinator/lib/exocomp/coordinator/` — supervisor, audit, inventory foundation
- `apps/exocomp_node/lib/exocomp/node/safety/` — ActionDefinition, Evidence, ValidatorResult types (from EXOCOMP-21)
- Branch `epic-EXOCOMP-3` contains EXOCOMP-21 and EXOCOMP-22 work; confirm it also includes EXOCOMP-75/EXOCOMP-76 from epic-EXOCOMP-16 via merge

**Remaining work and risks:**
1. Implement canonical versioned approval payload struct encoding (deterministic JSON or binary canonical form)
2. Ed25519 signing using the coordinator approval key from PKI online state
3. Bind: schema version, nonce (UUID/random), task ID, correlation ID, node ID, action ID, parameter hash (SHA-256), evidence hash (SHA-256), issued_at, expires_at (short-lived), operator identity
4. Coordinator-local `approve <task_id>` and `deny <task_id>` CLI/operator commands
5. Audit without secrets (log operator, issuance time, task/action — never the token or private key)
6. Forbid approval of user-data deletion actions or unknown actions at issuance time
7. Tests: canonical encoding vectors, signature verification, every binding tamper, expiry boundary, operator audit, missing/unavailable key, forbidden action refusal
8. Run make test, make lint, make fmt-check

**Risks:**
- EXOCOMP-75 implemented the Ed25519 key as a raw key file; need to verify the file format (raw binary vs PEM) and load/sign API in Erlang :crypto
- The branch must include both epic-EXOCOMP-3 (EXOCOMP-21/22 types) and epic-EXOCOMP-16 (EXOCOMP-75 PKI) — check if the branch has the PKI code or if it needs to be merged/rebased
- Canonical encoding: must be deterministic so signature verification is reproducible; JSON key ordering must be fixed or use a binary format

**Recommended next focus:** feature
---
author: oompah
created: 2026-07-24 02:30
---
Agent completed successfully in 113s (4716 tokens)
---
author: oompah
created: 2026-07-24 02:30
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 35, Tool calls: 24
- Tokens: 18 in / 4.7K out [4.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 53s
- Log: EXOCOMP-23__20260724T022901Z.jsonl
---
author: oompah
created: 2026-07-24 02:30
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
<!-- COMMENTS:END -->
