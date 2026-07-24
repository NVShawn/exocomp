---
id: EXOCOMP-13
type: chore
status: In Progress
priority: 1
title: Verify the M1 node-agent milestone
parent: EXOCOMP-1
children: []
blocked_by:
- EXOCOMP-12
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:08:57.920933Z'
updated_at: '2026-07-24T02:44:55.949141Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 04088bd9-279b-4422-8161-5ed0b98941c2
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 17
  total_output_tokens: 3865
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 17
      output_tokens: 3865
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 17
    output_tokens: 3865
    cost_usd: 0.0
    recorded_at: '2026-07-24T02:31:42.528103+00:00'
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Verify the M1 node-agent milestone.

Implementation
Build a clean Linux integration fixture using test certificates and fake or pinned llama.cpp; exercise release startup, Agent Card discovery, diagnostics, proposal failure behavior, task lifecycle, concurrency, and shutdown; collect evidence for every M1 acceptance criterion.

Testing
Run the full ExUnit/integration suite and make build, make test, make lint, and make fmt-check; verify the fixture host state before and after.

Acceptance Criteria
- [ ] Every M1-CRIT-* item in the plan has recorded pass/fail evidence.
- [ ] The node release works without development tooling.
- [ ] The end-to-end test proves no host state change.
- [ ] All repository quality gates pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:30
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:30
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 02:31
---
Understanding: Acting as Duplicate Investigator for EXOCOMP-13 (Verify the M1 node-agent milestone). Searching for any duplicate verification, acceptance, or integration-fixture task across the EXOCOMP task graph.
---
author: oompah
created: 2026-07-24 02:31
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-13 is a unique task with no overlap in the existing EXOCOMP task graph.

**Evidence reviewed:**
- Reviewed the EXOCOMP-1 parent epic: EXOCOMP-13 is the final (7th) M1 child task and is explicitly listed as the acceptance verification step.
- Reviewed all 6 sibling M1 tasks: EXOCOMP-7 (Done, scaffold), EXOCOMP-8 (Done, A2A types), EXOCOMP-9 (Done, mTLS identity), EXOCOMP-10 (Done, diagnostics), EXOCOMP-11 (Done, llama.cpp), EXOCOMP-12 (Done, node A2A service). None of them collect evidence against M1-CRIT-* acceptance criteria or run an end-to-end integration fixture.
- Searched plans/milestone-1-node-agent.md: M1-CRIT-1 through M1-CRIT-7 acceptance criteria are defined there; EXOCOMP-13 is uniquely responsible for demonstrating pass/fail evidence for each.
- No other task in the known graph (EXOCOMP-14 through EXOCOMP-47+ cover M2-M6 milestones) duplicates M1 acceptance testing.
- EXOCOMP-12 (the blocker) is now Done, so EXOCOMP-13 is unblocked.

**Relevant files:**
- plans/milestone-1-node-agent.md — M1-CRIT-1 through M1-CRIT-7 acceptance criteria (lines ~185-198)
- apps/exocomp_node/ — the node application under test
- Makefile — quality gate targets: make build, make test, make lint, make fmt-check

**Remaining work:**
1. Build a clean Linux integration fixture using test certificates and a fake/pinned llama.cpp stub
2. Exercise release startup, Agent Card discovery, diagnostics, proposal failure, task lifecycle, concurrency, and shutdown
3. Collect pass/fail evidence for every M1-CRIT-* item
4. Run the full ExUnit/integration suite and all Make targets
5. Verify the fixture host state is unchanged before and after

**Recommended next focus:** test — this is an integration testing and acceptance verification task for the completed M1 node-agent milestone
---
author: oompah
created: 2026-07-24 02:31
---
Agent completed successfully in 93s (3882 tokens)
---
author: oompah
created: 2026-07-24 02:31
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 32, Tool calls: 22
- Tokens: 17 in / 3.9K out [3.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 33s
- Log: EXOCOMP-13__20260724T023011Z.jsonl
---
author: oompah
created: 2026-07-24 02:31
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 02:31
---
Agent dispatched (profile: quick)
---
author: oompah
created: 2026-07-24 02:31
---
Focus: Test Engineer
---
author: oompah
created: 2026-07-24 02:32
---
Understanding: I will verify every M1-CRIT item with a hermetic Linux integration fixture that exercises the built release, test certificates, a fake/pinned llama.cpp boundary, discovery, diagnostics, proposal failure, lifecycle/concurrency, graceful shutdown, and before/after host-state invariance. I will follow existing test patterns and run focused coverage plus make build, test, lint, and fmt-check.
---
author: oompah
created: 2026-07-24 02:32
---
Discovery: the current epic worktree was stale; after fast-forwarding to origin/main, the complete M1 node-agent implementation is present on the finished blocker branch origin/epic-EXOCOMP-12 (A2A protocol/router, mTLS identity/listener, collectors, task registry, skill handlers, and tests) but is not yet merged to main. The verification must integrate that prerequisite branch before adding release-level acceptance coverage. Existing integration/fixture_test.exs tests a separate systemd fixture and does not verify M1.
---
author: oompah
created: 2026-07-24 02:33
---
Agent completed successfully in 73s
---
author: oompah
created: 2026-07-24 02:33
---
Run #1 [attempt=1, profile=quick, role=fast -> Codex/default]
- Turns: 0, Tool calls: 27
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 13s
- Log: EXOCOMP-13__20260724T023153Z.jsonl
---
author: oompah
created: 2026-07-24 02:33
---
Agent completed without closing this issue (73s). Escalating from 'quick' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-24 02:33
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:33
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 02:33
---
Understanding: As Maintenance Engineer, I'm taking over from the Test Engineer focus. The previous agent found that the complete M1 node-agent implementation exists on the finished EXOCOMP-12 branch but isn't merged to main yet. My job is to: (1) explore the current branch state, (2) build the integration fixture for M1 acceptance criteria, (3) run all quality gates, and (4) close the task. Starting with exploration now.
---
author: oompah
created: 2026-07-24 02:38
---
Discovery: The complete M1 implementation is on the current branch (epic-EXOCOMP-1 → EXOCOMP-13). Key findings:

- Unit tests cover M1-CRIT-4 (collectors), M1-CRIT-5 (llama.cpp failure isolation), M1-CRIT-6 (identity/listener validation)
- What is MISSING: a live end-to-end integration test that starts a real Bandit mTLS listener and makes actual HTTPS A2A requests — needed to provide pass/fail evidence for M1-CRIT-3, M1-CRIT-5 (runtime), M1-CRIT-6 (runtime), M1-CRIT-7 (host state invariance)
- The M1 acceptance test will go in apps/exocomp_node/test/integration/m1_acceptance_test.exs, tagged :m1_acceptance (no systemd needed, runs in standard CI container)
- Quality gates (make build, test, lint, fmt-check) remain to be run — these constitute M1-CRIT-1 evidence
---
author: oompah
created: 2026-07-24 02:44
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:44
---
Focus: Maintenance Engineer
---
<!-- COMMENTS:END -->
