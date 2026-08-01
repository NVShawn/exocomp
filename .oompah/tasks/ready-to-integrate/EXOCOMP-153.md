---
id: EXOCOMP-153
type: task
status: Ready to Integrate
priority: 2
title: Record bounded cluster and node status history
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-152
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:37.552915Z'
updated_at: '2026-08-01T15:02:00.568963Z'
work_branch: epic-EXOCOMP-131--task-EXOCOMP-153
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 56ed462b0075c8b2b24ecc3c693a952e5feb167ae9d73281644cf94e129e577b
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:49:04.378369+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active EXOCOMP-152, EXOCOMP-149, EXOCOMP-154, EXOCOMP-174,
    EXOCOMP-165, and EXOCOMP-166. Their scopes are current-state persistence, event
    ingestion, incidents, retention deletion, and UI consumption respectively; EXOCOMP-152
    and EXOCOMP-149 explicitly exclude history recording.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 925fe644-ebad-485a-bc1c-419a2e895a53
oompah.work_branch: epic-EXOCOMP-131--task-EXOCOMP-153
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: epic-EXOCOMP-131--task-EXOCOMP-153
  head_sha: bf443ed83b8a12febc5f96878fe9299cd8d49cc5
  submitted_at: '2026-08-01T15:01:58.413484+00:00'
  updated_at: '2026-08-01T15:01:58.413484+00:00'
oompah.task_costs:
  total_input_tokens: 544749
  total_output_tokens: 3273
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 544749
      output_tokens: 3273
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 544749
    output_tokens: 3273
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:49:04.375693+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-153__20260801T144736Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-131--task-EXOCOMP-153
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:49:04.392842+00:00'
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Add partition-ready status-history storage scoped to organization and source identity.
- Record cluster checkpoints every five minutes.
- Record node state changes immediately and unchanged-node checkpoints hourly.
- Preserve observation time separately from ingestion time.

Acceptance:
- Clock-controlled tests cover change detection, checkpoint cadence, duplicate snapshots, late events, and bounded batch writes.
- History writes do not block or replace the current-state transaction.

Out of scope: retention deletion and charts.
Quality gate: focused history tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:47
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:47
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:49
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 11
- Tokens: 544.7K in / 3.3K out [548.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 38s
- Log: EXOCOMP-153__20260801T144736Z.jsonl
---
author: oompah
created: 2026-08-01 14:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 14:49
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 14:50
---
Understanding: Implementing bounded status-history storage for Mission Control. Key requirements: (1) partition-ready storage scoped by organization and source identity, (2) cluster checkpoints every 5min, (3) node changes immediately + hourly checkpoints for unchanged nodes, (4) preserve observation_time separate from ingestion_time, (5) history writes async and non-blocking to current-state transaction. Will implement with clock-controlled tests for change detection, checkpoint cadence, duplicate snapshots, late events, and bounded batch writes.
---
author: oompah
created: 2026-08-01 14:53
---
Discovery: No Mission Control app or status-history infrastructure exists yet. EXOCOMP-152 is blocked by the same commit (8f80aebf). Will implement status-history library in exocomp_core with: (1) data models for partitioned history storage, (2) clock-controlled recorder logic for cluster checkpoints (5min) and node changes (immediate + hourly), (3) comprehensive tests. This provides a reusable component for Mission Control to use.
---
author: oompah
created: 2026-08-01 15:01
---
Implementation: Created partition-ready status-history storage in exocomp_core with: (1) Record data model supporting cluster/node snapshots and changes with separate observed_at/recorded_at fields, (2) Recorder module implementing clock-controlled checkpoints (5min for clusters, 1hr for nodes), change detection, and duplicate deduplication, (3) Acceptance of late events within configurable windows (1hr for changes, 1 day for snapshots), (4) Bounded batch writes (max 1000 records). All tests pass: 511 passed, fmt-check, lint.
---
author: oompah
created: 2026-08-01 15:01
---
Verification: All quality gates pass. Test results: 511 tests passed (includes 48 new tests for status-history). Tests cover: clock-controlled checkpoint cadence, change detection, duplicate snapshots, late event acceptance, bounded batch writes. Code passes: make test, make fmt-check, make lint. Branch pushed to origin/epic-EXOCOMP-131--task-EXOCOMP-153.
---
author: oompah
created: 2026-08-01 15:02
---
Implemented partition-ready status-history storage with clock-controlled recorder for cluster (5min) and node (1hr) checkpoints, change detection, duplicate deduplication, and bounded batch writes.
---
<!-- COMMENTS:END -->
