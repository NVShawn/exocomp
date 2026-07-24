---
id: EXOCOMP-104
type: feature
status: In Progress
priority: 1
title: Recover coordinator live state after volatile restart
parent: EXOCOMP-18
children: []
blocked_by:
- EXOCOMP-103
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T04:29:59.527638Z'
updated_at: '2026-07-24T18:03:02.148271Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 7fb6ade8-6dba-41ba-abb8-254d0f72c405
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 514862
  total_output_tokens: 2803
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 514862
      output_tokens: 2803
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 514862
    output_tokens: 2803
    cost_usd: 0.0
    recorded_at: '2026-07-24T18:02:34.279497+00:00'
---
## Summary

Implement startup reconstruction without a database: reload inventory/registry state, identify any recoverable downstream diagnostic tasks from bounded durable audit context where possible, and re-query node A2A task state using deterministic idempotency keys. When volatile cluster history is unavailable, return an explicit unavailable/not-found response and allow the caller to safely resubmit the same logical request without duplicate downstream work. Do not claim recovery that cannot be proven. Document volatile restart behavior, idempotent resubmission, limits, and operator-visible degraded states in docs/. Add restart-focused tests for recovered terminal/live node state, loss of coordinator ETS/process state, node-unavailable recovery, and safe resubmission.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:01
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:01
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 18:01
---
Understanding: screening this restart-recovery feature against existing coordinator recovery/idempotency tasks. I will search task records and project docs, inspect full candidate histories, and either archive only on a confirmed scope match or hand off with evidence; no implementation will be performed in this focus.
---
author: oompah
created: 2026-07-24 18:02
---
Discovery: duplicate screening found no confirmed duplicate. EXOCOMP-18 explicitly decomposes restart reconstruction into EXOCOMP-104 after EXOCOMP-103 and before EXOCOMP-105. Closest reviewed tasks are complementary: EXOCOMP-14 rebuilds inventory/Registry only; EXOCOMP-100 provides volatile coordinator goal state and deterministic downstream keys but not post-restart recovery; EXOCOMP-79 is the node-side bounded task registry; EXOCOMP-90 owns poll scheduling/state transitions; EXOCOMP-103 emits durable lifecycle audit context; EXOCOMP-105 owns final integrated verification. The milestone plan separately requires reloading inventory, probing/re-querying nodes, explicitly reporting unavailable volatile tasks, and safe idempotent resubmission.
---
author: oompah
created: 2026-07-24 18:02
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-104 should proceed to feature implementation. No repository files were changed.

Evidence and decisions: Searched available plans/docs for coordinator restart, reconstruction, idempotent resubmission, and unavailable task behavior; this checkout has no materialized .oompah/tasks directory. Read full tracker descriptions/comments for EXOCOMP-14, EXOCOMP-18, EXOCOMP-79, EXOCOMP-90, EXOCOMP-100, EXOCOMP-103, and EXOCOMP-105. EXOCOMP-104 is the parent epic's deliberately isolated restart-recovery child. Foundations provide inventory/Registry reload, volatile goal semantics and stable downstream keys, node task lookup, polling, and bounded durable audit events, but none implements coordinator reconstruction after loss of ETS/process state. EXOCOMP-105 verifies the assembled system rather than owning this implementation.

Relevant files and decisions: plans/exocomp.md states live coordinator state is reconstructible while correlated audit is durable. plans/milestone-2-coordinator.md states Registry/task state uses ETS, restart reloads inventory and probes nodes, outstanding volatile tasks may be unavailable, and callers may resubmit idempotently. Likely implementation surfaces are apps/exocomp_coordinator/lib/exocomp/coordinator/{application,inventory,registry,audit,goal_store,orchestrator,diagnostic_client}.ex plus focused coordinator tests and user-facing docs/. Do not treat audit as a database or claim reconstruction unless bounded audit evidence and node A2A state prove it.

Remaining work/risks: add startup reconstruction; derive/reuse deterministic downstream idempotency keys; recover provable live/terminal node state by re-query; represent node-unavailable and missing volatile history explicitly; make same logical resubmission safe from duplicate downstream work; document degraded/operator-visible behavior and limits; add restart-focused tests. The actual checkout is epic-EXOCOMP-18, despite dispatch text naming epic-EXOCOMP-2, so the implementation agent should verify branch/prerequisite state before editing.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 18:02
---
Agent completed successfully in 94s (517665 tokens)
---
author: oompah
created: 2026-07-24 18:02
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 13
- Tokens: 514.9K in / 2.8K out [517.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 34s
- Log: EXOCOMP-104__20260724T180103Z.jsonl
---
author: oompah
created: 2026-07-24 18:02
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 18:02
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 18:02
---
Focus: Technical Writer
---
author: oompah
created: 2026-07-24 18:03
---
Understanding: I am the Technical Writer focus for EXOCOMP-104. My job is to document the volatile restart recovery feature in docs/. Based on previous handoff comments, the feature involves: (1) startup reconstruction without a database by reloading inventory/registry ETS state; (2) re-querying node A2A task state using deterministic idempotency keys; (3) explicitly reporting unavailable volatile coordinator history; (4) safe idempotent resubmission. I will explore the codebase to find what has been implemented, then write docs covering volatile restart behavior, idempotent resubmission, limits, and operator-visible degraded states.
---
<!-- COMMENTS:END -->
