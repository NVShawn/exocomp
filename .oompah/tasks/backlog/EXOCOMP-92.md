---
id: EXOCOMP-92
type: task
status: Backlog
priority: 1
title: Add multi-node discovery and polling integration coverage
parent: EXOCOMP-15
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T02:43:19.301040Z'
updated_at: '2026-07-24T02:43:19.301040Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Add the cross-component verification suite for EXOCOMP-15 after DNS, authenticated probing, scheduling, and concurrent execution land. Use at least three controllable TLS node fixtures and a deterministic DNS/resolver seam to exercise healthy, degraded/slow, stale, unreachable, and wrong-identity nodes; multiple addresses; DNS address changes accepted only after successful mTLS verification; failed address changes retaining the last verified address; bounded concurrent polling; per-node timeout isolation; exponential backoff; and recovery without blocking unrelated nodes. Assert Registry reachability, addresses, Agent Card metadata, failure counters, last-attempt/last-success timestamps, and next eligible poll times, plus relevant redacted audit events. Avoid wall-clock sleeps where injectable clocks/events suffice. Run the focused coordinator suite and every affected Make quality gate (test, lint, fmt-check, and build if applicable), documenting any true environment-only exclusions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

