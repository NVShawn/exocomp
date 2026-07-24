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
labels: []
assignee: null
created_at: '2026-07-23T23:01:19.306900Z'
updated_at: '2026-07-24T01:06:21.714460Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 08cd3096-9e89-4241-9d8f-54dadfb534d5
---
## Summary

Implement the coordinator enrollment-token service consumed by EXOCOMP-17. Use the inventory/registry contract from EXOCOMP-14 and protected online state from EXOCOMP-75. Provide explicit issue and consume APIs. Issuance must reject node IDs absent from the active inventory, use a default lifetime of 600 seconds, allow only shorter positive configured lifetimes, generate high-entropy opaque token values, return the plaintext token only once, and persist only a cryptographic digest plus node ID, expiry, and consumption metadata. Consumption must perform constant-time digest comparison and atomically validate inventory membership, bound node ID, expiry, and unused status before marking the token consumed so concurrent requests cannot both succeed. Persist replay state across coordinator restarts with restrictive permissions and fail closed on corrupt or unavailable storage; prune expired records without making replay possible inside their validity window. Inject time/randomness/storage seams for deterministic tests. Tokens, digests, keys, and private metadata must never appear in Logger output, audit payloads, errors, Inspect output, or crash reports; emit only safe node ID/result/correlation metadata through the EXOCOMP-14 audit abstraction. Add focused tests for issuance membership checks, ten-minute default and shorter overrides, expiry boundary, node mismatch, sequential and concurrent replay, restart persistence, corrupt storage, pruning, permissions, and log/audit redaction. Run coordinator-focused tests plus make fmt-check, make test, and make lint. Acceptance: tokens are inventory-node-bound, expiring, single-use under concurrency and restart, stored protected, and secret-free in observable output.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

