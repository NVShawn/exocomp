---
id: EXOCOMP-90
type: feature
status: In Validation
priority: 1
title: Implement poll scheduling, backoff, and registry state transitions
parent: EXOCOMP-15
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-24T02:43:03.724012Z'
updated_at: '2026-08-01T01:43:46.329808Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 5b537988-9c46-4c92-a27a-d86a2680551b
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 560598
  total_output_tokens: 2923
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 560598
      output_tokens: 2923
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 560598
    output_tokens: 2923
    cost_usd: 0.0
    recorded_at: '2026-07-24T03:05:49.867930+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    no-auditor-audit-478202836c55-3: '2026-07-31T19:59:05.163100+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-90
    target_state: Archived
    evidence_fingerprint: 0345e34e3b5b812463b184e8434eb4e9f889d38a064b937da0f7700d3a435d37
    audit_ids:
    - audit-478202836c55
    kind: result
    applied: true
    retired_at: '2026-07-31T19:59:05.163111+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-90
    audit_id: audit-478202836c55
    attempt_id: no-auditor-audit-478202836c55-3
    target_state: Archived
    evidence_fingerprint: 0345e34e3b5b812463b184e8434eb4e9f889d38a064b937da0f7700d3a435d37
    status: Needs Human
    audit_ids:
    - audit-478202836c55
    applied: true
    created_at: '2026-07-31T19:59:05.163127+00:00'
    applied_at: '2026-07-31T19:59:07.446737+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-478202836c55
    project_id: proj-c260b117
    task_id: EXOCOMP-90
    target_state: Archived
    request_state: superseded
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 0345e34e3b5b812463b184e8434eb4e9f889d38a064b937da0f7700d3a435d37
    attempts:
    - version: 1
      attempt_id: attempt-0bbd4acabe18
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 0345e34e3b5b812463b184e8434eb4e9f889d38a064b937da0f7700d3a435d37
      created_at: '2026-07-31T19:54:16.560727+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-31T19:54:16.560727+00:00'
      branch_key: epic-EXOCOMP-2
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T19:54:24.518531+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T19:54:34.518498+00:00'
    - version: 1
      attempt_id: attempt-f770f5e553b3
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 0345e34e3b5b812463b184e8434eb4e9f889d38a064b937da0f7700d3a435d37
      created_at: '2026-07-31T19:57:18.290095+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-07-31T19:57:18.290095+00:00'
      branch_key: epic-EXOCOMP-2
      candidate_rotation_count: 1
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T19:57:24.179047+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T19:57:44.179022+00:00'
    - version: 1
      attempt_id: attempt-57c7e396f6eb
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 0345e34e3b5b812463b184e8434eb4e9f889d38a064b937da0f7700d3a435d37
      created_at: '2026-07-31T19:58:10.436467+00:00'
      provider_id: prov-651d553c
      model: haiku
      started_at: '2026-07-31T19:58:10.436467+00:00'
      branch_key: epic-EXOCOMP-2
      candidate_rotation_count: 2
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T19:58:15.245794+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
      next_retry_at: '2026-07-31T19:58:55.245770+00:00'
    - version: 1
      attempt_id: no-auditor-audit-478202836c55-3
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 0345e34e3b5b812463b184e8434eb4e9f889d38a064b937da0f7700d3a435d37
      verdict: fail
      failure_classification: no_auditor
      created_at: '2026-07-31T19:59:05.162956+00:00'
      completed_at: '2026-07-31T19:59:05.162956+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-31T19:41:24.805725+00:00'
    updated_at: '2026-08-01T01:43:44.004295+00:00'
  - version: 1
    audit_id: audit-12c708f03f0c
    project_id: proj-c260b117
    task_id: EXOCOMP-90
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 0345e34e3b5b812463b184e8434eb4e9f889d38a064b937da0f7700d3a435d37
    attempts: []
    requested_by:
      version: 1
      identity: oompah-cli
      source: api
    previous_state: Merged
    created_at: '2026-08-01T01:43:44.004295+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-0bbd4acabe18
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 0345e34e3b5b812463b184e8434eb4e9f889d38a064b937da0f7700d3a435d37
    created_at: '2026-07-31T19:54:16.560727+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-31T19:54:16.560727+00:00'
    branch_key: epic-EXOCOMP-2
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T19:54:24.518531+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T19:54:34.518498+00:00'
  - version: 1
    attempt_id: attempt-f770f5e553b3
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 0345e34e3b5b812463b184e8434eb4e9f889d38a064b937da0f7700d3a435d37
    created_at: '2026-07-31T19:57:18.290095+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-07-31T19:57:18.290095+00:00'
    branch_key: epic-EXOCOMP-2
    candidate_rotation_count: 1
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T19:57:24.179047+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T19:57:44.179022+00:00'
  - version: 1
    attempt_id: attempt-57c7e396f6eb
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 0345e34e3b5b812463b184e8434eb4e9f889d38a064b937da0f7700d3a435d37
    created_at: '2026-07-31T19:58:10.436467+00:00'
    provider_id: prov-651d553c
    model: haiku
    started_at: '2026-07-31T19:58:10.436467+00:00'
    branch_key: epic-EXOCOMP-2
    candidate_rotation_count: 2
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T19:58:15.245794+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2'
    next_retry_at: '2026-07-31T19:58:55.245770+00:00'
