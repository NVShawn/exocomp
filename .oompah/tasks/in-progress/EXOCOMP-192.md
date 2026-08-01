---
id: EXOCOMP-192
type: task
status: In Progress
priority: 2
title: Schedule service discovery and observations in the coordinator
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-188
- EXOCOMP-190
- EXOCOMP-191
labels: []
assignee: null
created_at: '2026-07-30T21:37:02.009432Z'
updated_at: '2026-08-01T15:58:44.715830Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-192
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: c3d4b1c7dfae5adf41d81e0d95bc8fe379f913c49dca8ecc83be6db1423bea0c
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T15:58:15.354994+00:00'
  matched_identifiers: []
  evidence: '## Investigation Complete


    I have completed my duplicate investigation for EXOCOMP-192. Here are my findings:


    ### What I Searched For


    I examined:

    1. **Existing code structure** - searched for any service discovery, discovery
    scheduler, or service observation code in the coordinator

    2. **Related infrastructure** - found `Exocomp.DesiredService` module created
    by EXOCOMP-189 with source types and resolver logic

    3. **Existing scheduling patterns** - found `HealthPoller` (30-second health cadence)
    and `Orchestrator` (bounded fan-out framework)

    4. **Test coverage** - searched for any existing tests related to service discovery
    scheduling


    ### Key Findings


    **EXOCOMP-189 (Integrated)**: Added infrastructure components:

    - `Exocomp.DesiredService` module with source types (`:manual`, `:automatic`,
    `:cluster_profile`)

    - Deterministic three-path resolver for merging contributions

    - Table-driven unit tests


    **EXOCOMP-192 (This Task)**: Distinct and separate work:

    - Requires NEW scheduler for service discovery (startup + every 5 minutes)

    - Requires service observation on health cadence (existing 30-second)

    - Requires jitter, bounded concurrency, per-node timeouts, and caching logic

    - Requires injectable clock for deterministic tests

    - No existing implementation found


    **Existing Patterns Available**:

    - `HealthPoller` - provides periodic polling framework with bounded concurrency

    - `Orchestrator` - provides fan-out with per-node isolation and timeouts

    - These are patterns to build upon, not duplicates


    ### Conclusion


    EXOCOMP-192 represents original, non-duplicated work. It''s a distinct implementation
    task that builds on the infrastructure created by EXOCOMP-189, but implements
    new scheduling logic not yet present in the coordinator.


    ---


    **Focus handoff: duplicate_detector**


    **Duplicate preflight verdict: no_duplicate**


    **Matches: none**


    **Evidence:** After thorough exploration of the coordinator codebase, I found
    no existing service discovery scheduler, observation servi'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 967d499b-29ae-446d-8817-9643a47fcf8d
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-192
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-192
  base_branch: epic-EXOCOMP-185
  base_sha: 7b3ff4a831259ec5555de09214348b3da5eb554e
  updated_at: '2026-08-01T15:58:26.939512+00:00'
oompah.task_costs:
  total_input_tokens: 242
  total_output_tokens: 6565
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 242
      output_tokens: 6565
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 242
    output_tokens: 6565
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:58:15.342909+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-192__20260801T155333Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-185--task-EXOCOMP-192
    source_sha: 7b3ff4a831259ec5555de09214348b3da5eb554e
    completed_at: '2026-08-01T15:58:15.369409+00:00'
---
## Summary

Plan: plans/mission-control.md, desired-state polling.

Deliverable: Add coordinator scheduling that discovers automatic services on startup and every five minutes and observes effective services on the existing 30-second health cadence.

Acceptance criteria:
- Use jitter, bounded concurrency, per-node timeouts, and the existing backoff/isolation patterns.
- Cache the newest successful discovery without replacing it with a failed scan.
- Inventory replacement triggers prompt reconciliation.
- One slow or unreachable node cannot block peers.
- Scheduling uses an injectable clock for deterministic tests.

Tests: Cover startup, periodic refresh, jitter, cache preservation, inventory reload, timeout isolation, and cancellation; run make test.

Out of scope: Merge rules, status event schemas, incidents, and recovery.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:53
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:53
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 15:58
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 68, Tool calls: 29
- Tokens: 242 in / 6.6K out [6.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 4m 52s
- Log: EXOCOMP-192__20260801T155333Z.jsonl
---
author: oompah
created: 2026-08-01 15:58
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 15:58
---
Focus: Software Engineer
---
author: oompah
created: 2026-08-01 15:58
---
Understanding: add coordinator scheduling for startup and five-minute automatic-service discovery plus 30-second effective-service observations, using injectable-clock tests and existing jitter, bounded concurrency, node timeout, backoff/isolation, cache, inventory-reload, and cancellation patterns.
---
<!-- COMMENTS:END -->
