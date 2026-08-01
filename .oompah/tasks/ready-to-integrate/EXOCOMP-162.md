---
id: EXOCOMP-162
type: task
status: Ready to Integrate
priority: 1
title: Implement operator approval and denial guards
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-141
- EXOCOMP-161
- EXOCOMP-147
- EXOCOMP-150
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:20.549186Z'
updated_at: '2026-08-01T13:16:29.053846Z'
work_branch: epic-EXOCOMP-132--task-EXOCOMP-162
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 356b414e5aa7c4d128397587c7aef42d5081a00957de9f5d41de745e16330475
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:58:13.958405+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active EXOCOMP-161 (proposal persistence), EXOCOMP-141 (authorization),
    EXOCOMP-150 (command outbox), EXOCOMP-163 (cluster execution), EXOCOMP-169 (UI
    controls), and EXOCOMP-171 (audit events). Their scopes are distinct; none duplicates
    operator approval/denial guards.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 253749ce-28b4-4ff3-b8e3-aa407e89578f
oompah.work_branch: epic-EXOCOMP-132--task-EXOCOMP-162
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: epic-EXOCOMP-132--task-EXOCOMP-162
  head_sha: 3cd1ec79bfcec392c2ee64213e2d634399d21d91
  submitted_at: '2026-08-01T13:16:26.793224+00:00'
  updated_at: '2026-08-01T13:16:26.793224+00:00'
oompah.task_costs:
  total_input_tokens: 785067
  total_output_tokens: 3700
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 785067
      output_tokens: 3700
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 785067
    output_tokens: 3700
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:58:13.957745+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-162__20260801T125643Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-132--task-EXOCOMP-162
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:58:13.970435+00:00'
---
## Summary

Plan: plans/mission-control.md, Typed Remedy Approval.

Deliverables:
- Add operator/admin context functions to approve or deny one pending proposal.
- Reject approval when the cluster is disconnected, proposal expired, evidence freshness elapsed, proposal terminal, or operator lacks role.
- Persist the decision and actor audit fields transactionally, then enqueue one typed approval command.
- Never queue an approval for later when the cluster is offline.

Acceptance:
- Tests cover every guard, duplicate/concurrent decisions, denial reason, queue failure rollback, viewer denial, and organization mismatch.
- An accepted decision is not represented as executed.

Out of scope: local revalidation and LiveView controls.
Quality gate: focused approval tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:56
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:56
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:58
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 19
- Tokens: 785.1K in / 3.7K out [788.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 39s
- Log: EXOCOMP-162__20260801T125643Z.jsonl
---
author: oompah
created: 2026-08-01 12:58
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:58
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 12:58
---
Understanding: implement operator/admin approve and deny context functions for one pending proposal, enforcing connectivity, expiry/freshness, terminal-state, role, and organization guards; persist actor/decision transactionally and enqueue exactly one typed approval command, with rollback on queue failure and no offline queueing.
---
author: oompah
created: 2026-08-01 13:01
---
Discovery: the intended Mission Control boundary is apps/exocomp_mission_control. Dependency commits provide Authorization.authorize/3 (organization + role), CommandOutbox.enqueue/2 (typed allow-list), SessionRegistry ownership for online sessions, and Ecto Repo/migrations. The approval context should compose with these contracts and atomically persist proposal decision plus audit actor fields before enqueueing.
---
author: oompah
created: 2026-08-01 13:14
---
Implementation: added Proposal schema/migration and Approvals context with operator/admin authorization, organization scoping, row-locked pending decisions, expiry/evidence freshness/terminal guards, explicit denial reasons, liveness checks that prevent offline approval writes, actor attribution fields, and transactional typed proposal.approve/proposal.deny outbox insertion. Focused tests cover guards, rollback, duplicate decisions, denial, and accepted-not-executed.
---
author: oompah
created: 2026-08-01 13:15
---
Verification: focused Mission Control tests pass (143 tests, 0 failures) and the app compiles with warnings-as-errors; formatter check and git diff check pass in the local compatibility harness. Required make fmt-check, make lint, and make test reach the pinned Docker builder but are blocked by the host Podman wrapper: read-only /run/user/1000/libpod prevents container startup; offline builder checks themselves pass.
---
author: oompah
created: 2026-08-01 13:16
---
Completion: pushed commit 3cd1ec79 on epic-EXOCOMP-132--task-EXOCOMP-162. Delivered transactional operator/admin proposal approve/deny guards, liveness and freshness fail-closed behavior, actor audit persistence, typed outbox commands, rollback protection, migration, and 143 passing focused Mission Control tests. Ready for oompah submission.
---
author: oompah
created: 2026-08-01 13:16
---
Implemented transactional operator/admin approval and denial guards with typed outbox commands, audit attribution, fail-closed liveness/freshness checks, rollback protection, migration, and focused tests.
---
<!-- COMMENTS:END -->
