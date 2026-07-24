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
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:09:29.099203Z'
updated_at: '2026-07-24T02:40:51.424812Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 16f41088-7488-4fad-9ba8-b29ab784d7f5
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 753297
  total_output_tokens: 5501
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 753297
      output_tokens: 5501
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 36
    output_tokens: 704
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:33:14.132059+00:00'
  - profile: default
    model: unknown
    input_tokens: 424916
    output_tokens: 3004
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:35:17.033832+00:00'
  - profile: standard
    model: unknown
    input_tokens: 328345
    output_tokens: 1793
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:36:36.602541+00:00'
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
author: oompah
created: 2026-07-24 02:33
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 18
- Tokens: 36 in / 704 out [740 total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 44s
- Log: EXOCOMP-15__20260724T023133Z.jsonl
---
author: oompah
created: 2026-07-24 02:33
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:33
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 02:35
---
Agent completed successfully in 89s (427920 tokens)
---
author: oompah
created: 2026-07-24 02:35
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 10
- Tokens: 424.9K in / 3.0K out [427.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 29s
- Log: EXOCOMP-15__20260724T023350Z.jsonl
---
author: oompah
created: 2026-07-24 02:35
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-2`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-24 02:35
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 02:35
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 02:36
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed. EXOCOMP-15 uniquely owns DNS discovery and concurrent coordinator polling; implementation must continue under a feature focus.

Evidence: Repository search found the authoritative scope in plans/milestone-2-coordinator.md: configured hostname resolution, no reverse-DNS trust, address adoption only after resolution plus mTLS verification, and 30-second jittered polling with bounded concurrency, timeouts, state transitions, and backoff. The checkout has no .oompah/tasks directory, so candidate details/comments were verified through tracker views. EXOCOMP-14 is complementary foundation only (inventory, ETS registry, audit, health scaffolding), and its completed implementation contains no DNS resolver or polling loop. EXOCOMP-16 is coordinator PKI initialization/enrollment tokens and explicitly records EXOCOMP-15 as separate DNS discovery/polling work. Prior screening also reviewed EXOCOMP-17 through EXOCOMP-20: enrollment/renewal, diagnostic orchestration, cluster A2A service, and milestone verification respectively; none owns this behavior.

Relevant files/decisions: plans/milestone-2-coordinator.md sections Inventory and Discovery / Node State; apps/exocomp_coordinator is the implementation surface supplied by EXOCOMP-14. Preserve hostname as identity context, never depend on reverse DNS, and keep slow/unreachable nodes isolated through bounded concurrent work and per-node timeout.

Remaining work/risks: Implement DNS resolution/address-change validation, independent mTLS identity checks, jittered concurrent Agent Card/health polling, registry states/timestamps, exponential backoff/recovery, and focused coverage for multiple addresses, identity mismatch, slow/stale/unreachable nodes, concurrency, and recovery. Verify the branch contains the EXOCOMP-14 foundation before coding. Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 02:36
---
Agent completed successfully in 63s (330138 tokens)
---
author: oompah
created: 2026-07-24 02:36
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 9
- Tokens: 328.3K in / 1.8K out [330.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 3s
- Log: EXOCOMP-15__20260724T023535Z.jsonl
---
author: oompah
created: 2026-07-24 02:36
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 02:40
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 02:40
---
Focus: Epic Planner
---
<!-- COMMENTS:END -->
