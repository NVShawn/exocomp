---
id: EXOCOMP-155
type: task
status: Needs Human
priority: 1
title: Implement incident health-transition rules
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-154
start_blocked_by: &id001
- EXOCOMP-193
- EXOCOMP-200
labels: []
assignee: null
created_at: '2026-07-30T14:15:39.771394Z'
updated_at: '2026-08-02T00:06:56.594157Z'
work_branch: epic-EXOCOMP-131--task-EXOCOMP-155
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: c8126b3670c097f541a336f7e8c0209296b74c91fda5460a1f77314b54d0ff7e
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:34:33.230839+00:00'
  matched_identifiers: []
  evidence: 'Acknowledged. The coordination message confirms that EXOCOMP-154 (a dependency
    and epic-sibling) has started implementation. This reinforces that EXOCOMP-155
    is a distinct task blocked by EXOCOMP-154''s completion, not a duplicate of it.


    My investigation conclusion remains unchanged:


    ---


    **Focus handoff: duplicate_detector**


    **Duplicate preflight verdict: no_duplicate**


    **Matches: none**


    **Evidence:** Comprehensive search across the codebase found no existing incident
    reducer implementation, incident state management, or parallel health-transition
    logic. The mission-control.md plan documents the requirements for EXOCOMP-155,
    but no code exists. The coordinator has foundational health monitoring (health_poller,
    node_prober) for node-level observations, but not the Mission Control incident
    reduction rules (two consecutive degraded/healthy observations, explicit alert
    severity mapping, manual/auto resolution). EXOCOMP-154 is a dependency (currently
    starting implementation), not a duplicate. EXOCOMP-155 is original implementation
    work that will begin once EXOCOMP-154 completes.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 10ce6f6e-c973-4eec-9134-985e0e901af0
oompah.work_branch: epic-EXOCOMP-131--task-EXOCOMP-155
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: epic-EXOCOMP-131--task-EXOCOMP-155
  head_sha: b4aa7d82e94f51905f3f3510c518d56df86b876c
  submitted_at: '2026-08-01T23:24:02.292085+00:00'
  updated_at: '2026-08-01T23:24:02.292085+00:00'
oompah.task_costs:
  total_input_tokens: 20385261
  total_output_tokens: 62796
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 20385261
      output_tokens: 62796
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 561
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:34:33.230105+00:00'
  - profile: default
    model: haiku
    input_tokens: 20385251
    output_tokens: 62235
    cost_usd: 0.0
    recorded_at: '2026-08-01T23:24:27.781344+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-155__20260801T123225Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-131--task-EXOCOMP-155
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:34:33.259918+00:00'
  - run_id: EXOCOMP-155__20260801T230151Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: callback_auth
    source_branch: epic-EXOCOMP-131--task-EXOCOMP-155
    source_sha: b4aa7d82e94f51905f3f3510c518d56df86b876c
    completed_at: '2026-08-01T23:24:27.785266+00:00'
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Open health incidents after two consecutive degraded observations.
- Open immediately for stale/unreachable state and identity, authentication, audit, policy, or remediation failures.
- Open explicit cluster alerts and apply deterministic severity mapping.
- Auto-resolve health incidents after two consecutive healthy observations; reopen on new matching unhealthy evidence.

Acceptance:
- Table-driven reducer tests cover every rule, threshold boundary, interleaved target, duplicate observation, manual-resolution recurrence, and explicit resolve event.
- No model is used for opening, grouping, or resolving incidents.

