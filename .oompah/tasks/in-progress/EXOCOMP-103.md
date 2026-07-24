---
id: EXOCOMP-103
type: feature
status: In Progress
priority: 1
title: Audit every correlated diagnostic task transition
parent: EXOCOMP-18
children: []
blocked_by:
- EXOCOMP-102
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T04:29:52.079956Z'
updated_at: '2026-07-24T17:36:19.253387Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 828ca41c-01f5-4f7b-bfa8-3d026c8adbbd
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 516517
  total_output_tokens: 3204
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 516517
      output_tokens: 3204
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 516517
    output_tokens: 3204
    cost_usd: 0.0
    recorded_at: '2026-07-24T17:36:06.236135+00:00'
---
## Summary

Integrate orchestration with the durable EXOCOMP-14 audit sink. Emit structured events for goal accepted/deduplicated, downstream dispatch and state changes, node result/failure/timeout, cancellation request/outcome, cluster completion, eviction, and recovery/resubmission decisions. Every event must carry the cluster correlation ID plus relevant downstream/node identifiers, recursively redact credentials and diagnostic secrets, and preserve diagnostic read availability with a local degraded-health signal when the audit sink is unavailable, consistent with the Milestone 2 audit policy. Add tests for event ordering/correlation, recursive redaction, sink write failures, degraded signaling, and recovery after sink availability returns.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 17:34
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 17:34
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 17:34
---
Understanding: Screening EXOCOMP-103 for duplication before any implementation. I will search existing tasks and project docs for correlated diagnostic audit/event-sink work, inspect plausible task descriptions and comments in full, then either archive as duplicate or hand off with evidence.
---
author: oompah
created: 2026-07-24 17:35
---
Discovery: No confirmed duplicate. Full tracker-state search found the closest tasks are EXOCOMP-14, EXOCOMP-90, EXOCOMP-104, EXOCOMP-105, and parent EXOCOMP-18. EXOCOMP-14 implements the generic durable JSON-lines audit sink, recursive redaction, outage degradation, and retry; it deliberately leaves orchestration-specific events to EXOCOMP-18. EXOCOMP-90 audits poll/registry transitions only. EXOCOMP-104 consumes bounded audit context for restart reconstruction, while EXOCOMP-105 verifies the integrated behavior. EXOCOMP-103 is the intentionally decomposed child uniquely responsible for emitting ordered, correlated events for every diagnostic-orchestrator lifecycle transition.
---
author: oompah
created: 2026-07-24 17:35
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no duplicate; EXOCOMP-103 should proceed to feature implementation. No repository files were changed.

Evidence and decisions: Searched the complete tracker state branch plus plans/docs for audit sink, correlation, diagnostic transitions, redaction, outage, recovery, and resubmission terms. Read full tracker records for EXOCOMP-14, EXOCOMP-18, EXOCOMP-90, EXOCOMP-104, EXOCOMP-105, and EXOCOMP-33. EXOCOMP-14 supplies the generic sink/redaction/health foundation; EXOCOMP-90 covers poll state only; EXOCOMP-104 owns restart reconstruction; EXOCOMP-105 owns integration verification; EXOCOMP-33 is Milestone 4 state-changing recovery testing. Parent EXOCOMP-18 intentionally created EXOCOMP-103 as its dedicated orchestration-audit child after EXOCOMP-102.

Relevant files: plans/milestone-2-coordinator.md (Coordinator Task Flow and Audit policy); apps/exocomp_coordinator/lib/exocomp/coordinator/audit.ex; health.ex; orchestrator.ex; goal_store.ex; diagnostic_goal.ex; node_outcome.ex; and their coordinator tests. The current checkout is epic-EXOCOMP-18 despite dispatch text naming epic-EXOCOMP-2.

Remaining work/risks: Instrument goal acceptance/deduplication, dispatch/state changes, node result/failure/timeout, cancellation request/outcomes, completion, eviction, and recovery/resubmission decisions with stable ordering and cluster/downstream/node identifiers. Reuse recursive redaction at the Audit boundary; diagnostic reads must remain available during sink failure while Health reports local degradation and clears it after recovery. Add focused ordering/correlation, secret-redaction, write-failure/degraded-health, and sink-recovery tests. Coordinate recovery event ownership with EXOCOMP-104 and avoid treating audit durability as a database.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 17:36
---
Agent completed successfully in 100s (519721 tokens)
---
author: oompah
created: 2026-07-24 17:36
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 26
- Tokens: 516.5K in / 3.2K out [519.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 40s
- Log: EXOCOMP-103__20260724T173430Z.jsonl
---
author: oompah
created: 2026-07-24 17:36
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 17:36
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 17:36
---
Focus: Software Engineer
---
<!-- COMMENTS:END -->
