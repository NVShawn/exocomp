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
- needs:test
assignee: null
created_at: '2026-07-23T19:08:57.920933Z'
updated_at: '2026-07-24T02:31:35.533357Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 1dd15b50-0f8b-49cf-a311-4312326fa14a
oompah.work_branch: epic-EXOCOMP-1
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
<!-- COMMENTS:END -->
