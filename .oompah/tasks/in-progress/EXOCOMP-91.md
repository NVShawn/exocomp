---
id: EXOCOMP-91
type: feature
status: In Progress
priority: 1
title: Run bounded concurrent node polls with per-node isolation
parent: EXOCOMP-15
children: []
blocked_by:
- EXOCOMP-89
- EXOCOMP-90
labels:
- focus-complete:duplicate_detector
- needs:feature
assignee: null
created_at: '2026-07-24T02:43:11.382930Z'
updated_at: '2026-07-24T03:52:54.059469Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: b1604bee-3f1d-4946-9c2b-cbd255e10cb2
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Implement the supervised health poller that selects Registry nodes whose next_eligible_poll_at is due and runs independent DNS/probe jobs with bounded concurrency. Support at least three simultaneous polls, enforce a per-node timeout, prevent duplicate in-flight polls for one node, and ensure a slow, crashed, or unreachable node cannot delay scheduling or completion of unrelated nodes. Feed typed probe outcomes through the scheduling/state-transition API, update Agent Card version/supported skills and health timestamps atomically, clean up timed-out/crashed workers, and continue polling after worker or poller restart. Make interval, jitter, concurrency, timeouts, clock, resolver, and probe adapters configurable for deterministic tests. Cover the concurrency bound, three overlapping polls, isolation from slow/unreachable nodes, timeout cleanup, no duplicate work, and continued scheduling/recovery; wire the supervisor tree and run affected Make targets.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 03:51
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 03:51
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 03:51
---
Understanding: I am the Duplicate Investigator for EXOCOMP-91 ('Run bounded concurrent node polls with per-node isolation'). My role is to check whether this issue is a duplicate of any existing task before any implementation begins. I will search the task tracker and docs for similar topics: health polling, concurrent polls, DNS probes, per-node isolation, bounded concurrency, Registry nodes, supervisor trees.
---
author: oompah
created: 2026-07-24 03:52
---
Discovery: Duplicate screening found NO confirmed duplicate. EXOCOMP-91 is a unique, well-scoped child task of EXOCOMP-15 ('Implement DNS discovery and concurrent node polling'), explicitly created as part of a five-way decomposition:

- EXOCOMP-88: DNS hostname resolution into candidates (Done)
- EXOCOMP-89: mTLS identity verification and address adoption (Done)
- EXOCOMP-90: Poll scheduling, backoff, and registry state transitions (Done)
- EXOCOMP-91: Bounded concurrent poll execution with per-node isolation (In Progress — this task)
- EXOCOMP-92: Multi-node integration coverage (Open, depends on EXOCOMP-91)

All prior duplicate screening agents for EXOCOMP-88, EXOCOMP-89, and EXOCOMP-90 explicitly confirmed that EXOCOMP-91 uniquely owns concurrent worker supervision, TaskSupervisor/bounded pool management, in-flight deduplication, per-node timeouts, and isolation of slow/crashed nodes. EXOCOMP-90 (Done) established the scheduling and state-transition API that EXOCOMP-91 will consume. No other task in EXOCOMP-14 through EXOCOMP-20 nor any sibling covers this scope.

Evidence reviewed: EXOCOMP-15, EXOCOMP-88, EXOCOMP-89, EXOCOMP-90, EXOCOMP-92 via oompah task view; plans/milestone-2-coordinator.md 'Node State' section (30-second jittered polling with bounded concurrency, per-node timeouts, failure states, backoff) and existing coordinator codebase (no concurrent poll supervisor exists yet).
---
author: oompah
created: 2026-07-24 03:52
---
Focus handoff: duplicate_detector

1. **Outcome:** No duplicate confirmed. EXOCOMP-91 is the unique concurrent-poll-supervisor child of EXOCOMP-15 and should proceed to implementation.

2. **Evidence and decisions:**
   - EXOCOMP-88 (Done): DNS resolver producing candidate_addresses in Registry — contributes to probe pipeline, no concurrency logic
   - EXOCOMP-89 (Done): NodeProber with injectable probe_fn returning typed outcomes (:healthy/:degraded/:timeout/:unreachable/:identity_mismatch), updating Registry.addresses only after verification
   - EXOCOMP-90 (Done): Registry APIs: begin_poll/record_observation with ordered attempt tokens, due_nodes selection by next_eligible_poll_at, jitter/backoff, freshness-based state transitions, redacted audit events
   - EXOCOMP-92 (Open): Multi-node integration suite — depends on EXOCOMP-91 landing first
   - plans/milestone-2-coordinator.md Node State section specifies bounded concurrency, per-node timeouts, no cross-node blocking; Test Strategy requires ≥3 concurrent polls and slow/unreachable node isolation tests
   - apps/exocomp_coordinator/lib/ — no poll supervisor or concurrent worker exists yet

3. **Remaining work and risks:**
   - Implement `Exocomp.Coordinator.PollSupervisor` (or HealthPoller) that selects due nodes from Registry, spawns isolated per-node Task workers bounded by a configurable concurrency limit (min 3), enforces per-node timeouts, prevents duplicate in-flight polls for the same node, feeds typed NodeProber outcomes into Registry (via EXOCOMP-90 APIs: begin_poll/record_observation), and cleans up timed-out/crashed workers
   - Make all adapters injectable: interval, jitter, concurrency, timeouts, clock, resolver, and probe functions — to enable deterministic tests without sleeps
   - Cover: concurrency bound, ≥3 overlapping polls, slow/unreachable node isolation, timeout cleanup, duplicate-work prevention, scheduling recovery after restart
   - Wire the supervisor into the application supervisor tree
   - Run affected Make targets (make test, make lint)
   - Risk: EXOCOMP-90's Registry now has begin_poll/due_nodes APIs — the feature agent must use these (not direct ETS writes) to coordinate in-flight tracking

4. **Recommended next focus:** feature
---
<!-- COMMENTS:END -->
