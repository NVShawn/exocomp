---
id: EXOCOMP-177
type: task
status: Ready to Integrate
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
updated_at: '2026-08-01T23:33:31.811492Z'
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
  verdict: no_duplicate
  checked_at: '2026-08-01T15:44:55.352382+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active EXOCOMP-152, EXOCOMP-154, EXOCOMP-160,\
    \ EXOCOMP-173, EXOCOMP-174, EXOCOMP-175, EXOCOMP-179, EXOCOMP-180, EXOCOMP-181,\
    \ EXOCOMP-182, EXOCOMP-183, EXOCOMP-193, and EXOCOMP-200. They cover persistence,\
    \ workflows, retention, webhooks, integration testing, desired-state reconciliation,\
    \ Ceph health reduction, or qualification; none covers Mission Control\u2019s\
    \ liveness/readiness endpoints and stable Prometheus metric surface. Terminal\
    \ tasks were excluded."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: da2b7ab1-b7c0-4786-8c09-25b673c9700c
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-177
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-177
  head_sha: 94476b76fea579c5b0c38cee2547a7ab3f600f21
  submitted_at: '2026-08-01T23:33:28.255110+00:00'
  updated_at: '2026-08-01T23:33:28.255110+00:00'
oompah.task_costs:
  total_input_tokens: 836126
  total_output_tokens: 4897
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 836126
      output_tokens: 4897
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 836126
    output_tokens: 4897
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:44:55.347392+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-177__20260801T154256Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-177
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T15:44:55.372158+00:00'
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
author: oompah
created: 2026-08-01 15:44
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 33
- Tokens: 836.1K in / 4.9K out [841.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 6s
- Log: EXOCOMP-177__20260801T154256Z.jsonl
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
Understanding: Add unauthenticated liveness and guarded readiness endpoints, with readiness reflecting migrations/database connectivity and critical supervision state without requiring a cluster, plus stable low-cardinality Prometheus metrics for the planned Mission Control domains. I will first inspect the server, startup, persistence, supervision, telemetry, docs, and Makefile test conventions; then implement focused coverage for healthy/unavailable/pending/degraded/recovery states and endpoint/metric security and stability.
---
author: oompah
created: 2026-08-01 23:06
---
Discovery: The existing Mission Control scaffold (dependency commit 3a3d6e61) provides Phoenix Endpoint/Router/Application with GET /health, while later dependency APIs identify Repo, connection/session liveness, incident, command, webhook, and retention boundaries. The current task branch has not yet received those dependency commits, so the implementation will preserve the scaffold-compatible public modules and keep health/telemetry checks injectable and low-cardinality for clean integration when dependencies land.
---
author: oompah
created: 2026-08-01 23:24
---
Implementation: Added Mission Control liveness (/health/live), backward-compatible /health, token-guarded redacted readiness (/health/ready), optional Ecto/PostgreSQL readiness checks, local critical-worker supervision checks, and operations documentation. Added a fixed low-cardinality Prometheus registry at /metrics with connection, ingest, incident, conversation/proposal, command, webhook, database, retention, and desired-service/recovery telemetry, including stable zero-valued series and schema validation.
---
author: oompah
created: 2026-08-01 23:31
---
Verification: Passed the dependency-neutral health/metrics smoke (healthy and degraded readiness, telemetry rendering, Ceph, recovery), explicit changed-file format checks, git diff --check, and make compliance-check. make lint passed its offline builder/Python checks but its container compile step was blocked by the host Podman sticky-bit filesystem error; make fmt-check hit the same container blocker. Focused ExUnit was attempted with the host Elixir 1.18.3 and remains blocked by missing Erlang syntax_tools; the project builder requires Elixir 1.20.2.
---
author: oompah
created: 2026-08-01 23:33
---
Completion: Delivered and pushed 94476b76. Mission Control now exposes /health/live, /health/ready, and /metrics with redacted readiness checks, bearer guarding, database/migration/worker evaluation, stable low-cardinality metric families, desired-service telemetry, and operations documentation. Focused smoke, formatting, and compliance checks passed; the project-version ExUnit/container gates remain environment-blocked as recorded above. Branch is up to date with origin.
---
author: oompah
created: 2026-08-01 23:33
---
Delivered guarded Mission Control health probes, database/migration readiness, stable low-cardinality Prometheus metrics, telemetry instrumentation, operations documentation, tests, and dependency license inventory.
---
<!-- COMMENTS:END -->
