---
id: EXOCOMP-15
type: feature
status: In Progress
priority: 1
title: Implement DNS discovery and concurrent node polling
parent: EXOCOMP-2
children: []
blocked_by:
- EXOCOMP-12
- EXOCOMP-14
labels: []
assignee: null
created_at: '2026-07-23T19:09:29.099203Z'
updated_at: '2026-07-24T02:32:39.120301Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 304dc270-7184-4769-bff0-6462f5e389b8
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Implement DNS discovery and concurrent node polling.

Implementation
Resolve configured hostnames, track address changes, verify mTLS identity independently of reverse DNS, and poll Agent Cards/health every 30 seconds with jitter, bounded concurrency, per-node timeout, failure states, and backoff.

Testing
Test DNS changes, multiple addresses, wrong identity, healthy/slow/stale/unreachable nodes, concurrent polling, backoff, and recovery without blocking unrelated nodes.

Acceptance Criteria
- [ ] At least three nodes are polled concurrently.
- [ ] One slow or unreachable node cannot delay unrelated polls.
- [ ] Address changes require successful DNS and mTLS checks.
- [ ] Registry states and timestamps are correct.
- [ ] Focused tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:31
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:31
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 02:32
---
Understanding: Duplicate screening initiated for EXOCOMP-15 (DNS discovery and concurrent node polling). Searching all sibling tasks of the EXOCOMP-2 epic (EXOCOMP-14 through EXOCOMP-20) and prior task histories for overlap with: DNS hostname resolution, address change tracking, mTLS identity verification independent of reverse DNS, and concurrent health polling with jitter/backoff.
---
author: oompah
created: 2026-07-24 02:32
---
Discovery: No duplicate confirmed. All sibling tasks reviewed with full detail:

- EXOCOMP-14 (Done): Coordinator inventory, registry, audit scaffold — provides ETS registry and OTP supervision foundation; no DNS resolution or polling logic
- EXOCOMP-16 (Done): Coordinator CA initialization and enrollment tokens — PKI only; EXOCOMP-16's duplicate_detector explicitly named EXOCOMP-15 as a distinct 'DNS discovery and polling' task
- EXOCOMP-17 (Open): Node enrollment and certificate renewal — node-side key gen and cert installation; no coordinator polling
- EXOCOMP-18 (Open): Coordinator diagnostic task orchestration and audit — correlation IDs, A2A dispatch, audit events; no DNS or health polling
- EXOCOMP-19 (Open): Expose coordinator cluster A2A service — Agent Card HTTP endpoints; no DNS or polling
- EXOCOMP-20 (Open): M2 milestone verification only

EXOCOMP-15 uniquely owns: (1) DNS resolver GenServer resolving configured hostnames, (2) address change adoption on successful re-verification, (3) mTLS identity verification independent of reverse DNS, (4) health poller with 30s interval + jitter + bounded concurrency + per-node timeouts + exponential backoff + failure state machine, (5) tests for DNS changes, multiple addresses, wrong identity, slow/stale/unreachable nodes, concurrent polling, backoff, and recovery. No other task covers these concerns.
---
<!-- COMMENTS:END -->
