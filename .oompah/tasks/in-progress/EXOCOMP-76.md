---
id: EXOCOMP-76
type: feature
status: In Progress
priority: 1
title: Implement durable node-bound enrollment token service
parent: EXOCOMP-16
children: []
blocked_by:
- EXOCOMP-75
- EXOCOMP-14
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T23:01:19.306900Z'
updated_at: '2026-07-24T01:32:11.348209Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 1ce4bb7b-ddd1-44d2-bbe0-3ca2a648eaa7
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 159879
  total_output_tokens: 1884
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 159879
      output_tokens: 1884
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 159879
    output_tokens: 1884
    cost_usd: 0.0
    recorded_at: '2026-07-24T01:08:15.626836+00:00'
---
## Summary

Implement the coordinator enrollment-token service consumed by EXOCOMP-17. Use the inventory/registry contract from EXOCOMP-14 and protected online state from EXOCOMP-75. Provide explicit issue and consume APIs. Issuance must reject node IDs absent from the active inventory, use a default lifetime of 600 seconds, allow only shorter positive configured lifetimes, generate high-entropy opaque token values, return the plaintext token only once, and persist only a cryptographic digest plus node ID, expiry, and consumption metadata. Consumption must perform constant-time digest comparison and atomically validate inventory membership, bound node ID, expiry, and unused status before marking the token consumed so concurrent requests cannot both succeed. Persist replay state across coordinator restarts with restrictive permissions and fail closed on corrupt or unavailable storage; prune expired records without making replay possible inside their validity window. Inject time/randomness/storage seams for deterministic tests. Tokens, digests, keys, and private metadata must never appear in Logger output, audit payloads, errors, Inspect output, or crash reports; emit only safe node ID/result/correlation metadata through the EXOCOMP-14 audit abstraction. Add focused tests for issuance membership checks, ten-minute default and shorter overrides, expiry boundary, node mismatch, sequential and concurrent replay, restart persistence, corrupt storage, pruning, permissions, and log/audit redaction. Run coordinator-focused tests plus make fmt-check, make test, and make lint. Acceptance: tokens are inventory-node-bound, expiring, single-use under concurrency and restart, stored protected, and secret-free in observable output.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 01:06
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 01:06
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 01:07
---
Understanding: Duplicate screening only. EXOCOMP-76 requests the coordinator-side durable enrollment-token service: inventory-bound issuance, digest-only protected persistence, atomic single-use consumption across concurrency/restarts, expiry, redaction, audit metadata, and focused tests. I will compare the parent, dependencies, consumer, and integration sibling before deciding whether it duplicates existing work; no implementation will occur in this focus.
---
author: oompah
created: 2026-07-24 01:07
---
Discovery: No duplicate found. EXOCOMP-16 explicitly decomposed its original combined CA/token scope into EXOCOMP-75 (PKI bootstrap/state validation), EXOCOMP-76 (durable inventory-bound enrollment tokens), and EXOCOMP-77 (supervision/operator/API integration). EXOCOMP-17 is node-side enrollment that consumes this service, while EXOCOMP-14 provides inventory/registry/audit primitives. Their full descriptions and histories show complementary, non-overlapping ownership.
---
author: oompah
created: 2026-07-24 01:07
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-76 is a unique, intentionally-created child of EXOCOMP-16 and should proceed to implementation.

Evidence: Searched enrollment-token, node-bound, single-use, and replay terms in the available repository plans/docs (the local .oompah/tasks mirror is absent). Reviewed full tracker state/comments for EXOCOMP-16, EXOCOMP-14, EXOCOMP-17, EXOCOMP-75, and EXOCOMP-77. EXOCOMP-16 comments #19-23 explicitly define EXOCOMP-76 as the durable token-service slice. EXOCOMP-75 implements PKI bootstrap only; EXOCOMP-77 integrates the token service; EXOCOMP-17 consumes it node-side; EXOCOMP-14 supplies inventory and audit contracts.

Relevant files/design: plans/milestone-2-coordinator.md; apps/exocomp_coordinator/lib/exocomp/coordinator/ and its tests. The current worktree reports branch epic-EXOCOMP-16 despite the dispatch text naming epic-EXOCOMP-2, and contains an unrelated untracked apps/exocomp_coordinator/tmp/ directory; neither was modified.

