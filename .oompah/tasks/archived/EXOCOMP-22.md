---
id: EXOCOMP-22
type: feature
status: Archived
priority: 1
title: Implement deterministic least-impact policy selection
parent: EXOCOMP-3
children:
- EXOCOMP-73
- EXOCOMP-74
blocked_by:
- EXOCOMP-21
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:10:08.344504Z'
updated_at: '2026-08-01T03:26:28.960011Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 39dc6ceb-c47b-45d4-96f0-493c1a9a4288
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 2629682
  total_output_tokens: 18317
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 2629682
      output_tokens: 18317
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 698111
    output_tokens: 2886
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:14:50.632593+00:00'
  - profile: standard
    model: unknown
    input_tokens: 454739
    output_tokens: 2963
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:16:30.350033+00:00'
  - profile: deep
    model: unknown
    input_tokens: 478089
    output_tokens: 2859
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:18:25.652836+00:00'
  - profile: default
    model: unknown
    input_tokens: 41
    output_tokens: 1177
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:28:41.044506+00:00'
  - profile: standard
    model: unknown
    input_tokens: 586736
    output_tokens: 3726
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:31:14.487337+00:00'
  - profile: deep
    model: unknown
    input_tokens: 411911
    output_tokens: 2930
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:32:57.786689+00:00'
  - profile: standard
    model: unknown
    input_tokens: 55
    output_tokens: 1776
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:51:30.555284+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-6c5f817061cb: '2026-08-01T03:26:26.367892+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-22
    target_state: Archived
    evidence_fingerprint: b6a4a41590fe075b9751c0a2880d8b0a6fbf63f9cb5282366f441369e61cb7dd
    audit_ids:
    - audit-8e35626a9ac2
    kind: result
    applied: true
    retired_at: '2026-08-01T03:26:26.367902+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-22
    audit_id: audit-8e35626a9ac2
    attempt_id: attempt-6c5f817061cb
    target_state: Archived
    evidence_fingerprint: b6a4a41590fe075b9751c0a2880d8b0a6fbf63f9cb5282366f441369e61cb7dd
    status: Archived
    audit_ids:
    - audit-8e35626a9ac2
    applied: false
    created_at: '2026-08-01T03:26:26.367918+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-8e35626a9ac2
    project_id: proj-c260b117
    task_id: EXOCOMP-22
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b6a4a41590fe075b9751c0a2880d8b0a6fbf63f9cb5282366f441369e61cb7dd
    attempts:
    - version: 1
      attempt_id: attempt-6c5f817061cb
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: b6a4a41590fe075b9751c0a2880d8b0a6fbf63f9cb5282366f441369e61cb7dd
      created_at: '2026-08-01T03:23:46.904494+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T03:23:46.904494+00:00'
      branch_key: epic-EXOCOMP-3
      verdict: pass
      completed_at: '2026-08-01T03:26:26.367736+00:00'
      ended_at: '2026-08-01T03:26:26.367736+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-01T02:59:45.197132+00:00'
    updated_at: '2026-08-01T03:26:26.367736+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-6c5f817061cb
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: b6a4a41590fe075b9751c0a2880d8b0a6fbf63f9cb5282366f441369e61cb7dd
    created_at: '2026-08-01T03:23:46.904494+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T03:23:46.904494+00:00'
    branch_key: epic-EXOCOMP-3
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Implement deterministic least-impact policy selection.

Implementation
Filter unauthorized, unsafe, stale, inapplicable, cooldown, and retry-exhausted actions; produce deny/allow/approval_required decisions; order eligible actions lexicographically by data loss, work loss, disruption, and scope; require proof before escalation.

Testing
Use table/property tests for stable ordering, ties, stale evidence, validator errors, unavailable policy, safer remaining candidates, and deterministic repeated evaluation.

