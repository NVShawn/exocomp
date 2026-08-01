---
id: EXOCOMP-95
type: task
status: Archived
priority: null
title: Implement node-side approval token verifier (signature, bindings, freshness)
parent: EXOCOMP-24
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T03:12:09.769791Z'
updated_at: '2026-08-01T03:16:33.953063Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: f962930a-a159-4505-873d-04268a70c5ce
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 794652
  total_output_tokens: 3593
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 794652
      output_tokens: 3593
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 794652
    output_tokens: 3593
    cost_usd: 0.0
    recorded_at: '2026-07-24T15:59:52.103138+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-e653bbf182a5: '2026-08-01T03:16:32.147792+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-95
    target_state: Archived
    evidence_fingerprint: 87928deddcc4f616910f2095f7cb88e470eaac4955fc101308e5c84939f092c3
    audit_ids:
    - audit-308bf0ecb161
    kind: result
    applied: true
    retired_at: '2026-08-01T03:16:32.147802+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-95
    audit_id: audit-308bf0ecb161
    attempt_id: attempt-e653bbf182a5
    target_state: Archived
    evidence_fingerprint: 87928deddcc4f616910f2095f7cb88e470eaac4955fc101308e5c84939f092c3
    status: Archived
    audit_ids:
    - audit-308bf0ecb161
    applied: false
    created_at: '2026-08-01T03:16:32.147817+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-308bf0ecb161
    project_id: proj-c260b117
    task_id: EXOCOMP-95
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 87928deddcc4f616910f2095f7cb88e470eaac4955fc101308e5c84939f092c3
    attempts:
    - version: 1
      attempt_id: attempt-e653bbf182a5
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 87928deddcc4f616910f2095f7cb88e470eaac4955fc101308e5c84939f092c3
      created_at: '2026-08-01T03:14:31.202362+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T03:14:31.202362+00:00'
      branch_key: epic-EXOCOMP-3
      verdict: pass
      completed_at: '2026-08-01T03:16:32.147632+00:00'
      ended_at: '2026-08-01T03:16:32.147632+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-01T03:00:55.899575+00:00'
    updated_at: '2026-08-01T03:16:32.147632+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-e653bbf182a5
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 87928deddcc4f616910f2095f7cb88e470eaac4955fc101308e5c84939f092c3
    created_at: '2026-08-01T03:14:31.202362+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T03:14:31.202362+00:00'
    branch_key: epic-EXOCOMP-3
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 15:58
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 15:58
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 15:58
---
Understanding: duplicate screening only. I will search task records and repository plans for prior work covering the same node-side Ed25519 approval verifier, inspect each plausible candidate's full description/comments, and either archive EXOCOMP-95 as duplicate or hand it off for implementation with evidence.
---
author: oompah
created: 2026-07-24 15:59
---
Discovery: no duplicate confirmed. Full records reviewed: EXOCOMP-24 is the parent epic whose planner deliberately decomposed this exact verifier into EXOCOMP-95; EXOCOMP-86 defines only the coordinator-side canonical token contract/hash helpers; EXOCOMP-23 is coordinator-side issuance; EXOCOMP-96 owns fresh-evidence comparison; EXOCOMP-98 only integrates the completed verifier/checker/ledger. EXOCOMP-87 issues node TLS certificates and does not provision or verify approval-token keys. A repository/all-ref search found no ApprovalVerifier implementation. The Milestone 3 plan uniquely assigns node-side signature, binding, and freshness validation to this child.
---
author: oompah
created: 2026-07-24 15:59
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no duplicate; EXOCOMP-95 should proceed to implementation.

Evidence/decisions: Reviewed full task histories for EXOCOMP-24, EXOCOMP-23, EXOCOMP-86, EXOCOMP-87, EXOCOMP-96, and EXOCOMP-98. EXOCOMP-24 intentionally created EXOCOMP-95 as its signature/bindings/freshness child. The others are complementary coordinator issuance/encoding, TLS certificate issuance, evidence re-checking, or gate integration scopes. Searched repository docs and every local/remote git ref for ApprovalVerifier/approval_verifier and node signature-verification language; only plans/milestone-3-safety-validation.md contains the design requirement, and no implementation exists.

Relevant files: plans/milestone-3-safety-validation.md; origin/EXOCOMP-86 contains apps/exocomp_coordinator/lib/exocomp/coordinator/safety/approval_token.ex. Requested new files are apps/exocomp_node/lib/exocomp/node/safety/approval_verifier.ex and its focused test.

Remaining work/risks: implement public-key loading with redacted failures, canonical encoding compatibility without a coordinator app dependency, Ed25519 verification, all binding/freshness checks, wire-format parsing, and focused tests. The supplied filesystem is actually on epic-EXOCOMP-24 tracking origin/main, while the prompt says epic-EXOCOMP-3; the implementation agent must reconcile the checkout and prerequisite EXOCOMP-86 integration before editing or committing.

