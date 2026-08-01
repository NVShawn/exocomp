---
id: EXOCOMP-174
type: task
status: In Progress
priority: 2
title: Delete status history with bounded retention jobs
parent: EXOCOMP-134
children: []
blocked_by:
- EXOCOMP-153
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:38.421513Z'
updated_at: '2026-08-01T15:40:12.988048Z'
work_branch: epic-EXOCOMP-134--task-EXOCOMP-174
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: aca00fd37b09c835b1fd8c142f2e8b56df43e4a4ac38fdd09ee3a2027f1607c1
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T15:37:09.253115+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active EXOCOMP-153, EXOCOMP-175, EXOCOMP-170, EXOCOMP-171,
    EXOCOMP-177, EXOCOMP-137, EXOCOMP-149, EXOCOMP-152, EXOCOMP-154, and EXOCOMP-166.
    Their scopes are status recording, other-domain retention, settings UI, audit
    storage, metrics, persistence, ingestion, current state, incidents, and UI; none
    duplicates status-history deletion jobs.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: a8847780-7970-460f-b442-6778db7fa939
oompah.work_branch: epic-EXOCOMP-134--task-EXOCOMP-174
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-134--task-EXOCOMP-174
  base_branch: epic-EXOCOMP-134
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:37:28.507128+00:00'
oompah.task_costs:
  total_input_tokens: 1326315
  total_output_tokens: 5152
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 1326315
      output_tokens: 5152
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 1326315
    output_tokens: 5152
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:37:09.251896+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-174__20260801T153500Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-134--task-EXOCOMP-174
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T15:37:09.260115+00:00'
---
## Summary

Plan: plans/mission-control.md, Persistence and Retention.

Deliverables:
- Add configurable organization retention settings with a 90-day status-history default and validated bounds.
- Implement partition drop or bounded-batch deletion without holding long transactions or deleting current materialized state.
- Record job progress/failure metrics and audit configuration changes.

Acceptance:
- Clock-controlled tests cover cutoff boundaries, multiple organizations, batch continuation, retry after failure, concurrent ingest, and preservation of current state.
- One job cannot delete another organization data.

Out of scope: incident/conversation/audit retention.
Quality gate: focused retention tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:34
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:34
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 15:37
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 26
- Tokens: 1.3M in / 5.2K out [1.3M total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 18s
- Log: EXOCOMP-174__20260801T153500Z.jsonl
---
author: oompah
created: 2026-08-01 15:37
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 15:37
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 15:40
---
**Understanding**: This task implements deletion of status history with bounded retention jobs for Mission Control. Deliverables: (1) Configurable per-organization retention settings with 90-day default and validated bounds, (2) Partition drop or bounded-batch deletion without long transactions or deletion of current state, (3) Job progress/failure metrics and audit logging. Acceptance: Clock-controlled tests covering cutoff boundaries, multiple orgs, batch continuation, retry/failure, concurrent ingest, state preservation, and cross-org isolation. Will implement in Mission Control app with focused retention tests, make test, make fmt-check, and make lint all passing. Starting with codebase exploration to identify blocking dependencies (EXOCOMP-153, EXOCOMP-171) and existing structure.
---
<!-- COMMENTS:END -->
