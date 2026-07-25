---
id: EXOCOMP-113
type: chore
status: In Progress
priority: 1
title: Recover omitted M3 and M4 acceptance and fault-injection work
parent: EXOCOMP-110
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-25T17:58:22.004834Z'
updated_at: '2026-07-25T18:56:27.299360Z'
work_branch: epic-EXOCOMP-110
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: a8cb5c65-95b6-47d5-aa6a-b42863cffdf0
oompah.work_branch: epic-EXOCOMP-110
oompah.task_costs:
  total_input_tokens: 17
  total_output_tokens: 6545
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 17
      output_tokens: 6545
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 17
    output_tokens: 6545
    cost_usd: 0.0
    recorded_at: '2026-07-25T18:56:01.009826+00:00'
---
## Summary

Recover the task-specific changes from EXOCOMP-28 and EXOCOMP-33 onto the EXOCOMP-110 shared recovery branch based on current main. Integrate M3 criterion evidence tests, the complete recovery fault-injection suite, and the EXOCOMP-33 state-restore and approval-gate security fixes without regressing later main changes. Run focused and full Make quality gates and verify all recovered scenarios.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 18:53
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 18:53
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-25 18:53
---
Understanding: As Duplicate Investigator, I'm screening EXOCOMP-113 before any implementation. The task asks to recover M3/M4 acceptance tests and fault-injection work from EXOCOMP-28 and EXOCOMP-33 onto the EXOCOMP-110 epic branch. I will search for any existing tasks covering the same recovery work before proceeding.
---
author: oompah
created: 2026-07-25 18:55
---
Discovery: Duplicate screening found NO duplicate. EXOCOMP-113 is the unique, dedicated recovery task for M3 and M4 deliverables from EXOCOMP-28 and EXOCOMP-33 within the EXOCOMP-110 epic.

Tasks reviewed as candidates:
- EXOCOMP-28 (Needs Human): SOURCE task — M3 safety/remediation verification. Its work (m3_acceptance_test.exs, vacuum_bounds.ex fix, privilege_test.exs fix) is stranded on branch EXOCOMP-28 at commit 27f5c5e and never landed on main. This is a SOURCE not a duplicate.
- EXOCOMP-33 (Needs Human): SOURCE task — M4 fault-injection suite. Its work (fault_injection_test.exs, state_machine.ex security fixes, approval_gate.ex security fix) is stranded on branch EXOCOMP-33 at commit 47fbb61 and never landed on main. This is a SOURCE not a duplicate.
- EXOCOMP-110 (Open): Parent epic — broader scope covering all stranded deliverables.
- EXOCOMP-111 (Done): Sibling — covered M1 A2A codec/fixture recovery (different scope, closed).
- EXOCOMP-112 (Done): Sibling — covered M5 benchmark host-profile/sampler recovery (different scope, closed).
- EXOCOMP-114/115/116 (Open): Siblings — M6 governance, undelivered work, and verification (all different scopes).

EXOCOMP-113 is the sole recovery vehicle for the EXOCOMP-28 and EXOCOMP-33 deliverables. No other task covers integrating these onto epic-EXOCOMP-110.
---
author: oompah
created: 2026-07-25 18:55
---
Focus handoff: duplicate_detector

1. OUTCOME: No duplicate confirmed. EXOCOMP-113 is the unique recovery task for EXOCOMP-28 (M3 acceptance test suite) and EXOCOMP-33 (M4 fault-injection suite + security fixes) onto epic-EXOCOMP-110.

2. RELEVANT FILES, COMMANDS, AND EVIDENCE:

Source commits available as local branches:

EXOCOMP-28 — branch EXOCOMP-28, deliverable commit 27f5c5e:
  Files to recover (3 total):
  - apps/exocomp_node/test/integration/m3_acceptance_test.exs (1493 lines, 44 tests, 8 describe blocks M3-CRIT-1 through M3-CRIT-8)
  - apps/exocomp_node/lib/exocomp/node/vacuum_bounds.ex (user_data_path?/1 now matches bare /home and /root)
  - apps/exocomp_node/test/exocomp/node/privilege_test.exs (rootless-Podman UID branching fix)

EXOCOMP-33 — branch EXOCOMP-33, deliverable commit 47fbb61:
  Files to recover (5 total):
  - apps/exocomp_node/test/exocomp/node/recovery/fault_injection_test.exs (1080 lines, 29 tests, 12 fault scenarios)
  - apps/exocomp_core/lib/exocomp/recovery/state_machine.ex (restore/5 injection defenses — validates known states and from-state match)
  - apps/exocomp_core/test/exocomp/recovery/state_machine_test.exs (3 new security tests)
  - apps/exocomp_node/lib/exocomp/node/safety/approval_gate.ex (nil fallback for unconfigured node_id, not empty string)
  - apps/exocomp_node/test/exocomp/node/safety/approval_gate_test.exs (1 new security test for nil fallback)

Current recovery branch state:
  - epic-EXOCOMP-110 HEAD is c958c8f (after EXOCOMP-111 and EXOCOMP-112 recoveries)
  - EXOCOMP-33's parent (261a547 = EXOCOMP-32) IS already in the recovery branch log — cherry-pick should apply cleanly
  - EXOCOMP-28's parent is epic-EXOCOMP-3 (different ancestry) — cherry-pick the single deliverable commit 27f5c5e; the 3 touched files are likely absent on the recovery branch so conflicts should be minimal

Recovery commands to attempt:
  git cherry-pick 47fbb61  # EXOCOMP-33 (parent already in branch)
  git cherry-pick 27f5c5e  # EXOCOMP-28 (standalone M3 test commit)

3. REMAINING WORK AND RISKS:
  - Cherry-pick both commits, resolve any semantic conflicts
  - vacuum_bounds.ex exists in main (EXOCOMP-85 introduced it) — check if fix is already present
  - privilege_test.exs exists in main — check if rootless fix was already applied
  - state_machine.ex exists in main (EXOCOMP-30 introduced it) — the restore/5 security patch may conflict if main modified it
  - approval_gate.ex exists in main (EXOCOMP-98 introduced it) — the nil-fallback fix may conflict
  - After integration: run make test (or scoped mix test for affected apps), verify all 8 M3 acceptance tests and 29 fault-injection tests pass
  - Risk: existing tests in state_machine_test.exs and approval_gate_test.exs may conflict with new security tests if the test count has changed

4. RECOMMENDED NEXT FOCUS: chore (git cherry-pick recovery, conflict resolution, quality gate verification)
---
author: oompah
created: 2026-07-25 18:56
---
Agent completed successfully in 139s (6562 tokens)
---
author: oompah
created: 2026-07-25 18:56
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 31, Tool calls: 21
- Tokens: 17 in / 6.5K out [6.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 19s
- Log: EXOCOMP-113__20260725T185345Z.jsonl
---
author: oompah
created: 2026-07-25 18:56
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-25 18:56
---
Agent dispatched (profile: quick)
---
author: oompah
created: 2026-07-25 18:56
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-25 18:56
---
Understanding: Recover EXOCOMP-28 commit 27f5c5e and EXOCOMP-33 commit 47fbb61 onto the current EXOCOMP-113 branch, reconcile their M3 acceptance/fault-injection tests and state-restore/approval-gate fixes with later main changes, then run focused and full Make quality gates before committing, pushing, and closing the task.
---
<!-- COMMENTS:END -->
