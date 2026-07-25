---
id: EXOCOMP-28
type: chore
status: Needs Human
priority: 1
title: Verify M3 safety and remediation controls
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-20
- EXOCOMP-26
- EXOCOMP-27
- EXOCOMP-113
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:10:14.600547Z'
updated_at: '2026-07-25T18:45:21.585901Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 21cc06ac-6de2-466e-9bbf-86abb87b11ef
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 556387
  total_output_tokens: 67008
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 556387
      output_tokens: 67008
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 556290
    output_tokens: 2674
    cost_usd: 0.0
    recorded_at: '2026-07-24T19:30:22.416759+00:00'
  - profile: default
    model: unknown
    input_tokens: 97
    output_tokens: 64334
    cost_usd: 0.0
    recorded_at: '2026-07-24T19:56:40.463513+00:00'
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Verify M3 safety and remediation controls.

Implementation
Run adversarial and integration suites across policy ordering, approvals, replay, privilege separation, failed-service authorization, active-service approval, bounded system cleanup, audit, and data classification; record evidence for every M3 criterion.

Testing
Run all focused tests and repository Make gates; include explicit negative tests for arbitrary commands, paths, services, unknown data, user data, token tampering, and restart replay.

Acceptance Criteria
- [ ] Every M3-CRIT-* item has recorded pass/fail evidence.
- [ ] No test path permits user-data deletion or arbitrary commands.
- [ ] System cleanup stays within fixed bounds under proved need.
- [ ] Automatic versus approval-required service behavior matches policy.
- [ ] All quality gates pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.
## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 19:28
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 19:29
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 19:29
---
Understanding: duplicate-screening only. I will search existing tasks and M3 safety-validation materials for overlapping verification/remediation work, inspect the full descriptions and comments of plausible candidates, then either archive EXOCOMP-28 as a confirmed duplicate or record a duplicate-detector handoff without implementing.
---
author: oompah
created: 2026-07-24 19:30
---
Discovery: duplicate screening found no duplicate. The worktree lacks .oompah/tasks, so I searched the git-backed tracker state plus plans/docs, then reviewed full tracker records for EXOCOMP-3, EXOCOMP-20, EXOCOMP-27, EXOCOMP-34, and EXOCOMP-98. EXOCOMP-98 owns the focused approval/replay gate suite; EXOCOMP-27 owns remediation lifecycle/A2A integration tests; both explicitly identify EXOCOMP-28 as separate broad M3 acceptance verification. EXOCOMP-3 lists EXOCOMP-28 as the final security-acceptance child. EXOCOMP-20 and EXOCOMP-34 are analogous verification tasks for M2 and M4, not M3 duplicates.
---
author: oompah
created: 2026-07-24 19:30
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-28 is the unique cross-cutting Milestone 3 acceptance-verification task.

Evidence and decisions: Repository search covered M3, safety validation, remediation, policy ordering, approvals/replay, privilege separation, bounded cleanup, audit, and data classification in plans/docs and the git-backed tracker state. Full records reviewed: EXOCOMP-3, EXOCOMP-20, EXOCOMP-27, EXOCOMP-34, and EXOCOMP-98. EXOCOMP-27 implements lifecycle/A2A/audit behavior and EXOCOMP-98 implements the focused 15-scenario approval/replay gate; neither records pass/fail evidence for every M3-CRIT item. EXOCOMP-3 deliberately retains EXOCOMP-28 as its security-acceptance child. EXOCOMP-20 and EXOCOMP-34 verify different milestones. Relevant specification: plans/milestone-3-safety-validation.md, especially Test Strategy and M3-CRIT-1 through M3-CRIT-8.

Remaining work and risks: Integrate the completed M3 prerequisite branches into epic-EXOCOMP-3 as needed; build the cross-component adversarial/integration acceptance suite; explicitly cover arbitrary commands/paths/services, unknown and user data, approval tampering, concurrent/sequential/restart replay, failed versus active/degraded services, bounded cleanup, privilege rules, and correlated audit; record criterion-by-criterion evidence and run affected Make gates. Existing task history indicates the epic worktree may lag completed child branches, so confirm integration state first.

