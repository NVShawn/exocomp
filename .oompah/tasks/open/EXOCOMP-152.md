---
id: EXOCOMP-152
type: task
status: Open
priority: 1
title: Persist current cluster and node status
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-149
start_blocked_by: &id001
- EXOCOMP-194
labels: []
assignee: null
created_at: '2026-07-30T14:15:36.397265Z'
updated_at: '2026-08-01T12:30:28.375306Z'
work_branch: epic-EXOCOMP-131--task-EXOCOMP-152
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: b810f85a7e08d820682dae622de9369a8b323957fbc131cb44a49075d1c29fd6
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:30:25.038562+00:00'
  matched_identifiers: []
  evidence: 'Based on my investigation, I have systematically searched the codebase
    for any existing or related tasks that might duplicate EXOCOMP-152''s scope.


    ## Investigation Summary


    I searched for:

    1. **Task references**: Looked for EXOCOMP-15x task IDs and related issues across
    the entire repository

    2. **Implementation code**: Searched for existing cluster/node state, current-state
    schemas, event reducers, materialized views

    3. **Related features**: Searched for mission-control, fleet-status, heartbeat,
    snapshot, and event reduction code

    4. **Schema definitions**: Searched for cluster and node schema implementations

    5. **Project plans**: Reviewed plans/mission-control.md for scope definition


    ## Findings


    The mission-control.md plan file describes the overall Milestone 7 architecture,
    including the requirement for "a current materialized view for clusters and nodes"
    that EXOCOMP-152 specifically implements. However:


    - No implementation code exists for this feature yet

    - No other tasks in the repository appear to be addressing the same cluster/node
    current-state schema and reducer requirements

    - EXOCOMP-152''s dependency on EXOCOMP-149 (connection protocol) indicates clear
    task decomposition, not duplication

    - The coordination notes identify EXOCOMP-152 as a distinct task within the epic
    hierarchy


    The specific scope of EXOCOMP-152 (schemas, reducers, and stale snapshot rejection)
    is distinct from its blocking dependencies and sibling tasks.


    ---


    **Focus handoff: duplicate_detector**


    **Duplicate preflight verdict: no_duplicate**


    **Matches: none**


    **Evidence:** Comprehensive search of the codebase found no existing implementation
    of cluster/node current-state schemas, event reducers, or materialized views.
    The mission-control.md plan describes the intended architecture but no active
    task appears to be implementing this specific component. EXOCOMP-152''s clear
    dependency structure (blocked by EXOCOMP-149, sibling to EXOCOMP-153+) indicates
    proper task decomposition rather'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 608724a7-d244-46c3-859d-feaaa351c481
oompah.work_branch: epic-EXOCOMP-131--task-EXOCOMP-152
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-131--task-EXOCOMP-152
  base_branch: epic-EXOCOMP-131
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:28:41.775935+00:00'
oompah.task_costs:
  total_input_tokens: 154
  total_output_tokens: 4917
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 154
      output_tokens: 4917
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 154
    output_tokens: 4917
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:30:25.032162+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-152__20260801T122845Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-131--task-EXOCOMP-152
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:30:25.147937+00:00'
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Add organization-scoped cluster and node current-state schemas for connectivity, health, versions, capabilities, labels, node counts, and last contact.
- Reduce cluster.hello, heartbeat, and status.snapshot events into the materialized current view transactionally.
- Reject stale snapshots using sequence/observation ordering.

Acceptance:
- Reducer tests cover initial state, partial update, stale update, node removal/tombstone, reconnect, duplicate event, and organization isolation.
- Current state can be queried without scanning event history.

Out of scope: history checkpoints, incidents, and UI.
Quality gate: focused context tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: persist the current effective service expectation and health per organization/cluster/node/unit, including source set, health depth, recovery authority, profile version, observation time, and retirement state. EXOCOMP-194 supplies the protocol contract.
---
author: oompah
created: 2026-08-01 12:28
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:28
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:30
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 50, Tool calls: 22
- Tokens: 154 in / 4.9K out [5.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 48s
- Log: EXOCOMP-152__20260801T122845Z.jsonl
---
<!-- COMMENTS:END -->
