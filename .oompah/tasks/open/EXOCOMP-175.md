---
id: EXOCOMP-175
type: task
status: Open
priority: 2
title: Delete incident, conversation, proposal, and audit history by policy
parent: EXOCOMP-134
children: []
blocked_by:
- EXOCOMP-158
- EXOCOMP-161
- EXOCOMP-171
- EXOCOMP-173
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:39.520334Z'
updated_at: '2026-08-01T15:41:33.603846Z'
work_branch: epic-EXOCOMP-134--task-EXOCOMP-175
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: e2942b5b46852d438031f60f9ab9e2f44de4b4ddd0be018079a5ed1c5b3084e3
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T15:41:26.812856+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active EXOCOMP-174, 171, 158, 161, and 173. Their scopes are
    distinct; EXOCOMP-174 explicitly excludes incident/conversation/audit retention.
    No files or tracker records were modified.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 824a03e4-d687-4168-a42e-d7d5b7603b00
oompah.work_branch: epic-EXOCOMP-134--task-EXOCOMP-175
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-134--task-EXOCOMP-175
  base_branch: epic-EXOCOMP-134
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:39:45.253349+00:00'
oompah.task_costs:
  total_input_tokens: 717617
  total_output_tokens: 3651
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 717617
      output_tokens: 3651
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 717617
    output_tokens: 3651
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:41:26.811700+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-175__20260801T153949Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-134--task-EXOCOMP-175
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T15:41:26.822690+00:00'
---
## Summary

Plan: plans/mission-control.md, Persistence and Retention.

Deliverables:
- Implement the configurable one-year default retention for resolved incidents, messages/evidence, proposals/decisions/executions, webhook event history, and audit events.
- Delete in dependency-safe bounded batches while preserving open incidents, pending proposals/commands, and records still required by a retained timeline.
- Record job counts, failures, and last successful cutoff.

Acceptance:
- Tests cover cutoff boundaries, dependency ordering, open/pending preservation, multiple organizations, interrupted resume, concurrent ingest, and audit of retention settings.
- The job never deletes cluster identity/current-state records.

Out of scope: legal hold and archival export.
Quality gate: focused retention tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:39
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:39
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 15:41
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 25
- Tokens: 717.6K in / 3.7K out [721.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 45s
- Log: EXOCOMP-175__20260801T153949Z.jsonl
---
<!-- COMMENTS:END -->