Out of scope: operator acknowledgement and UI.
Quality gate: focused reducer tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: reduce service and profile health into incidents. Use two observations for unhealthy/WARN transitions, immediate critical alerts for Ceph HEALTH_ERR, explicit coverage incidents, and desired_state_removed resolution without creating a false recovery observation.
---
author: oompah
created: 2026-08-01 12:32
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:32
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:34
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 60, Tool calls: 31
- Tokens: 10 in / 561 out [571 total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 16s
- Log: EXOCOMP-155__20260801T123225Z.jsonl
---
author: oompah
created: 2026-08-01 23:01
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 23:01
---
Focus: Callback Auth Validation Specialist
---
author: oompah
created: 2026-08-01 23:02
---
Understanding: implement a deterministic incident health-transition reducer over fleet observations. I will reuse the incident APIs from EXOCOMP-154, define the exact severity and threshold rules from plans/mission-control.md, add table-driven coverage for all acceptance boundaries and ordering cases, then run focused tests plus make test, make fmt-check, and make lint.
---
author: oompah
created: 2026-08-01 23:03
---
Discovery: current-state observations are map-based status.snapshot data in exocomp_core, while EXOCOMP-154 supplies the organization-scoped Incidents store in exocomp_mission_control. Canonical history also requires desired-state service/profile WARN hysteresis, immediate Ceph HEALTH_ERR/critical handling, explicit coverage incidents, and desired_state_removed resolution without a synthetic healthy sample. I’m reconciling these contracts before implementation.
---
author: oompah
created: 2026-08-01 23:12
---
Implementation: added a pure HealthReducer under the EXOCOMP-154 incident app, with two-observation degraded/healthy hysteresis, immediate stale/unreachable/failure/critical/coverage/explicit-alert paths, deterministic alert identity and severity mapping, duplicate-ID conflict detection, desired-state removal resolution, and a store-backed process boundary for persisted/reopened incidents. Focused table-driven coverage is next.
---
author: oompah
created: 2026-08-01 23:18
---
Verification checkpoint: direct ExUnit execution passed 28 tests (20 new HealthReducer cases plus 8 incident-store cases), with zero failures. Coverage includes threshold boundaries, interleaved targets, duplicate/conflicting IDs, all immediate failure classes, Ceph HEALTH_ERR, explicit severity mapping, auto-resolution, manual-resolution recurrence, desired-state removal, and explicit resolve events.
---
author: oompah
created: 2026-08-01 23:22
---
Verification: the changed Mission Control incident sources compile with Elixir warnings-as-errors, focused source formatting checks pass, git diff --check passes, and direct ExUnit passes 30 tests with zero failures. make test, make fmt-check, and make lint ran their offline checks successfully where applicable but cannot reach the pinned container compile step because the environment’s Podman wrapper cannot chmod /run/user/1000/libpod (read-only filesystem); full-project format also reports an unrelated pre-existing bootstrap.ex formatting difference.
---
author: oompah
created: 2026-08-01 23:23
---
Completion: delivered and pushed b4aa7d82 (with submitted EXOCOMP-154 ancestor). HealthReducer now deterministically opens, updates, reopens, and resolves incidents across fleet, service/profile, Ceph, coverage, explicit-alert, and control-plane failure evidence; incident records retain severity. Focused ExUnit is green (30 tests), changed sources compile warnings-as-errors, and branch is clean/up to date. Full Makefile container gates remain environment-blocked by the read-only Podman libpod filesystem noted above.
---
author: oompah
created: 2026-08-01 23:24
---
Implemented deterministic incident health-transition reduction with hysteresis, immediate failure and alert rules, severity mapping, recurrence, explicit resolution, and 30 focused tests; pushed b4aa7d82.
---
author: oompah
created: 2026-08-01 23:24
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 154
- Tokens: 20.4M in / 62.2K out [20.4M total]
- Cost: $0.0000
- Exit: normal, Duration: 22m 48s
- Log: EXOCOMP-155__20260801T230151Z.jsonl
---
author: oompah
created: 2026-08-01 23:24
---
Task handoff failed after the worker ran: the server-owned, task-scoped tracker capability could not update this task. The task is held in Needs Human and will not be redispatched automatically; verify the handoff service and reconcile the worker's branch before resuming it.
---
author: oompah
created: 2026-08-02 00:06
---
Operator taking ownership of recovery. The branch is clean and pushed at b4aa7d82; the Needs Human transition was a false positive from the pre-OOMPAH-678 service process treating expected peer-view scope denials as a failed own-task handoff after submit succeeded. Running the required Makefile gates from the operator environment before resubmission.
---
<!-- COMMENTS:END -->