---
## Summary

Implement deterministic scheduling and node-state transition logic for the coordinator poller. Default to a 30-second interval with bounded configurable jitter; track last_attempted_contact, last_successful_contact, consecutive_failures, and next_eligible_poll_at in Exocomp.Coordinator.Registry; apply bounded exponential backoff for repeated unreachable/time-out/authentication failures; reset failures/backoff on recovery; and map probe results consistently to unknown, healthy, degraded, stale, or unreachable. Define and test the freshness thresholds that distinguish degraded/stale/unreachable, using injected clock/randomness so tests do not sleep. Ensure stale callbacks cannot overwrite a newer observation and emit transition audit events without exposing secrets. Add table-driven unit tests for initial scheduling, jitter bounds, every transition, timestamps, backoff cap, repeated failures, recovery, and late-result handling; run focused and affected Make gates.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:52
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:52
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 02:52
---
Understanding: This run is limited to duplicate screening. I will search task history and design/docs for coordinator polling, scheduling, backoff, registry transitions, stale callbacks, and audit events; read plausible task candidates in full; then archive only if the same deliverable is already covered, otherwise hand off with evidence to an implementation focus.
---
author: oompah
created: 2026-07-24 02:53
---
Discovery: No duplicate confirmed. The closest reviewed tasks were EXOCOMP-15 (parent epic), EXOCOMP-14 (completed Registry/Audit scaffold), EXOCOMP-89 (mTLS probe boundary and typed outcomes), EXOCOMP-91 (bounded concurrent poll execution), and EXOCOMP-92 (cross-component integration coverage). EXOCOMP-90 is the intentionally decomposed child that uniquely owns deterministic scheduling, backoff, freshness/state transitions, timestamps, stale-result protection, and transition-audit unit behavior. The milestone plan's Node State/Audit/Test Strategy sections match that boundary.
---
author: oompah
created: 2026-07-24 02:54
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no duplicate; EXOCOMP-90 remains a distinct implementation child of EXOCOMP-15.

Evidence: Repository search covered poll/scheduling/backoff/registry-state/timestamp/stale-callback/audit terms across the available plans/docs; this checkout has no .oompah/tasks directory, so full candidate descriptions/comments were read through tracker views. EXOCOMP-14 provides the existing ETS Registry and redacted Audit infrastructure but no poll scheduling/state machine. EXOCOMP-89 produces typed authenticated probe outcomes and safely adopts addresses. EXOCOMP-91 consumes EXOCOMP-90's scheduling/state-transition API while owning worker concurrency/timeouts/isolation. EXOCOMP-92 verifies the combined system. plans/milestone-2-coordinator.md Node State specifies the exact EXOCOMP-90 fields, 30-second jittered interval, exponential backoff, and reachability states; Audit/Test Strategy requires redacted poll-transition events and unit state/schedule coverage.

Relevant files/decisions: plans/milestone-2-coordinator.md sections Node State, Audit, and Test Strategy; implementation should extend Exocomp.Coordinator.Registry and reuse Exocomp.Coordinator.Audit from EXOCOMP-14. Keep scheduling deterministic through injected clock/randomness and reject late observations with an ordering token or attempt timestamp.

