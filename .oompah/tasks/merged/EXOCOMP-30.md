---
id: EXOCOMP-30
type: feature
status: Merged
priority: 1
title: Implement the service-recovery state machine
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-18
- EXOCOMP-22
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:10:46.278084Z'
updated_at: '2026-07-25T02:13:28.264002Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: cec7eb02-03e8-40ef-9eac-6f4fcee6c7c4
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 315770
  total_output_tokens: 61713
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 315770
      output_tokens: 61713
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 315727
    output_tokens: 3014
    cost_usd: 0.0
    recorded_at: '2026-07-24T18:25:56.732926+00:00'
  - profile: default
    model: unknown
    input_tokens: 43
    output_tokens: 58699
    cost_usd: 0.0
    recorded_at: '2026-07-24T18:42:25.138080+00:00'
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Implement the service-recovery state machine.

Implementation
Implement observe, diagnose, propose, validate, await approval, execute, verify, cooldown, complete, and escalate states with legal transitions, correlation, cancellation, deadlines, fresh-evidence requirements, one-attempt limit, and durable transition audit.

Testing
Use exhaustive state-transition tests for all legal/illegal events, stale/out-of-order messages, cancellation, timeout, duplicate events, restart restoration, cooldown, and escalation.

Acceptance Criteria
- [ ] Illegal or stale transitions fail without action.
- [ ] Each transition has one correlated audit event.
- [ ] Only validated paths can reach execution.
- [ ] A failed verification cannot autonomously loop to execution.
- [ ] Focused state-machine tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:24
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:24
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 18:24
---
Understanding: screening EXOCOMP-30 for duplication before any implementation. I will search the tracker and Milestone 4 plan for tasks covering the same recovery-state-machine states, transition guards, audit durability, and exhaustive tests; confirmed candidates will be read in full.
---
author: oompah
created: 2026-07-24 18:25
---
Discovery: Duplicate screening found no duplicate. The closest candidate is EXOCOMP-27, which integrates the generic Milestone 3 remediation lifecycle with A2A tasks and audit; it does not define EXOCOMP-30's explicit Milestone 4 service-recovery states, legal event matrix, recovery-episode one-attempt/cooldown rules, restart restoration, or exhaustive transition tests. EXOCOMP-18 supplies coordinator orchestration/audit, EXOCOMP-22 supplies policy decisions, and M4 siblings EXOCOMP-29/31/32/33/34 respectively own the fixture, automatic flow, approval flow, fault testing, and milestone verification.
---
author: oompah
created: 2026-07-24 18:25
---
Focus handoff: duplicate_detector\n\nOutcome: No duplicate confirmed; EXOCOMP-30 is a unique Milestone 4 state-machine implementation task.\n\nEvidence and decisions:\n- Repository search covered service-recovery/state-machine/cooldown/fresh-evidence terms in plans and docs. The checkout has no .oompah/tasks directory, so candidate task records were read through the tracker.\n- Reviewed full records for EXOCOMP-4, EXOCOMP-18, EXOCOMP-21, EXOCOMP-22, EXOCOMP-25 through EXOCOMP-27, and EXOCOMP-29 through EXOCOMP-34.\n- EXOCOMP-27 is the closest candidate but owns generic M3 remediation-to-A2A integration; EXOCOMP-30 owns the explicit M4 recovery state graph and its transition semantics.\n- EXOCOMP-18 and EXOCOMP-22 are prerequisites providing orchestration/audit and policy selection. EXOCOMP-31/32 consume the machine for automatic and approval-required service flows; EXOCOMP-33 fault-tests execution boundaries; EXOCOMP-34 verifies the milestone.\n- Relevant specification: plans/milestone-4-service-recovery.md, especially Recovery State Machine, Minimal-Impact Rules, Concurrency and Idempotency, Failure Behavior, and Test Strategy.\n\nRemaining work and risks: Implement observe, diagnose, propose, validate, awaiting-approval, execute, verify, cooldown, complete, and escalate states with a closed legal event matrix; correlated durable audit per accepted transition; stale/out-of-order/duplicate rejection; cancellation/deadlines; fresh evidence; one execution attempt; restart restoration; and exhaustive focused tests. Preserve a clean boundary with EXOCOMP-27's generic lifecycle layer and interfaces expected by EXOCOMP-31/32.\n\nRecommended next focus: feature.
---
author: oompah
created: 2026-07-24 18:25
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-30 is the unique Milestone 4 recovery-state-machine task.

Evidence: Reviewed the full tracker records for EXOCOMP-4, EXOCOMP-18, EXOCOMP-21, EXOCOMP-22, EXOCOMP-25 through EXOCOMP-27, and EXOCOMP-29 through EXOCOMP-34, plus plans/milestone-4-service-recovery.md. EXOCOMP-27 is closest but owns generic M3 remediation/A2A integration. EXOCOMP-30 uniquely owns the explicit M4 state/event graph, transition guards, one-attempt and cooldown semantics, restoration, and exhaustive transition tests. EXOCOMP-18 and EXOCOMP-22 are prerequisites; EXOCOMP-31 through EXOCOMP-34 consume or verify this machine.