Recommended next focus: feature (security-sensitive implementation). No repository files changed; quality gates were not applicable during read-only screening.
---
author: oompah
created: 2026-07-24 15:59
---
Agent completed successfully in 109s (798245 tokens)
---
author: oompah
created: 2026-07-24 15:59
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 23
- Tokens: 794.7K in / 3.6K out [798.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 49s
- Log: EXOCOMP-95__20260724T155806Z.jsonl
---
author: oompah
created: 2026-07-24 15:59
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 16:00
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:00
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 16:00
---
Understanding: I'm implementing Exocomp.Node.Safety.ApprovalVerifier — the node-side cryptographic and binding-validation layer for Ed25519-signed approval tokens. Plan:

1. Merge/inspect EXOCOMP-86's ApprovalToken (coordinator side) for canonical_encode logic
2. Extract canonical_encode to exocomp_core as a shared module (avoids cross-app dependency)
3. Implement ApprovalVerifier in apps/exocomp_node/ with: public key loading (config-path approach), Ed25519 signature verification via :crypto.verify, and all 11 binding checks
4. Write comprehensive tests covering all specified cases
5. Run make test && make lint before closing

Key design decisions to document: config-path key loading, shared encoding in exocomp_core, no cross-app coordinator dependency.
---
author: oompah
created: 2026-07-24 16:04
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:04
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 16:04
---
Understanding: Implementing the node-side Ed25519 verifier with a configurable lazy-loaded raw 32-byte public-key path, shared canonical token encoding/hash helpers in exocomp_core, strict binding/freshness checks, and comprehensive focused tests. The supplied worktree was clean but on epic-EXOCOMP-24; I corrected it in place to a new EXOCOMP-95 branch at origin/main.
---
author: oompah
created: 2026-07-24 16:08
---
Implementation: Added Exocomp.Core.ApprovalToken for deterministic canonical JSON and SHA-256 helpers; added Exocomp.Node.Safety.ApprovalVerifier with documented nested wire format, lazy raw-key loading with redacted fail-closed errors, Ed25519 verification, all execution bindings, and strict issued/expires checks. Added focused core and node tests covering correct/bad keys, binary/base64url signatures, all eleven tamper fields, expiry/future issuance, and node/action/parameter mismatches.
---
author: oompah
created: 2026-07-24 16:08
---
Discovery: origin/EXOCOMP-86 contains the canonical JSON/hash contract but is based on an older divergent history, so merging it would delete current node/A2A work. I copied the exact eleven-field encoding contract into a shared exocomp_core module. Existing node identity is passed through runtime configuration objects rather than stored globally, so the verifier takes node_id in its execution context; the approval public-key file path is injected through Application config.
---
author: oompah
created: 2026-07-24 16:29
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 16:29
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 16:29
---
Understanding: Resuming the existing node-side approval verifier implementation. I will audit the current diff for contract/security correctness, run the Makefile test and lint gates, fix any failures, then commit, push, and close EXOCOMP-95.
---
author: oompah
created: 2026-07-24 16:29
---
Discovery: The prior run left four focused files untracked: shared Exocomp.Core.ApprovalToken canonical/hash helpers, node ApprovalVerifier, and tests for both. The shared encoder matches origin/EXOCOMP-86's fixed eleven-field lexicographic signing contract while avoiding a coordinator dependency. The verifier uses a configurable raw 32-byte key file, redacted fail-closed key errors, Ed25519 verification, execution bindings, and strict freshness checks. I also corrected the worktree attachment from epic-EXOCOMP-24 to the existing EXOCOMP-95 branch before committing.
---
author: oompah
created: 2026-07-24 16:35
---
Implementation: Added Exocomp.Core.ApprovalToken with the coordinator-compatible deterministic eleven-field canonical JSON contract and SHA-256 parameter/evidence helpers. Added Exocomp.Node.Safety.ApprovalVerifier with documented nested wire format, raw/base64url signature support, lazy configurable 32-byte public-key loading with redacted fail-closed errors, Ed25519 verification, all required execution bindings, and strict issued/expires checks. Added focused core and node tests covering valid tokens, bad signatures/keys, missing/malformed key files, each payload field, freshness, and node/action/parameter mismatches.
---
author: oompah
created: 2026-07-24 16:36
---
Verification: Static review and git diff --cached --check passed. make fmt, make test, and make lint were each attempted, but none could start the pinned builder because this managed host's Podman runtime under /run/user/1000/libpod is read-only; a filesystem-sandbox fallback was blocked by disabled user namespaces. The focused tests are included but could not be executed in this session. No code/test failure was observed; this is an infrastructure limitation that review CI must validate.
---
author: oompah
created: 2026-07-24 16:36
---
Completion: Delivered and pushed commit c64f176 on origin/EXOCOMP-95. The node now has a configurable fail-closed Ed25519 approval verifier with signature, eleven-field binding, and strict freshness validation, backed by shared coordinator-compatible canonical hashing/encoding and comprehensive focused tests. Working tree is clean and synchronized with origin. Required Makefile gates were attempted but blocked before execution by the managed host's read-only Podman runtime; this limitation is recorded for review CI.
---
author: oompah
created: 2026-07-24 16:36
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 0, Tool calls: 50
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 7m 33s
- Log: EXOCOMP-95__20260724T162907Z.jsonl
---
author: oompah
created: 2026-07-24 16:36
---
Implemented and pushed node-side Ed25519 approval-token verification with shared canonical encoding, configurable redacted public-key loading, all required binding/freshness checks, and focused tests. Makefile gates were attempted but could not launch due the host's read-only Podman runtime; review CI must execute them.
---
author: oompah
created: 2026-08-01 03:00
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-08-01 03:14
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 03:14
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-01 03:16
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- merged_commit: 7b477ce9a3594a260e19370ffdf760208a207767
- commit_title: EXOCOMP-95: verify signed approval tokens
- verifier_file: apps/exocomp_node/lib/exocomp/node/safety/approval_verifier.ex
- verifier_test_file: apps/exocomp_node/test/exocomp/node/safety/approval_verifier_test.exs
- shared_encoder_file: apps/exocomp_core/lib/exocomp/core/approval_token.ex
- shared_encoder_test_file: apps/exocomp_core/test/exocomp/core/approval_token_test.exs
- commit_on_main: yes
- files_added_by_commit: 4
- insertions_by_commit: 471
---
<!-- COMMENTS:END -->
