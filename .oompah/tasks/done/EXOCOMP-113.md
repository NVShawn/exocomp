---
id: EXOCOMP-113
type: chore
status: Done
priority: 1
title: Recover omitted M3 and M4 acceptance and fault-injection work
parent: EXOCOMP-110
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-25T17:58:22.004834Z'
updated_at: '2026-07-25T19:15:59.950944Z'
work_branch: epic-EXOCOMP-110
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: b57d8882-424c-4441-b71b-c8fc5a7a5ac4
oompah.work_branch: epic-EXOCOMP-110
oompah.task_costs:
  total_input_tokens: 55
  total_output_tokens: 17593
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 55
      output_tokens: 17593
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 17
    output_tokens: 6545
    cost_usd: 0.0
    recorded_at: '2026-07-25T18:56:01.009826+00:00'
  - profile: default
    model: unknown
    input_tokens: 38
    output_tokens: 11048
    cost_usd: 0.0
    recorded_at: '2026-07-25T19:14:08.244302+00:00'
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
author: oompah
created: 2026-07-25 18:56
---
Discovery: The clean worktree is on shared recovery branch epic-EXOCOMP-110 at c958c8f (not a separately named EXOCOMP-113 branch), which matches the issue's requested integration target. Source commits 47fbb61 (5 M4/security files) and 27f5c5e (3 M3 files) are available locally; EXOCOMP-33's parent 261a547 is already in branch history. I will apply both payloads without committing so conflicts can be reconciled into one EXOCOMP-113 commit.
---
author: oompah
created: 2026-07-25 19:03
---
Verification environment hint: the completed EXOCOMP-112 recovery proved the pinned Make gates work through the already-running Podman service. Create an empty ignored/temporary storage config, then run with CONTAINERS_STORAGE_CONF=<that-file>, XDG_RUNTIME_DIR=/home/shedwards/.oompah/tmp/<task>-runtime, DOCKER_HOST=, and CONTAINER_ENGINE='podman --remote --url unix:///run/user/1000/podman/podman.sock'. For make test, also pass _CONTAINER_USER_FLAG=--userns=keep-id. Remove the temporary config/runtime before committing. This passed fmt-check, lint, all 1,487 tests, both release builds, and smoke tests on EXOCOMP-112.
---
author: oompah
created: 2026-07-25 19:04
---
Implementation: Applied both recovery payloads cleanly and formatted the affected Elixir files. Added the M3 CRIT-1..8 acceptance suite and 12-scenario recovery fault-injection suite; hardened StateMachine.restore/5 against unknown target states and from-state mismatches; made ApprovalGate's missing node_id fail closed with nil; retained the /home and /root vacuum-boundary fix and rootless-container privilege test behavior. No unrelated source changes were kept.
---
author: oompah
created: 2026-07-25 19:07
---
Operator handoff: the recovery implementation is staged with no conflicts and 189 focused tests pass. Stop exploring alternate OTP/proot runtimes. Finish verification using the Podman remote-socket command in comment #12 (empty temporary storage config, remote URL, and --userns=keep-id), then commit the staged eight-file recovery, push epic-EXOCOMP-110, and mark Done.
---
author: oompah
created: 2026-07-25 19:08
---
Run #1 [attempt=1, profile=quick, role=fast -> Codex/default]
- Turns: 0, Tool calls: 70
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 11m 52s
- Log: EXOCOMP-113__20260725T185612Z.jsonl
---
author: oompah
created: 2026-07-25 19:08
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 19:08
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-25 19:08
---
Understanding: Previous agent (profile: quick) staged all 8 recovery files but was terminated before committing/pushing. The staged changes include all M3 and M4 deliverables. I am picking up where they left off: run the full Make quality gates via Podman remote socket, commit the staged 8-file payload, push the epic-EXOCOMP-110 branch, and close the task.
---
author: oompah
created: 2026-07-25 19:13
---
Verification: Full make test suite passed via Podman remote socket. Results: 78 (bench) + 192 (exocomp_core) + 478 (exocomp_coordinator) + 816 (exocomp_node) = 1564 passed, 10 excluded. The first run had a parallel-compiler race with stale _build artifacts (pre-existing behavior); second run was clean. Focused run of m3_acceptance_test.exs + fault_injection_test.exs: 73 passed. fmt-check and lint both green. Releases built and smoke tests passed.
---
author: oompah
created: 2026-07-25 19:13
---
Completion: Committed and pushed cad1c28 to epic-EXOCOMP-110. Recovered 8 files from EXOCOMP-28 and EXOCOMP-33: M3 acceptance suite (44 tests, M3-CRIT-1..8), M4 fault-injection suite (29 tests, 12 fault scenarios), StateMachine.restore/5 injection defenses (+3 security tests), ApprovalGate nil-fallback fix (+1 security test), vacuum_bounds bare /home+/root fix, and rootless-Podman privilege test fix. All 1564 tests pass with make test; 73/73 recovered scenario tests pass in focused run. Quality gates: fmt-check, lint, releases, smoke tests all green.
---
author: oompah
created: 2026-07-25 19:13
---
Recovered M3 acceptance suite (44 tests) and M4 fault-injection suite (29 tests) from EXOCOMP-28/EXOCOMP-33 onto epic-EXOCOMP-110. Added StateMachine injection defenses and ApprovalGate nil-fallback fix. All 1564 tests pass.
---
author: oompah
created: 2026-07-25 19:14
---
Agent completed successfully in 362s (11086 tokens)
---
author: oompah
created: 2026-07-25 19:14
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 60, Tool calls: 35
- Tokens: 38 in / 11.0K out [11.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 6m 2s
- Log: EXOCOMP-113__20260725T190808Z.jsonl
---
author: oompah
created: 2026-07-25 19:14
---
Close refused by orchestrator: branch `epic-EXOCOMP-110` has 7 commits not on `main` and no open PR targets `main` from this branch.

Diagnostic:
  Unmerged commits: 7
    cad1c28 EXOCOMP-113: recover M3 acceptance and M4 fault-injection suites from EXOCOMP-28 and EXOCOMP-33
    c958c8f EXOCOMP-56: implement Linux host sampler
    b65ad23 EXOCOMP-53: implement Bench.HostProfile with amd64/arm64 pinned profiles
    2da861a EXOCOMP-111: reconcile recovered A2A dependencies
    d115dd2 EXOCOMP-51: pin A2A 1.0 fixture files and add protocol test suite
    62717d7 EXOCOMP-49: bootstrap Hex in container before mix commands
    d22dff8 EXOCOMP-49: implement A2A JSON codecs and version handling
  Open PRs from this branch: 0
  Merged PRs from this branch: 0

Required: open a PR before closing.
  gh pr create --base main --head epic-EXOCOMP-110 --title "EXOCOMP-113: Recover omitted M3 and M4 acceptance and fault-injection work" --body "..."

Task reopened. Re-dispatch on the next tick will see this comment in its prompt context.
---
author: oompah
created: 2026-07-25 19:14
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 19:14
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-25 19:14
---
Understanding: The recovered M3/M4 implementation is committed at cad1c28, pushed, and fully verified. Closure failed only because epic-EXOCOMP-110 has no open PR to main. I will create that required PR, confirm the branch/PR state, then retry task closure.
---
author: oompah
created: 2026-07-25 19:14
---
Discovery: origin/epic-EXOCOMP-110 is synchronized at cad1c28 and the worktree is clean. GitHub reports no open PR from epic-EXOCOMP-110; this exactly matches the orchestrator's sole closure blocker.
---
author: oompah
created: 2026-07-25 19:15
---
Implementation: Opened PR #13 from epic-EXOCOMP-110 to main for the complete EXOCOMP-110 recovery stack, including EXOCOMP-113 commit cad1c28: https://github.com/NVShawn/exocomp/pull/13
---
author: oompah
created: 2026-07-25 19:15
---
Verification: PR #13 is OPEN, targets main from epic-EXOCOMP-110, points to cad1c28, and GitHub reports it MERGEABLE. The branch remains clean and up to date with origin. Existing verification remains green: 73 focused recovered scenarios; full make test 1,564 passed/10 excluded; fmt-check, lint, releases, and smoke tests passed.
---
author: oompah
created: 2026-07-25 19:15
---
Completion: Delivered and pushed cad1c28 with the recovered M3 acceptance and M4 fault-injection work plus state-restore and approval-gate hardening. Opened required review PR #13 to main; branch is synchronized, clean, and all focused/full quality gates are green.
---
author: oompah
created: 2026-07-25 19:15
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 0, Tool calls: 13
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 40s
- Log: EXOCOMP-113__20260725T191419Z.jsonl
---
author: oompah
created: 2026-07-25 19:15
---
Recovered M3 acceptance and M4 fault-injection suites plus recovery/approval security fixes in cad1c28. All 1,564 tests pass; PR #13 is open to main.
---
<!-- COMMENTS:END -->
