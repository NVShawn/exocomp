---
id: EXOCOMP-95
type: task
status: Backlog
priority: null
title: Implement node-side approval token verifier (signature, bindings, freshness)
parent: EXOCOMP-24
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T03:12:09.769791Z'
updated_at: '2026-07-24T03:12:09.769791Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

### Goal

Implement \`Exocomp.Node.Safety.ApprovalVerifier\` — the cryptographic and binding-validation layer for Ed25519-signed approval tokens on the node side.

### Context

EXOCOMP-86 (Done, branch \`EXOCOMP-86\`) delivered \`Exocomp.Coordinator.Safety.ApprovalToken\` with \`canonical_encode/1\`, \`sha256_hex/1\`, \`hash_params/1\`, and \`hash_evidence/1\`. That module lives in \`apps/exocomp_coordinator/\`.

The node side needs a corresponding verifier. The verifier is the first gate before any execution can proceed.

### Implementation

Create \`apps/exocomp_node/lib/exocomp/node/safety/approval_verifier.ex\` containing \`Exocomp.Node.Safety.ApprovalVerifier\`.

### Coordinator public key provisioning

The node needs the coordinator's Ed25519 **public** key (32 bytes) to verify signatures. Design and implement one of these approaches (choose and document the decision):

- **Config-path approach**: the operator places the coordinator's Ed25519 public key in a configured file path (e.g. \`/etc/exocomp/coordinator_approval_public.key\`); the verifier loads it at startup or lazily.
- **Enrollment-distributed approach**: during enrollment (EXOCOMP-17/EXOCOMP-87), the coordinator sends its Ed25519 approval public key alongside the certificate chain; the node stores it in its identity directory.

Either approach must: (a) load the key from a configurable path; (b) return a clear error if the key file is absent or malformed; (c) never log or expose the raw key bytes in error messages; (d) be injectable for tests via Application config.

Also consider whether the approval public key should be verified against the coordinator's certificate chain for additional authenticity. Document your decision in the module's \`@moduledoc\`.

### Signature verification

Use \`:crypto.verify(:eddsa, :none, canonical_bytes, signature, [pub_key, :ed25519])\` where \`canonical_bytes\` is produced by \`ApprovalToken.canonical_encode/1\` (or a node-local copy of the same encoding logic if coordinator module is not a dependency of exocomp_node).

**Important**: To avoid a cross-app dependency on \`exocomp_coordinator\`, consider copying or extracting the \`canonical_encode/1\` logic into a shared module (e.g. \`apps/exocomp_core/lib/exocomp/core/approval_token.ex\`) or duplicating only the encoding in the node. Document the decision.

### Binding verification

Verify all 11 token fields against the execution context provided by the caller:

| Token field | Check against |
|-------------|---------------|
| \`schema_version\` | module constant \`"1"\` |
| \`nonce\` | must be present and non-empty (uniqueness checked by ReplayLedger) |
| \`node_id\` | this node's configured identity (from enrollment/config) |
| \`task_id\` | caller-provided task ID |
| \`correlation_id\` | caller-provided correlation ID |
| \`action_id\` | atom-to-string mapping of the requested action |
| \`parameter_hash\` | \`ApprovalToken.hash_params/1\` of the actual parameter map |
| \`evidence_hash\` | stored for later use by PreconditionChecker (not checked here) |
| \`issued_at\` | parse and verify \`issued_at <= now\` |
| \`expires_at\` | parse and verify \`expires_at > now\` (strict — no clock skew grace) |
| \`operator\` | must be non-empty |

Return \`{:ok, token}\` on all checks passing, or \`{:error, {:binding_mismatch, field, expected, actual}}\` / \`{:error, :expired}\` / \`{:error, :not_yet_valid}\` / \`{:error, :invalid_signature}\` / \`{:error, :public_key_unavailable}\` as appropriate.

### Token format

The token arrives as a map or struct containing a \`signature\` field (binary or base64-encoded) plus the 11 payload fields. Define and document the wire format (e.g. a map with \`"payload"\` sub-map and \`"signature"\` base64url string).

### Tests

File: \`apps/exocomp_node/test/exocomp/node/safety/approval_verifier_test.exs\`

Cover:
- Valid token passes all checks
- Signature verified with correct key
- Invalid signature rejected (bit-flipped signature)
- Wrong public key rejected
- Absent public key file returns \`{:error, :public_key_unavailable}\`
- Each of the 11 fields tampered individually → binding mismatch error naming the correct field
- Expired token (expires_at in the past) → \`{:error, :expired}\`
- Not-yet-valid token (issued_at in the future) → \`{:error, :not_yet_valid}\`
- Wrong node_id rejected
- Wrong action_id rejected
- Wrong parameter_hash rejected (different parameters)
- Correct token with correct node / action / parameters passes

### Prerequisites

Merge \`origin/EXOCOMP-86\` (ApprovalToken struct) onto this branch, or extract canonical_encode logic to exocomp_core as a shared module.

### Quality gate

Run \`make test\` and \`make lint\` before closing.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