Remaining work/risks: Implement and test scheduling, bounded jitter/backoff, freshness thresholds, all state/timestamp transitions, recovery, stale-result rejection, and redacted audit emissions. Coordinate the public outcome contract with EXOCOMP-89 and the due-node/concurrency consumer with EXOCOMP-91. Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 03:05
---
Agent completed successfully in 792s (563521 tokens)
---
author: oompah
created: 2026-07-24 03:05
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 17
- Tokens: 560.6K in / 2.9K out [563.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 13m 12s
- Log: EXOCOMP-90__20260724T025242Z.jsonl
---
author: oompah
created: 2026-07-24 03:05
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 03:31
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 03:31
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-24 03:32
---
Understanding: I will extend the coordinator Registry with deterministic 30-second jittered scheduling, bounded exponential backoff, explicit freshness/state mapping, ordered observation tokens that reject late callbacks, and redacted transition audit events. I will align with the existing NodeProber outcome and Audit contracts, add table-driven tests covering schedules, all states, timestamps, failure/recovery behavior, caps, and stale results, then run the focused coordinator and repository Make gates.
---
author: oompah
created: 2026-07-24 03:33
---
Discovery: Registry already stores the required fields but initializes next_eligible_poll_at to nil and only exposes unrestricted map updates; NodeProber already returns :healthy, :degraded, :timeout, :unreachable, and :identity_mismatch outcomes. The compatible seam is to add ordered poll-attempt and observation APIs to Registry, retain NodeProber address adoption, derive failure reachability from last-success freshness, and emit state-transition audits through the existing recursively redacting Audit service.
---
author: oompah
created: 2026-07-24 03:44
---
Implementation: Registry now assigns deterministic jittered initial schedules, exposes ordered due_nodes/begin_poll/record_observation APIs, tracks attempt/success timestamps and failure counts, applies capped exponential backoff, maps failure freshness at 60-second degraded and 5-minute stale thresholds, resets on recovery, and ignores obsolete attempt tokens. State transitions emit minimal redacted audit attributes. NodeProber accepts an optional attempt token so typed outcomes and verified addresses are committed atomically while preserving its legacy direct-call behavior. Added table-driven Registry coverage for scheduling bounds, all states/transitions, timestamps, repeated failures/cap/recovery, stale results, and audit secrecy.
---
author: oompah
created: 2026-07-24 03:46
---
Verification: Focused Registry+NodeProber tests pass (45/45). make lint passes formatting and forced warnings-as-errors compilation across all umbrella apps. make test passes: bench 55, core 2, coordinator 70, node 49 with 10 integration exclusions; both test releases assembled and smoke-started successfully. One initial full-suite run exposed an unrelated existing ProposalClient teardown race, and the immediate rerun plus final post-change full run both passed.
---
author: oompah
created: 2026-07-24 03:47
---
Completion: Delivered deterministic coordinator poll scheduling and Registry state transitions in commit cfec4d2 on pushed branch EXOCOMP-90. Includes 30s bounded jitter, 60s/5m freshness thresholds, capped 15m exponential backoff, ordered stale-result rejection, recovery reset, transition audit events, NodeProber token integration, and comprehensive table-driven tests. Final focused tests, make lint, full make test, release assembly, and release smoke checks all pass.
---
author: oompah
created: 2026-07-24 03:48
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 0, Tool calls: 90
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 16m 13s
- Log: EXOCOMP-90__20260724T033157Z.jsonl
---
author: oompah
created: 2026-07-24 03:48
---
Implemented deterministic poll scheduling, bounded jitter/backoff, freshness-based Registry transitions, stale-result protection, redacted audits, NodeProber token integration, and comprehensive passing tests.
---
author: oompah
created: 2026-07-31 19:41
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-07-31 19:54
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-07-31 19:54
---
Run #1 [attempt=1, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 6s
---
author: oompah
created: 2026-07-31 19:54
---
Auditor attempt ended: git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-07-31 19:57
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-07-31 19:57
---
Run #2 [attempt=2, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 4s
---
author: oompah
created: 2026-07-31 19:57
---
Auditor attempt ended: git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-07-31 19:58
---
Auditor dispatched (attempt #3, candidate: prov-651d553c/haiku)
---
author: oompah
created: 2026-07-31 19:58
---
Run #3 [attempt=3, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 3s
---
author: oompah
created: 2026-07-31 19:58
---
Auditor attempt ended: git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-2. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-07-31 19:59
---
Needs Human — Archived audit requires operator input.

No independent auditor candidate is available for this audit (Audit reached the maximum of 3 attempts.). Configure the `auditor` role with at least one healthy provider/model that is independent of the task contributors, then move the task back to Open to retry.
---
author: oompah
created: 2026-08-01 00:59
---
Direct operator recovery claimed at the project owner's request. This is a failed Archived audit caused by deleted historical branch checkout, not incomplete implementation. Keep Needs Human as a scheduler hold until OOMPAH-671 is deployed; I will rearm and oversee the existing archive audit without reopening implementation.
---
author: oompah
created: 2026-08-01 01:43
---
Terminal audit rearmed by project owner after recovery: Detached historical audit workspace recovery is deployed; retry the existing Archived audit without reopening implementation.
---
<!-- COMMENTS:END -->
