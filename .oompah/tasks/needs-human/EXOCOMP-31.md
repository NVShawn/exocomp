---
id: EXOCOMP-31
type: feature
status: Needs Human
priority: 0
title: Implement automatic recovery of an already-failed service
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-25
- EXOCOMP-27
- EXOCOMP-29
- EXOCOMP-30
- EXOCOMP-115
labels:
- focus-complete:duplicate_detector
- merge-conflict
- focus-complete:merge_conflict
assignee: null
created_at: '2026-07-23T19:10:47.061070Z'
updated_at: '2026-07-25T18:38:55.770660Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 49d23404-bdf9-433e-ad51-b2fbcff4b2bb
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 577941
  total_output_tokens: 6914
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 577941
      output_tokens: 6914
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 577810
    output_tokens: 3291
    cost_usd: 0.0
    recorded_at: '2026-07-25T02:04:23.281584+00:00'
  - profile: standard
    model: unknown
    input_tokens: 131
    output_tokens: 3623
    cost_usd: 0.0
    recorded_at: '2026-07-25T02:14:14.280723+00:00'
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Implement automatic recovery of an already-failed service.

Implementation
Connect fresh service evidence, structured restart proposal, deterministic policy, audit-before-action, exact executor, systemd verification, application health check, stability window, terminal artifact, and one-attempt cooldown for a failed allow-listed service.

Testing
Test happy path, service self-recovers before execution, state changes to active/degraded, restart command failure, active-but-unhealthy result, health timeout, audit failure, and stable completion.

Acceptance Criteria
- [ ] Only a currently inactive/failed allow-listed service restarts automatically.
- [ ] Exactly one restart occurs per recovery episode.
- [ ] Success requires systemd plus application health stability.
- [ ] Failure enters cooldown/escalation with complete audit.
- [ ] Focused recovery tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 02:02
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 02:02
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-25 02:02
---
Understanding: duplicate-detector screening only. I will search existing tasks and Milestone 4 design material for service-recovery/restart work, inspect the full descriptions and comments of plausible matches, and either archive EXOCOMP-31 as a confirmed duplicate or hand it off for implementation if no duplicate is established. No code changes will be made in this focus.
---
author: oompah
created: 2026-07-25 02:03
---
Discovery: Duplicate screening found no confirmed duplicate. The closest reviewed tasks are EXOCOMP-30 (generic M4 recovery state machine and invariants), EXOCOMP-32 (approval-required active/degraded service flow), EXOCOMP-27 (generic remediation/A2A lifecycle), and EXOCOMP-33 (fault/idempotency test coverage). Their full descriptions and comments establish prerequisite or sibling boundaries: none implements the automatic orchestration for a currently inactive/failed allow-listed service, including fresh evidence, deterministic allow decision, audit-before-restart, exact execution, systemd plus application-health stability verification, terminal artifact, and one-attempt cooldown.
---
author: oompah
created: 2026-07-25 02:04
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-31 is the distinct Milestone 4 automatic recovery flow for an already-failed service and should proceed to implementation.

Evidence and decisions: The checkout has no .oompah/tasks directory, so I searched plans/docs locally and searched tracker Markdown on origin/oompah/state/proj-c260b117. I then read the full tracker records for EXOCOMP-30, EXOCOMP-32, EXOCOMP-27, EXOCOMP-33, and parent EXOCOMP-4. EXOCOMP-30 provides the pure recovery state machine; EXOCOMP-27 provides generic proposal/policy/audit lifecycle infrastructure; EXOCOMP-32 implements only approval-required active/degraded recovery and explicitly escalates without action when evidence becomes failed; EXOCOMP-33 owns broader failure/idempotency testing; EXOCOMP-4 intentionally lists EXOCOMP-31 as a separate child. Relevant specification and fixture expectations are in plans/milestone-4-service-recovery.md and docs/testing-systemd-fixture.md.

