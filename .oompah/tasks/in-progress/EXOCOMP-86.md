---
id: EXOCOMP-86
type: task
status: In Progress
priority: null
title: Define ApprovalToken struct and deterministic canonical encoding
parent: EXOCOMP-23
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T02:36:43.435381Z'
updated_at: '2026-07-24T02:38:42.333736Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 1101bb94-f3b0-4634-926f-2d4d52b67fd3
oompah.work_branch: epic-EXOCOMP-3
---
## Summary

### Goal
Define the canonical, versioned approval-token payload struct and its deterministic binary serialisation used to produce the signing input.

### Context
EXOCOMP-23 is the coordinator-side issuer of Ed25519-signed, task-bound approval tokens. This task covers only the data contract and serialisation; signing and policy enforcement are in the next child task.

The token must bind ten fields so that any modification invalidates the signature:
- \`schema_version\` — fixed string \`"1"\`
- \`nonce\` — 32 high-entropy random bytes, base64url-encoded
- \`task_id\` — A2A task identifier (string)
- \`correlation_id\` — correlation/trace identifier (string)
- \`node_id\` — target node identity (string)
- \`action_id\` — stable action identifier from the catalog (string)
- \`parameter_hash\` — SHA-256 hex digest of the canonical action parameters map
- \`evidence_hash\` — SHA-256 hex digest of the canonical evidence map
- \`issued_at\` — ISO 8601 UTC timestamp
- \`expires_at\` — ISO 8601 UTC timestamp (short-lived, typically 5 minutes)
- \`operator\` — approving operator identity string

### Implementation

1. Create \`apps/exocomp_coordinator/lib/exocomp/coordinator/safety/approval_token.ex\`
   - Define \`Exocomp.Coordinator.Safety.ApprovalToken\` struct with the 11 fields above
   - Add \`@enforce_keys\` for all fields
   - Add a \`@schema_version "1"\` module attribute

2. Implement \`canonical_encode/1\` in the same module:
   - Produce a deterministic binary that can be fed directly to \`:crypto.sign/5\`
   - Strategy: serialize fields in a fixed, documented order using a binary-safe format. Preferred approach: UTF-8 JSON with lexicographically-sorted keys (use \`Jason.encode!/1\` with \`sort_keys: true\`, which is available in the project). This is reproducible across BEAM restarts and language boundaries.
   - Alternative if Jason sort_keys is unavailable: manually build a keyword list in fixed key order and pass to Jason.

3. Implement hash helpers:
   - \`sha256_hex/1\` — returns lowercase hex SHA-256 of binary input
   - \`hash_params/1\` — encodes a \`%{String.t => term}\` map deterministically (sorted JSON) then returns \`sha256_hex/1\` of the result
   - \`hash_evidence/1\` — same as hash_params for evidence values

### Tests
File: \`apps/exocomp_coordinator/test/exocomp/coordinator/safety/approval_token_test.exs\`

- \`canonical_encode/1\` is byte-for-byte identical for identical inputs
- Two structs differing in any single field produce different canonical bytes
- \`hash_params/1\` and \`hash_evidence/1\` produce identical output regardless of map insertion order
- Schema version mismatch returns an error (add \`validate_schema_version/1\`)
- All 11 enforce_keys are required (missing any raises ArgumentError)

### No dependencies
This task has no upstream code dependency — all referenced modules are part of Elixir standard library and Jason. The implementation branch need not merge prerequisite branches before starting this task.

### Quality gate
\`make test\` (focused on exocomp_coordinator) and \`make lint\`.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:38
---
Agent dispatched (profile: default)
---
<!-- COMMENTS:END -->