Remaining work and risks: Implement the closed transition matrix, correlation and exactly-one durable audit per accepted transition, cancellation/deadlines, fresh-evidence checks, duplicate/stale rejection, one execution attempt, restart restoration, cooldown/escalation, and focused exhaustive tests. Keep the state-machine boundary distinct from EXOCOMP-27 and compatible with EXOCOMP-31/32.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 18:25
---
Agent completed successfully in 85s (318741 tokens)
---
author: oompah
created: 2026-07-24 18:25
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 25
- Tokens: 315.7K in / 3.0K out [318.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 25s
- Log: EXOCOMP-30__20260724T182435Z.jsonl
---
author: oompah
created: 2026-07-24 18:25
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 18:26
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:26
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-24 18:28
---
Understanding: Implementing the service-recovery state machine for Milestone 4.

The state machine has 10 states: observing, diagnosing, proposed, validating, awaiting_approval, executing, verifying, cooling_down, completed, escalated.

Key requirements:
- Closed legal event matrix; illegal/stale transitions rejected
- One correlated durable audit event per accepted transition
- Fresh evidence requirements (evidence age checked before transitions)
- One execution attempt per recovery episode (no autonomous retry loops)
- Cancellation and deadline support from any non-terminal state
- Restart restoration via persisted audit events
- Exhaustive state-transition tests covering all legal/illegal/stale/duplicate/timeout/cancellation/cooldown/escalation paths

Plan: Create an Elixir umbrella project under apps/exocomp_core with Recovery.StateMachine (pure functional), Recovery.Audit (audit event types/writing), and Recovery.Evidence (freshness). Update Makefile targets for fmt/fmt-check/build/test/lint. Write exhaustive ExUnit tests in apps/exocomp_core/test/.
---
author: oompah
created: 2026-07-24 18:31
---
Discovery: The repository has plans and a stub Makefile but no Elixir source code yet. Need to create the umbrella project and implement the state machine from scratch.

Key design decisions:
- Pure functional state machine (no GenServer) — callers own persistence and I/O
- 10 states: observing, diagnosing, proposed, validating, awaiting_approval, executing, verifying, cooling_down, completed, escalated; plus cancelled terminal state
- Closed legal event matrix with 15 transition rules + universal cancel
- Evidence freshness via collected_at age check (default 300s, injectable for tests)
- Approval expiry check via expires_at field
- Monotonic sequence counter — stale/out-of-order events produce {:error, :already_terminal}
- execution_attempted boolean flag as defense-in-depth against re-entry to :executing
- Restart restoration via restore/5 replaying transition log
- AuditEvent struct produced for every accepted transition, caller must persist before external action

Files: apps/exocomp_core/lib/exocomp/recovery/{evidence,audit_event,state_machine}.ex
Tests: apps/exocomp_core/test/exocomp/recovery/state_machine_test.exs
---
author: oompah
created: 2026-07-24 18:40
---
Implementation: Created the Elixir umbrella project and implemented the service-recovery state machine.

New files:
- apps/exocomp_core/lib/exocomp/recovery/evidence.ex — versioned evidence struct with freshness check (age <= max_evidence_age_seconds)
- apps/exocomp_core/lib/exocomp/recovery/audit_event.ex — durable audit event struct (one per accepted transition)
- apps/exocomp_core/lib/exocomp/recovery/state_machine.ex — the state machine (pure functional)
- apps/exocomp_core/test/exocomp/recovery/state_machine_test.exs — 85 exhaustive tests
- apps/exocomp_core/mix.exs — umbrella app config
- mix.exs — umbrella root
- Makefile — working fmt/fmt-check/build/test/lint/clean targets

Design decisions:
- Pure functional: no GenServer; callers own persistence and I/O
- Closed transition matrix: 15 transition rules + universal cancel; all other combos return {:error, {:illegal_transition, state, event_tag}}
- Evidence freshness checked at every evidence-carrying transition via collected_at age
- Approval token expiry checked via expires_at field
- execution_attempted boolean as defense-in-depth guard against re-entry to :executing
- restore/5 reconstructs machine from transition log for node-restart recovery
- Durable audit event produced per transition; caller must persist BEFORE external action

All 4 Make targets pass: fmt-check, build, test, lint
---
author: oompah
created: 2026-07-24 18:41
---
Verification: All quality gates pass.

make fmt-check  ✓  (mix format --check-formatted)
make build      ✓  (mix compile --warnings-as-errors, 0 warnings)
make test       ✓  (1 doctest + 85 unit tests, 0 failures, 0.5s)
make lint       ✓  (build + fmt-check)

Test suite covers:
- All 15 legal transitions (both happy paths + escalation paths)
- All illegal transition state/event combinations
- Stale evidence (age > max, negative/future age)
- Approval expiry
- Cancellation from all 8 non-terminal states
- Deadline enforcement (past, at boundary, no deadline)
- One-execution-attempt defense-in-depth flag
- Duplicate event rejection
- Restart restoration via restore/5 (full path, partial, empty log, sequence gap, approval path)
- Audit event field correctness (correlation, meta, timestamp, sequence integrity)
- Evidence tracking in machine struct
- Pure-functional guarantee
- Post-terminal event rejection
---
author: oompah
created: 2026-07-24 18:42
---
Completion: Service-recovery state machine implemented, tested, and pushed to epic-EXOCOMP-4 branch.

Delivered:
- Exocomp.Recovery.StateMachine — pure functional state machine with 10 states (+ cancelled), closed event matrix, one audit event per transition, evidence freshness, approval expiry, one-attempt guard, cancellation, deadlines, restart restoration
- Exocomp.Recovery.Evidence — versioned evidence struct with freshness check
- Exocomp.Recovery.AuditEvent — durable audit event struct

Acceptance criteria:
✓ Illegal or stale transitions fail without action
✓ Each transition has one correlated audit event
✓ Only validated paths can reach execution (validating via failed_and_allowed, or awaiting_approval via valid_approval)
✓ A failed verification cannot autonomously loop to execution (verifying → cooling_down → escalated is terminal)
✓ Focused state-machine tests pass (85 tests, 0 failures)

Quality gate: make fmt-check, make build, make test, make lint all pass.
---
author: oompah
created: 2026-07-24 18:42
---
Implemented Exocomp.Recovery.StateMachine with 10 states, closed event matrix, durable audit per transition, evidence freshness, one-attempt limit, cancellation, deadlines, and restart restoration. 85 exhaustive tests, 0 failures. All Makefile quality gates pass.
---
author: oompah
created: 2026-07-24 18:42
---
Agent completed successfully in 977s (58742 tokens)
---
author: oompah
created: 2026-07-24 18:42
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 82, Tool calls: 48
- Tokens: 43 in / 58.7K out [58.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 16m 17s
- Log: EXOCOMP-30__20260724T182610Z.jsonl
---
author: oompah
created: 2026-07-24 18:42
---
Close refused by orchestrator: branch `epic-EXOCOMP-4` has 2 commits not on `main` and no open PR targets `main` from this branch.

Diagnostic:
  Unmerged commits: 2
    a21fb61 EXOCOMP-30: Implement service-recovery state machine
    5096f79 EXOCOMP-29: Add fixture design document and decompose into child tasks
  Open PRs from this branch: 0
  Merged PRs from this branch: 0

Required: open a PR before closing.
  gh pr create --base main --head epic-EXOCOMP-4 --title "EXOCOMP-30: Implement the service-recovery state machine" --body "..."

Task reopened. Re-dispatch on the next tick will see this comment in its prompt context.
---
author: oompah
created: 2026-07-24 18:45
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:45
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-24 18:45
---
Understanding: Resuming the completed EXOCOMP-30 implementation after closure was refused. I will review the committed state machine against the Milestone 4 plan, rerun all affected Makefile quality gates, verify the pushed branch, open the required PR from epic-EXOCOMP-4 to main, then close the task.
---
author: oompah
created: 2026-07-24 18:46
---
Discovery: The committed implementation is present at a21fb61 on clean, pushed branch epic-EXOCOMP-4. StateMachine defines the closed recovery graph and guards; Evidence enforces freshness; AuditEvent carries correlated transition identity; 85 focused tests cover legal/illegal events, deadlines, cancellation, duplicates, restoration, cooldown, and escalation. No PR exists for the branch, which is the sole remaining closure blocker.
---
author: oompah
created: 2026-07-24 18:46
---
Implementation: No additional code changes were necessary. Reviewed the previously committed Exocomp.Recovery.StateMachine, Evidence, AuditEvent, and focused test suite; commit a21fb61 already delivers the requested implementation and the worktree remains clean.
---
author: oompah
created: 2026-07-24 18:46
---
Verification: make fmt-check, make build, make test, and make lint all pass. Test result: 1 doctest and 85 tests, 0 failures.
---
author: oompah
created: 2026-07-24 18:47
---
Completion: Delivered the Milestone 4 service-recovery state machine with its evidence and audit types and 85 focused tests. All affected Make gates pass, branch epic-EXOCOMP-4 is clean and up to date with origin, and review is open as PR #10: https://github.com/NVShawn/exocomp/pull/10
---
author: oompah
created: 2026-07-24 18:47
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 0, Tool calls: 30
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 2m 8s
- Log: EXOCOMP-30__20260724T184523Z.jsonl
---
author: oompah
created: 2026-07-24 18:47
---
Implemented and verified the service-recovery state machine; 85 focused tests pass and PR #10 is open.
---
<!-- COMMENTS:END -->