Remaining work and risks: Implement the service-specific automatic path for currently inactive/failed allow-listed evidence, reuse the existing state machine/policy/executor/audit boundaries, refresh evidence immediately before the one permitted restart, require both systemd and application-health stability, emit complete terminal audit/artifacts, and enter cooldown/escalation on every failure without retry. Cover happy path, self-recovery/state drift before execution, command failure, unhealthy/timeout verification, audit failure, and stable completion.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-25 02:04
---
Agent completed successfully in 113s (581101 tokens)
---
author: oompah
created: 2026-07-25 02:04
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 17
- Tokens: 577.8K in / 3.3K out [581.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 53s
- Log: EXOCOMP-31__20260725T020234Z.jsonl
---
author: oompah
created: 2026-07-25 02:04
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-25 02:05
---
YOLO: Merge conflict detected on MR #10. Rebase onto main and resolve conflicts.
---
author: oompah
created: 2026-07-25 02:05
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-25 02:05
---
Focus: Merge Conflict Resolver
---
author: oompah
created: 2026-07-25 02:06
---
Understanding: merge-conflict resolution only. I will fetch and rebase the existing EXOCOMP-31 commits onto origin/main, inspect both sides of every conflict to preserve branch intent and upstream changes, run the applicable Makefile quality gate, force-push with lease, and verify the rebased review diff. I will not add feature work or unrelated fixes.
---
author: oompah
created: 2026-07-25 02:06
---
Run #YOLO-reopen [attempt=YOLO-reopen, profile=standard, role=standard -> Codex/default]
- Turns: 0, Tool calls: 4
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 49s
- Log: EXOCOMP-31__20260725T020600Z.jsonl
---
author: oompah
created: 2026-07-25 02:06
---
Discovery: MR #10's actual source ref is the checked-out epic-EXOCOMP-4 branch (refs/pull/10/head exactly matches HEAD); no EXOCOMP-31 branch exists locally or remotely. The required rebase onto origin/main is underway. The first conflict is apps/exocomp_coordinator/mix.exs: the replayed approval-token commit adds Jason while upstream main already contains Jason plus Bandit/Plug/X509, so resolution must retain the upstream superset and the branch's Jason requirement.
---
author: oompah
created: 2026-07-25 02:07
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-25 02:07
---
Focus: Merge Conflict Resolver
---
author: oompah
created: 2026-07-25 02:07
---
Understanding: Merge conflict resolver focus. The rebase of epic-EXOCOMP-4 onto origin/main is already in progress (8 of 16 commits done). One remaining conflict in apps/exocomp_node/lib/exocomp/node/application.ex: HEAD (EXOCOMP-25 executor commit) added {ExecutorLock, name: ExecutorLock} to the supervisor children, while the incoming EXOCOMP-97 commit (durable replay ledger) added Exocomp.Node.Safety.ReplayLedger. Resolution: include both in the children list, then continue the rebase through remaining commits.
---
author: oompah
created: 2026-07-25 02:08
---
Implementation: completed the rebase onto origin/main without dropping or squashing branch commits. Resolved conflicts in coordinator mix dependencies, node Application supervision, config/config.exs, and coordinator Application supervision by preserving both sides: upstream networking/PKI/task services remain, while branch Jason usage, ExecutorLock, ReplayLedger, VacuumState, replay-ledger config, and RemediationLifecycle are retained.
---
author: oompah
created: 2026-07-25 02:12
---
Verification (pre-push): rebase completed; git diff --check passes and no conflict markers remain. The prescribed make fmt-check/test gates could not execute because Podman cannot write its fixed /run/user/1000/libpod runtime path in this managed session. Local fallback is also unavailable: host Elixir is 1.18.3 while the project requires 1.20.2, and the user temp-storage quota prevents unpacking the official temporary 1.20.2 toolchain. No test failure was observed; execution was blocked by tooling before tests ran.
---
author: oompah
created: 2026-07-25 02:14
---
Run #YOLO-reopen [attempt=YOLO-reopen, profile=standard, role=standard -> Claude/default]
- Turns: 0, Tool calls: 82
- Tokens: 131 in / 3.6K out [3.8K total]
- Cost: $0.0000
- Exit: terminated, Duration: 7m 9s
- Log: EXOCOMP-31__20260725T020709Z.jsonl
---
author: oompah
created: 2026-07-25 02:14
---
Verification: final pushed review head 261a547 exactly matched refs/pull/10/head. After the force-push, GitHub merged PR #10 as 725120a; its second parent is exactly 261a547 and the review branch is now fully contained in origin/main. The final parent-to-parent diff passes git diff --check, has no conflict markers, and every changed .ex/.exs file parses successfully. Full Make tests remained environment-blocked as previously recorded (Podman read-only runtime; incompatible host Elixir).
---
author: oompah
created: 2026-07-25 02:14
---
Focus handoff: merge_conflict\n\nOutcome: Rebased MR #10's actual source branch epic-EXOCOMP-4 onto current main, resolved all conflicts while retaining both sides, force-pushed with lease, verified refs/pull/10/head, and confirmed GitHub merged the review as 725120a.\n\nEvidence and decisions: conflict resolutions covered apps/exocomp_coordinator/mix.exs, both OTP Application supervision trees, and config/config.exs. The final merged parent 261a547 retains remediation lifecycle/state-machine/approval-required work; git diff --check, conflict-marker scan, remote SHA verification, and Elixir syntax parsing passed. Make quality gates could not start due the managed Podman runtime path being read-only; local Mix was rejected because host Elixir 1.18.3 does not meet the exact 1.20.2 project requirement.\n\nRemaining work and risks: EXOCOMP-31 automatic recovery itself is not implemented by this merge-conflict focus. A feature agent must implement the already-failed allow-listed service path and focused tests described in the task. Full tests should run in the supported builder/CI environment.\n\nRecommended next focus: feature.
---
author: oompah
created: 2026-07-25 02:14
---
Completion (merge-conflict focus): review branch force-pushed, final review SHA verified, PR #10 merged into main, and focus-complete:merge_conflict recorded. EXOCOMP-31 remains for the feature implementation handoff; no out-of-scope feature changes were made in this session.
---
author: oompah
created: 2026-07-25 18:31
---
Action required: use recovery task EXOCOMP-115 to implement and verify this task's previously undelivered scope on main. Do not mark this task Merged again until EXOCOMP-115 lands and the original acceptance criteria are confirmed against main.
---
author: oompah
created: 2026-07-25 18:31
---
Moved to Needs Human from the dashboard/API. Human action required: inspect EXOCOMP-31 (Implement automatic recovery of an already-failed service), add the specific decision, missing information, or manual fix needed, then move the task back to Open when it is ready for agents again.
---
author: oompah
created: 2026-07-25 18:33
---
The parent epic EXOCOMP-4 merged from epic-EXOCOMP-4, but this task was Needs Human with work branch epic-EXOCOMP-4. Its work is not proven to be in the merged epic. Inspect the task's agent history and remote branches, recover any missing commits through a new recovery epic or approved follow-up PR, then move this task to Done only after the recovered work is verified on the target branch.
---
author: oompah
created: 2026-07-25 18:38
---
The parent epic EXOCOMP-4 merged from epic-EXOCOMP-4, but this task was Needs Human with work branch epic-EXOCOMP-4. Its work is not proven to be in the merged epic. Inspect the task's agent history and remote branches, recover any missing commits through a new recovery epic or approved follow-up PR, then move this task to Done only after the recovered work is verified on the target branch.
---
<!-- COMMENTS:END -->
