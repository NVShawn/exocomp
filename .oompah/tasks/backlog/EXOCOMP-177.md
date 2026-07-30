---
id: EXOCOMP-177
type: task
status: Backlog
priority: 2
title: Expose Mission Control health and Prometheus metrics
parent: EXOCOMP-135
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:18:30.240380Z'
updated_at: '2026-07-30T14:18:30.240380Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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

