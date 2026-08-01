---
id: EXOCOMP-177
type: task
status: Open
priority: 2
title: Expose Mission Control health and Prometheus metrics
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-147
- EXOCOMP-152
- EXOCOMP-154
- EXOCOMP-160
- EXOCOMP-150
- EXOCOMP-173
- EXOCOMP-174
- EXOCOMP-175
start_blocked_by: &id001
- EXOCOMP-193
- EXOCOMP-200
labels: []
assignee: null
created_at: '2026-07-30T14:18:30.240380Z'
updated_at: '2026-08-01T15:42:54.239898Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-177
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 478261293571058520cc5f48fdcdb3bf94de7d0be9d03eede91987cba794252d
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 5d4d2712-05c8-4bd5-8fc7-1c33ac8fe334
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T15:42:45.997697+00:00'
  claim_expires_at: '2026-08-01T16:12:45.997697+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 020a3281-e526-405b-93b4-e78fef361d4a
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-177
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-177
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:42:52.372155+00:00'
---
## Summary

Plan: plans/mission-control.md, Deployment and Operations.

Deliverables:
- Add unauthenticated liveness and appropriately guarded readiness endpoints.
- Readiness must cover database migrations/connectivity and critical supervision state without depending on any cluster being online.
- Export the planned connection, ingest, incident, chat/proposal, command, webhook, database, and retention metrics without high-cardinality cluster/node labels.

Acceptance:
- Tests cover healthy, database unavailable, migration pending, degraded worker, recovery, and metric name/type/label stability.
- Endpoints expose no secrets or tenant records.

Out of scope: dashboards and alert-manager rules.
Quality gate: focused health/telemetry tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: add counts and transition metrics for healthy/unhealthy/stale/retired services, automatic-discovery failures, profile coverage, Ceph health severity, helper denial, recovery verification failure, and cooldown.
---
author: oompah
created: 2026-08-01 15:42
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:42
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