Recommended next focus: test. No repository files were changed; quality gates were not applicable to this read-only duplicate screening.
---
author: oompah
created: 2026-07-24 19:30
---
Agent completed successfully in 85s (558964 tokens)
---
author: oompah
created: 2026-07-24 19:30
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 14
- Tokens: 556.3K in / 2.7K out [559.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 25s
- Log: EXOCOMP-28__20260724T192900Z.jsonl
---
author: oompah
created: 2026-07-24 19:30
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 19:30
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 19:30
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 19:30
---
Understanding: As Maintenance Engineer, my role is to run the M3 safety and remediation verification suite and record pass/fail evidence for every M3-CRIT-* criterion. The duplicate_detector confirmed this is the unique broad M3 acceptance-verification task. I will: (1) explore the codebase to find existing M3 tests and the milestone-3-safety-validation plan, (2) run all focused tests and Make gates, (3) record evidence per criterion, and (4) hand off to a test specialist if new test scaffolding is needed. Starting now.
---
author: oompah
created: 2026-07-24 19:33
---
Discovery: The codebase has extensive unit/focused tests covering all M3-CRIT criteria but no cross-cutting m3_acceptance_test.exs. Key findings:

- M3-CRIT-1 (schema/evidence validation): proposal_schema_test.exs, action_definition_test.exs, evidence_test.exs
- M3-CRIT-2 (policy ordering/determinism): policy_engine_test.exs, risk_rank_test.exs, policy_engine_filter_test.exs  
- M3-CRIT-3 (user/unknown data protection): data_classification_test.exs, policy_engine_test.exs
- M3-CRIT-4 (bounded system cleanup): vacuum_bounds_test.exs, disk_pressure_collector_test.exs
- M3-CRIT-5 (failed vs active service auth): policy_engine_test.exs, approval_gate_test.exs
- M3-CRIT-6 (approval tampering/replay): approval_gate_test.exs (15 scenarios from EXOCOMP-98)
- M3-CRIT-7 (privilege separation): privilege_test.exs, sudoers_policy_test.exs, executor_test.exs
- M3-CRIT-8 (audit trail): approval_gate_test.exs (audit log properties section)

Gap: No m3_acceptance_test.exs that records per-criterion evidence. Pattern from m1_acceptance_test.exs is clear — I will create it with [PASS/FAIL evidence for M3-CRIT-X] markers and run the Make gates.
---
author: oompah
created: 2026-07-24 19:49
---
Implementation: Created apps/exocomp_node/test/integration/m3_acceptance_test.exs (53174 bytes) — comprehensive M3 acceptance suite with 8 describe blocks mapping to M3-CRIT-1 through M3-CRIT-8. Each test carries # [PASS/FAIL evidence for M3-CRIT-X] markers following the M1 pattern. Tests cover all required adversarial cases: injection, stale evidence, schema mismatches, policy ordering determinism, user-data deletion blocked at type AND policy level, VacuumBounds eligibility/source rejection, service approval/automatic behavior, token tampering/replay/expiry/binding mismatch, privilege separation, argv enforcement, and audit trail coverage. Running make test revealed 3 failures to fix: (1) VacuumBounds.user_data_path?/1 missing exact match for /home and /root bare paths, (2) M3-CRIT-7a test flunks in rootless Podman where UID=0 inside container, (3) pre-existing PrivilegeTest check_not_root/0 has same rootless issue. Applying targeted fixes to all three now.
---
author: oompah
created: 2026-07-24 19:56
---
Verification: make test passes cleanly — 761 ExUnit tests passed, 10 excluded (systemd/integration), 0 failures. Releases smoke-tested successfully with bundled musl ERTS inside the Alpine container.

Three issues were found and fixed during testing:
1. VacuumBounds.user_data_path?/1 did not match bare /home or /root paths (only /home/... sub-paths). Fixed — M3-CRIT-4e now correctly records :user_data_path for all user directory roots.
2. M3-CRIT-7a flunked in rootless Podman (kernel maps host UID to 0 inside the container namespace). Fixed to branch on actual UID, consistent with the check_not_root!/0 test already in the file.
3. PrivilegeTest check_not_root/0 had the same pre-existing rootless-Podman issue. Fixed with the same branching strategy.

All M3-CRIT acceptance evidence is now recorded in the test file comments.
---
author: oompah
created: 2026-07-24 19:56
---
Completion: EXOCOMP-28 is done.

Delivered:
- apps/exocomp_node/test/integration/m3_acceptance_test.exs — 1493 lines, 8 describe blocks (one per M3-CRIT), 44 tests total. Every test carries a # [PASS/FAIL evidence for M3-CRIT-X] marker following the M1 acceptance test pattern.
- apps/exocomp_node/lib/exocomp/node/vacuum_bounds.ex — user_data_path?/1 now matches bare /home and /root (previously only subdirectory paths with trailing slash were matched; M3-CRIT-4e defense-in-depth tightened).
- apps/exocomp_node/test/exocomp/node/privilege_test.exs — pre-existing rootless-Podman failure resolved; test now branches on actual UID rather than unconditionally asserting :ok.

Acceptance criteria status:
  [PASS] Every M3-CRIT-1 through M3-CRIT-8 item has recorded pass/fail evidence.
  [PASS] No test path permits user-data deletion or arbitrary commands (M3-CRIT-3, M3-CRIT-7).
  [PASS] System cleanup stays within fixed bounds under proved need (M3-CRIT-4).
  [PASS] Automatic vs approval-required service behavior matches policy (M3-CRIT-5).
  [PASS] All quality gates pass — 761/761 ExUnit tests, releases smoke-passed.

Branch: EXOCOMP-28, commit 27f5c5e
---
author: oompah
created: 2026-07-24 19:56
---
Created m3_acceptance_test.exs with per-criterion pass/fail evidence for M3-CRIT-1 through M3-CRIT-8 (44 tests, 1493 lines). Fixed VacuumBounds bare /home /root detection. Fixed PrivilegeTest rootless-Podman compatibility. All 761 tests pass; make test exits 0.
---
author: oompah
created: 2026-07-24 19:56
---
Agent completed successfully in 1564s (64431 tokens)
---
author: oompah
created: 2026-07-24 19:56
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 189, Tool calls: 127
- Tokens: 97 in / 64.3K out [64.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 26m 4s
- Log: EXOCOMP-28__20260724T193037Z.jsonl
---
author: oompah
created: 2026-07-25 18:30
---
Action required: use recovery task EXOCOMP-113 to integrate and verify this task's omitted deliverables on main. Do not mark this task Merged again until EXOCOMP-113 lands and its acceptance criteria are confirmed against main.
---
author: oompah
created: 2026-07-25 18:30
---
Moved to Needs Human from the dashboard/API. Human action required: inspect EXOCOMP-28 (Verify M3 safety and remediation controls), add the specific decision, missing information, or manual fix needed, then move the task back to Open when it is ready for agents again.
---
author: oompah
created: 2026-07-25 18:31
---
The parent epic EXOCOMP-3 merged from epic-EXOCOMP-3, but this task was Needs Human with work branch epic-EXOCOMP-3. Its work is not proven to be in the merged epic. Inspect the task's agent history and remote branches, recover any missing commits through a new recovery epic or approved follow-up PR, then move this task to Done only after the recovered work is verified on the target branch.
---
author: oompah
created: 2026-07-25 18:33
---
The parent epic EXOCOMP-3 merged from epic-EXOCOMP-3, but this task was Needs Human with work branch epic-EXOCOMP-3. Its work is not proven to be in the merged epic. Inspect the task's agent history and remote branches, recover any missing commits through a new recovery epic or approved follow-up PR, then move this task to Done only after the recovered work is verified on the target branch.
---
author: oompah
created: 2026-07-25 18:38
---
The parent epic EXOCOMP-3 merged from epic-EXOCOMP-3, but this task was Needs Human with work branch epic-EXOCOMP-3. Its work is not proven to be in the merged epic. Inspect the task's agent history and remote branches, recover any missing commits through a new recovery epic or approved follow-up PR, then move this task to Done only after the recovered work is verified on the target branch.
---
author: oompah
created: 2026-07-25 18:43
---
The parent epic EXOCOMP-3 merged from epic-EXOCOMP-3, but this task was Needs Human with work branch epic-EXOCOMP-3. Its work is not proven to be in the merged epic. Inspect the task's agent history and remote branches, recover any missing commits through a new recovery epic or approved follow-up PR, then move this task to Done only after the recovered work is verified on the target branch.
---
author: oompah
created: 2026-07-25 18:45
---
The parent epic EXOCOMP-3 merged from epic-EXOCOMP-3, but this task was Needs Human with work branch epic-EXOCOMP-3. Its work is not proven to be in the merged epic. Inspect the task's agent history and remote branches, recover any missing commits through a new recovery epic or approved follow-up PR, then move this task to Done only after the recovered work is verified on the target branch.
---
<!-- COMMENTS:END -->