Remaining work/risks: Implement the explicit issue/consume service, durable digest-only protected store, atomic concurrency/restart replay prevention, fail-closed corruption/availability behavior, pruning, injected seams, audit/redaction, and required focused/full quality gates. Preserve existing untracked files and ensure the implementation branch includes completed EXOCOMP-14 and EXOCOMP-75 work.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 01:08
---
Agent completed successfully in 95s (161763 tokens)
---
author: oompah
created: 2026-07-24 01:08
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 13
- Tokens: 159.9K in / 1.9K out [161.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 35s
- Log: EXOCOMP-76__20260724T010656Z.jsonl
---
author: oompah
created: 2026-07-24 01:08
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 01:08
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 01:08
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 01:08
---
Understanding: Dispatched as Maintenance Engineer to EXOCOMP-76. This task requires implementing a durable node-bound enrollment token service in the coordinator. The previous duplicate_detector confirmed this is unique work. I will now explore the codebase to understand what exists (EXOCOMP-14 inventory/audit contracts, EXOCOMP-75 online state) before determining if this is maintenance-scope or requires a feature handoff.
---
author: oompah
created: 2026-07-24 01:11
---
Discovery: EXOCOMP-14 (inventory/registry/audit) and EXOCOMP-75 (PKI bootstrap) are both Done and merged. I've fast-forwarded EXOCOMP-76 branch to include both via EXOCOMP-75 merge. Current coordinator has: Inventory GenServer, ETS Registry, Audit GenServer with redaction, Health, Error struct, and PKI Bootstrap module. Enrollment token service is completely absent. Will implement EnrollmentToken GenServer with: inventory-bound issuance (rejects unknown node IDs), 600s default lifetime (shorter overrides allowed), high-entropy opaque tokens (48 random bytes split into 16-byte ID + 32-byte secret), single-use (digest-only storage), durable protected storage (JSON file at 0o600 in 0o700 dir), atomic constant-time consumption, fail-closed on corrupt storage, pruning after expiry, injected time/rand/store seams, and full audit/log redaction of all secret material.
---
author: oompah
created: 2026-07-24 01:31
---
Implementation: Added Exocomp.Coordinator.EnrollmentToken GenServer with full durable node-bound enrollment token service. Key design decisions:

TOKEN FORMAT: 'tok_{key_b64url}.{secret_b64url}' where key=16 random bytes (lookup index), secret=32 random bytes (the actual credential). Only SHA-256(secret) is stored as a binary digest.

ISSUANCE: Validates node ID against inventory_fn seam (defaults to live Inventory.current()), rejects missing nodes, generates token using rand_fn seam, writes to store atomically via staged-rename, emits audit event with only node_id. Fails closed if storage fails.

CONSUMPTION: All validation occurs atomically in one GenServer call (preventing concurrent double-consumption). Validates format, looks up by key_b64, constant-time compares SHA-256(presented_secret) vs stored_digest using :crypto.hash_equals/2, checks node_id match, expiry (strict < not <=), consumed_at == nil. Persists consumed state before returning :ok - fails closed if storage fails.

PERSISTENCE: mode-0700 directory, mode-0600 file at {store_path}/enrollment_tokens.json. JSON format with 'tok_' prefix never stored. Staged atomic rename. Fail-closed on corrupt file (stops init). Missing file treated as first start. Expires-at pruning on startup and via prune/1.

REDACTION: format_status/1 replaces all digest values with '[REDACTED]'. rand_fn/now_fn/inventory_fn stripped from crash reports. Audit events include only node_id/result/correlation. Tokens never logged.

SEAMS: now_fn, rand_fn, store_path, inventory_fn, max_lifetime all injectable.

TESTS: 61 tests covering all required scenarios: membership checks, default (600s) and shorter lifetimes, expiry boundary, node mismatch, sequential/concurrent replay, restart persistence, corrupt storage (3 variants), pruning, file/dir permissions, log/audit/error/format_status redaction.
---
author: oompah
created: 2026-07-24 01:32
---
Verification: All quality gates pass on commit af14041 (branch epic-EXOCOMP-16):

- make test: 61/61 coordinator tests pass including all 61 new EnrollmentToken tests. 55/55 bench tests pass. 2/2 core tests pass. 2 pre-existing node failures (EXOCOMP-83: missing /usr/bin/kill in Alpine) are unrelated.
- make lint: Zero warnings-as-errors.
- make fmt-check: All files properly formatted.

Test coverage confirmed for all acceptance criteria:
- enrollment_token_test.exs (61 tests): inventory membership, 600s default + shorter overrides, lifetime validation (>600 rejected, <=0 rejected), expiry boundary (valid at T+599, rejected at T+600 and T+601), node mismatch, sequential replay, concurrent replay (exactly 1 success out of 2 concurrent calls), restart persistence (issue pre-restart consumed post-restart, replay of pre-consumed token rejected post-restart), 3 corrupt storage variants (invalid JSON, empty file, wrong version), pruning (removes expired, preserves unexpired, pruned file contains no records), file permissions (0700 dir, 0600 file), log/audit/error/format_status redaction.
---
<!-- COMMENTS:END -->