Acceptance Criteria
- [ ] Validator ambiguity or error fails closed.
- [ ] A higher-impact action cannot win while a safer eligible action remains.
- [ ] Decisions include auditable reasons and ordering evidence.
- [ ] Repeated inputs produce the same decision.
- [ ] Focused policy tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 22:13
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:13
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:14
---
Agent completed successfully in 92s (700997 tokens)
---
author: oompah
created: 2026-07-23 22:14
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 11
- Tokens: 698.1K in / 2.9K out [701.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 32s
- Log: EXOCOMP-22__20260723T221321Z.jsonl
---
author: oompah
created: 2026-07-23 22:14
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-3`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 22:15
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:15
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:16
---
Agent completed successfully in 82s (457702 tokens)
---
author: oompah
created: 2026-07-23 22:16
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 8
- Tokens: 454.7K in / 3.0K out [457.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 22s
- Log: EXOCOMP-22__20260723T221510Z.jsonl
---
author: oompah
created: 2026-07-23 22:16
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-3`. Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
author: oompah
created: 2026-07-23 22:16
---
Retrying (attempt #2, agent: deep)
---
author: oompah
created: 2026-07-23 22:16
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:18
---
Agent completed successfully in 91s (480948 tokens)
---
author: oompah
created: 2026-07-23 22:18
---
Run #3 [attempt=3, profile=deep, role=deep -> Codex/default]
- Turns: 1, Tool calls: 15
- Tokens: 478.1K in / 2.9K out [480.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 31s
- Log: EXOCOMP-22__20260723T221657Z.jsonl
---
author: oompah
created: 2026-07-23 22:18
---
Agent completed 3 times without closing this issue. Human action required: review the agent run history and task state, then either close the task if the work is done or add specific guidance and move it back to Open.
---
author: oompah
created: 2026-07-23 22:26
---
[watchdog:stalled_task] Stalled-task watchdog audit (run #7)

**State audited:** `Needs Human`
**Classification:** `actionable`
**Action:** `reopen`
**Evidence:** Last agent comment signals completion without a human question; the Needs Human transition appears accidental.

*This comment is posted automatically by the oompah stalled-task watchdog. No human action required unless the classification above is incorrect.*
---
author: oompah
created: 2026-07-23 22:27
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:27
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:28
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 27
- Tokens: 41 in / 1.2K out [1.2K total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 25s
- Log: EXOCOMP-22__20260723T222718Z.jsonl
---
author: oompah
created: 2026-07-23 22:28
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:28
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:31
---
Agent completed successfully in 139s (590462 tokens)
---
author: oompah
created: 2026-07-23 22:31
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 16
- Tokens: 586.7K in / 3.7K out [590.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 19s
- Log: EXOCOMP-22__20260723T222856Z.jsonl
---
author: oompah
created: 2026-07-23 22:31
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-3`. Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
author: oompah
created: 2026-07-23 22:31
---
Retrying (attempt #2, agent: deep)
---
author: oompah
created: 2026-07-23 22:31
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:32
---
Agent completed successfully in 77s (414841 tokens)
---
author: oompah
created: 2026-07-23 22:33
---
Run #3 [attempt=3, profile=deep, role=deep -> Codex/default]
- Turns: 1, Tool calls: 7
- Tokens: 411.9K in / 2.9K out [414.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 17s
- Log: EXOCOMP-22__20260723T223142Z.jsonl
---
author: oompah
created: 2026-07-23 22:33
---
Agent completed 3 times without closing this issue. Human action required: review the agent run history and task state, then either close the task if the work is done or add specific guidance and move it back to Open.
---
author: oompah
created: 2026-07-23 22:35
---
Duplicate screening is complete: EXOCOMP-22 is not a duplicate. EXOCOMP-21 provides prerequisite types, while EXOCOMP-25/26/27/31 cover execution, cleanup, lifecycle integration, and recovery. Implement EXOCOMP-22's deterministic least-impact policy selection on the parent shared branch epic-EXOCOMP-3: fail closed on ambiguity, filter ineligible actions, select lexicographically by data loss/work loss/disruption/scope, and add focused tests for ordering and escalation safety. Do not open a child PR directly to main.
---
author: oompah
created: 2026-07-23 22:35
---
Resolved erroneous Needs Human escalation: duplicate screen is complete and the task is requeued for feature implementation.
---
author: oompah
created: 2026-07-23 22:47
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:47
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 22:50
---
Understanding (Epic Planner): EXOCOMP-22 implements deterministic least-impact policy selection for the M3 safety engine. It depends on EXOCOMP-21 (type system: Done, on branch origin/EXOCOMP-21) and sits alongside EXOCOMP-25 (executor: Done, on origin/EXOCOMP-25). No policy engine code exists yet — the branch is on epic-EXOCOMP-3 with no local commits. The scope is: (1) filtering ineligible actions from the proposal/catalog pair, (2) risk-ranking the eligible set and selecting the lowest-impact candidate, (3) producing auditable deny/allow/approval_required decisions, and (4) comprehensive table/property tests for ordering, ties, stale evidence, fail-closed errors, escalation prevention, and determinism. I will decompose into two focused child tasks: one for the eligibility-filter pipeline and one for the risk-ordered selection engine and tests.
---
author: oompah
created: 2026-07-23 22:51
---
Run #1 [attempt=1, profile=standard, role=standard -> Claude/default]
- Turns: 0, Tool calls: 35
- Tokens: 55 in / 1.8K out [1.8K total]
- Cost: $0.0000
- Exit: terminated, Duration: 3m 57s
- Log: EXOCOMP-22__20260723T224737Z.jsonl
---
author: oompah
created: 2026-08-01 02:59
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-08-01 03:23
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 03:23
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-01 03:26
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- impl_commits: 91a3c41 (EXOCOMP-73 filter), 6e48177 (EXOCOMP-74 selection)
- impl_files: apps/exocomp_node/lib/exocomp/node/safety/policy_engine.ex, risk_rank.ex, policy_context.ex
- test_files: policy_engine_test.exs, policy_engine_filter_test.exs, policy_context_test.exs, integration/m3_acceptance_test.exs
- prior_state: Merged
- aging_reason: Aged Merged auto-archive (closed 7 days ago)
- acceptance_coverage: fail-closed, non-escalation, auditable reasons, determinism (100x), all verified in policy_engine_test.exs and M3-CRIT-2
---
<!-- COMMENTS:END -->
