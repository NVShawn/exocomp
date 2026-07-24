---
id: EXOCOMP-92
type: task
status: In Progress
priority: 1
title: Add multi-node discovery and polling integration coverage
parent: EXOCOMP-15
children: []
blocked_by:
- EXOCOMP-88
- EXOCOMP-89
- EXOCOMP-90
- EXOCOMP-91
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T02:43:19.301040Z'
updated_at: '2026-07-24T04:03:14.937311Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: d3bdff2a-775a-4938-9c68-8c9fc3e864be
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 524986
  total_output_tokens: 2437
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 524986
      output_tokens: 2437
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 524986
    output_tokens: 2437
    cost_usd: 0.0
    recorded_at: '2026-07-24T04:02:54.382953+00:00'
---
## Summary

Add the cross-component verification suite for EXOCOMP-15 after DNS, authenticated probing, scheduling, and concurrent execution land. Use at least three controllable TLS node fixtures and a deterministic DNS/resolver seam to exercise healthy, degraded/slow, stale, unreachable, and wrong-identity nodes; multiple addresses; DNS address changes accepted only after successful mTLS verification; failed address changes retaining the last verified address; bounded concurrent polling; per-node timeout isolation; exponential backoff; and recovery without blocking unrelated nodes. Assert Registry reachability, addresses, Agent Card metadata, failure counters, last-attempt/last-success timestamps, and next eligible poll times, plus relevant redacted audit events. Avoid wall-clock sleeps where injectable clocks/events suffice. Run the focused coordinator suite and every affected Make quality gate (test, lint, fmt-check, and build if applicable), documenting any true environment-only exclusions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 04:01
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 04:01
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 04:01
---
Understanding: Screening EXOCOMP-92 for duplication before any implementation. I will search task records and design docs for existing multi-node discovery/polling integration coverage, then inspect full candidate task histories to distinguish prerequisite component tests from an already-covered cross-component suite.
---
author: oompah
created: 2026-07-24 04:02
---
Discovery: No duplicate confirmed. Reviewed full records for EXOCOMP-15, EXOCOMP-20, and prerequisite children EXOCOMP-88 through EXOCOMP-91. EXOCOMP-15 is the parent that intentionally decomposed this suite into EXOCOMP-92; EXOCOMP-88/89/90/91 contain component-level DNS, probe, scheduling, and concurrency tests, while EXOCOMP-20 is broader milestone verification spanning enrollment, diagnostics, restart, and all M2 criteria. Repository search shows separate Resolver/NodeProber/Registry unit coverage but no existing cross-component multi-node TLS discovery/polling suite. EXOCOMP-92 uniquely owns that integration boundary.
---
author: oompah
created: 2026-07-24 04:02
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no duplicate; EXOCOMP-92 should proceed as a test/integration implementation task.

Evidence and decisions: Full tracker histories reviewed for EXOCOMP-15 and EXOCOMP-88 through EXOCOMP-91, plus closest broader verifier EXOCOMP-20. The four completed siblings explicitly reserve cross-component integration for EXOCOMP-92. EXOCOMP-20 verifies the entire M2 milestone (enrollment, renewal, diagnostics, cancellation, restart, audit) and should consume this focused evidence rather than replace it. plans/milestone-2-coordinator.md lines 172-195 separately require at least three node fixtures and the multi-node integration suite. Existing tests under apps/exocomp_coordinator/test/exocomp/coordinator cover Resolver, NodeProber, and Registry in isolation; repository search found no combined TLS/DNS/HealthPoller scenario suite.

Relevant files: plans/milestone-2-coordinator.md Test Strategy and M2-CRIT-2/M2-CRIT-8; apps/exocomp_coordinator/test/exocomp/coordinator/resolver_test.exs; node_prober_test.exs; registry_test.exs. EXOCOMP-91's pushed HealthPoller implementation/coverage is the final prerequisite and may need integration into the current epic branch before this work begins.

Remaining work and risks: Build controllable TLS node fixtures and a deterministic resolver/clock/event seam; test three-node concurrency, slow/timeout isolation, identity mismatch, address adoption/preservation, state/backoff/timestamp/Agent Card metadata, recovery, and redacted audits without wall-clock sleeps. Ensure the branch contains all completed sibling commits, especially EXOCOMP-91, then run focused coordinator plus affected Make gates and document only genuine environment exclusions.

Recommended next focus: test.
---
author: oompah
created: 2026-07-24 04:02
---
Agent completed successfully in 92s (527423 tokens)
---
author: oompah
created: 2026-07-24 04:02
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 14
- Tokens: 525.0K in / 2.4K out [527.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 32s
- Log: EXOCOMP-92__20260724T040126Z.jsonl
---
author: oompah
created: 2026-07-24 04:02
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 04:03
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 04:03
---
Focus: Test Engineer
---
author: oompah
created: 2026-07-24 04:03
---
Understanding: I am the Test Engineer for EXOCOMP-92. My task is to write the cross-component integration suite for multi-node discovery and polling. Based on the duplicate_detector handoff, I need to: (1) build controllable TLS node fixtures with a deterministic DNS/resolver seam, (2) test at least 3 nodes across healthy, degraded/slow, stale, unreachable, and wrong-identity scenarios, (3) assert Registry reachability, addresses, Agent Card metadata, failure counters, timestamps, backoff, audit events, (4) avoid wall-clock sleeps. I will first explore the codebase to understand the existing architecture before writing tests.
---
<!-- COMMENTS:END -->
