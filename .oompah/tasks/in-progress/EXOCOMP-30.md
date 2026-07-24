---
id: EXOCOMP-30
type: feature
status: In Progress
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
updated_at: '2026-07-24T18:26:10.278938Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 1abd3c15-68a9-4065-b1aa-72252bd0272d
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 315727
  total_output_tokens: 3014
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 315727
      output_tokens: 3014
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 315727
    output_tokens: 3014
    cost_usd: 0.0
    recorded_at: '2026-07-24T18:25:56.732926+00:00'
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
<!-- COMMENTS:END -->
