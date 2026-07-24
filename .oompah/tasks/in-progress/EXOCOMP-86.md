---
id: EXOCOMP-86
type: task
status: In Progress
priority: null
title: Define ApprovalToken struct and deterministic canonical encoding
parent: EXOCOMP-23
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T02:36:43.435381Z'
updated_at: '2026-07-24T03:05:53.635614Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: f8b86f95-c48b-4ac0-a464-87d1b26ceb9a
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 592243
  total_output_tokens: 3701
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 592243
      output_tokens: 3701
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 592216
    output_tokens: 3063
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:40:18.318971+00:00'
  - profile: default
    model: unknown
    input_tokens: 27
    output_tokens: 638
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:46:33.285269+00:00'
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
author: oompah
created: 2026-07-24 02:38
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 02:38
---
Understanding: This run is limited to duplicate investigation. I will search approval-token/canonical-encoding tasks and project design references, read the full state and comments of plausible candidates, then either archive EXOCOMP-86 as duplicate or hand it off with focus-complete:duplicate_detector; no implementation will be performed in this focus.
---
author: oompah
created: 2026-07-24 02:40
---
Discovery: Duplicate screening found no duplicate. Tracker-state search for approval-token, canonical encoding, parameter/evidence hashes, sorted JSON, and SHA-256 map serialization matched only EXOCOMP-86 and its decomposed parent EXOCOMP-23. Full records show EXOCOMP-24 is node-side verification/replay prevention, EXOCOMP-76 is opaque enrollment-token issuance/consumption, EXOCOMP-73 is policy eligibility filtering, and EXOCOMP-84 only computes disk-pressure Evidence integrity data. Git history contains no ApprovalToken module or implementation.
---
author: oompah
created: 2026-07-24 02:40
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-86 is the unique payload-contract/serialization child of EXOCOMP-23 and should proceed to implementation.

Evidence: Searched the tracker state branch and repository docs/plans for approval-token, canonical encoding, parameter_hash, evidence_hash, sorted JSON, and deterministic SHA-256 serialization. Reviewed full task records/comments for EXOCOMP-23, EXOCOMP-24, EXOCOMP-73, and EXOCOMP-76, plus EXOCOMP-84's complete nearby scope. EXOCOMP-23 is the intentionally decomposed parent; EXOCOMP-24 is the node-side verifier/replay owner; EXOCOMP-76 is a distinct opaque enrollment-token protocol; EXOCOMP-73/84 concern policy filtering and disk evidence. Git history has no ApprovalToken implementation. Relevant design is plans/milestone-3-safety-validation.md, Approval Tokens section.

Remaining work/risks: Implement the 11-field enforced struct, schema-version validation, deterministic canonical_encode/1, sha256_hex/1, deterministic parameter/evidence hashing, and focused tests. Confirm the installed Jason version supports sorted-key encoding; if not, construct the canonical object/order explicitly. Run coordinator-focused tests plus make test and make lint, then commit/push/close.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 02:40
---
Agent completed successfully in 97s (595279 tokens)
---
author: oompah
created: 2026-07-24 02:40
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 24
- Tokens: 592.2K in / 3.1K out [595.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 37s
- Log: EXOCOMP-86__20260724T023846Z.jsonl
---
author: oompah
created: 2026-07-24 02:40
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 02:40
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:40
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 02:40
---
Understanding: Implementing the ApprovalToken struct and deterministic canonical encoding for EXOCOMP-86. Plan: (1) Explore existing coordinator app structure and Jason version; (2) Create approval_token.ex with 11-field @enforce_keys struct, canonical_encode/1, sha256_hex/1, hash_params/1, hash_evidence/1, validate_schema_version/1; (3) Write tests covering determinism, field-sensitivity, map-order independence, schema validation, and enforce_keys; (4) Run make test and make lint.
---
author: oompah
created: 2026-07-24 02:43
---
Discovery: Explored codebase structure. Key findings: (1) coordinator app at apps/exocomp_coordinator has no Jason dependency — must add {:jason, "~> 1.4"} to mix.exs; (2) Jason 1.4.5 is in mix.lock (from bench app); (3) No existing ApprovalToken or safety/ directory — greenfield implementation; (4) ProposalSchema in exocomp_node provides a pattern for @schema_version, @enforce_keys, and validate functions; (5) Jason 1.4.x does NOT have sort_keys: true encoder option — will use manual sorted key-value pair construction for deterministic JSON output. Implementation ready to proceed.
---
author: oompah
created: 2026-07-24 02:44
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:45
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 02:45
---
Understanding: Implementing ApprovalToken struct and deterministic canonical encoding. Plan: (1) Verify coordinator app structure and Jason dependency situation; (2) Create approval_token.ex with 11-field @enforce_keys struct, canonical_encode/1, sha256_hex/1, hash_params/1, hash_evidence/1, validate_schema_version/1 using manually sorted JSON since Jason 1.4.x lacks sort_keys; (3) Write tests for all required scenarios; (4) Add Jason dependency to coordinator mix.exs; (5) Run make test and make lint.
---
author: oompah
created: 2026-07-24 02:46
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 14
- Tokens: 27 in / 638 out [665 total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 36s
- Log: EXOCOMP-86__20260724T024500Z.jsonl
---
author: oompah
created: 2026-07-24 02:46
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 02:46
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 02:47
---
Understanding: This is continuation attempt #1. Previous agents confirmed no duplicate exists and discovered: (1) coordinator app lacks Jason dependency — need to add {:jason, "~> 1.4"}; (2) Jason 1.4.x lacks sort_keys option — must use manually sorted key-value construction; (3) No ApprovalToken or safety/ directory exists — greenfield. Plan: Create approval_token.ex with 11-field @enforce_keys struct, canonical_encode/1, sha256_hex/1, hash_params/1, hash_evidence/1, validate_schema_version/1; write full test suite; add Jason dep; run make test + make lint; commit and close.
---
author: oompah
created: 2026-07-24 03:05
---
Implementation: Created apps/exocomp_coordinator/lib/exocomp/coordinator/safety/approval_token.ex with:
- 11-field struct with @enforce_keys on all fields and @schema_version "1"
- canonical_encode/1: builds deterministic UTF-8 JSON by iterating a manually ordered {key, value} pair list in lexicographic key order and concatenating per-pair Jason encodings — avoids Jason 1.4.x's missing sort_keys option and Elixir map ordering non-determinism
- sha256_hex/1: lowercase hex SHA-256 via :crypto.hash/2 + Base.encode16
- hash_params/1 / hash_evidence/1: sorted-JSON SHA-256 of string-keyed maps; nested maps also recursively sorted
- validate_schema_version/1: returns {:ok, token} or {:error, :unknown_schema_version}
Also added {:jason, "~> 1.4"} to coordinator mix.exs (already present from previous agent run).
Test file: apps/exocomp_coordinator/test/exocomp/coordinator/safety/approval_token_test.exs with 44 tests covering all required scenarios.
---
<!-- COMMENTS:END -->
