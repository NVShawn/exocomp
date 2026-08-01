---
id: EXOCOMP-171
type: task
status: In Progress
priority: 1
title: Add correlated Mission Control audit events
parent: EXOCOMP-134
children: []
blocked_by:
- EXOCOMP-138
- EXOCOMP-141
- EXOCOMP-139
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:34.779256Z'
updated_at: '2026-08-01T13:21:24.440719Z'
work_branch: epic-EXOCOMP-134--task-EXOCOMP-171
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: cf0b41ee9e841503700dd293cf9b9d0f92e9fac56ceb90af0530ca81b91aaa9a
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:05:21.176483+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector  \nDuplicate preflight verdict: no_duplicate\
    \  \nMatches: none  \nEvidence: Reviewed active Mission Control tasks EXOCOMP-134,\
    \ 137, 138, 139, 149, 150, 151, 154, 158, 160, 161, 162, 163, 169, 170, 172, 173,\
    \ 175, 179, 181, and 194. They cover parent orchestration, persistence foundations,\
    \ ingestion, commands, incidents, conversations, proposals, UI, webhooks, retention,\
    \ or security testing\u2014not immutable correlated audit-event storage. Terminal\
    \ tasks were excluded."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 3f51ce77-d11c-490a-8473-b0140bd78a30
oompah.work_branch: epic-EXOCOMP-134--task-EXOCOMP-171
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-134--task-EXOCOMP-171
  base_branch: epic-EXOCOMP-134
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:05:41.218802+00:00'
oompah.task_costs:
  total_input_tokens: 880593
  total_output_tokens: 4076
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 880593
      output_tokens: 4076
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 880593
    output_tokens: 4076
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:05:21.175947+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-171__20260801T130345Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-134--task-EXOCOMP-171
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:05:21.181831+00:00'
---
## Summary

Plan: plans/mission-control.md, Persistence and Retention.

Deliverables:
- Add immutable organization-scoped audit-event storage for operator mutations, cluster events, commands, proposals, decisions, executions, and administrative changes.
- Store actor/cluster identity, timestamp, event type, target, outcome, and correlation IDs.
- Add one redaction module used before audit and webhook serialization.

Acceptance:
- Tests cover each actor type, correlation lookup, ordering, transaction rollback, cross-organization access, redaction, and attempts to update/delete an event through normal contexts.
- Secrets, private keys, tokens, and arbitrary raw logs are never persisted.

Out of scope: retention deletion and audit UI.
Quality gate: focused audit tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:03
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:03
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:05
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 12
- Tokens: 880.6K in / 4.1K out [884.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 48s
- Log: EXOCOMP-171__20260801T130345Z.jsonl
---
author: oompah
created: 2026-08-01 13:05
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 13:05
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 13:07
---
Understanding: This task requires adding immutable, organization-scoped audit-event storage for Mission Control. Deliverables: (1) Audit event model storing actor/cluster identity, timestamp, event type, target, outcome, correlation IDs; (2) One redaction module for sensitive data before serialization; (3) Tests covering actor types, correlation, ordering, rollback, cross-org access, redaction, and prevention of update/delete. Plan reference: plans/mission-control.md 'Persistence and Retention' section. Approach: (1) Review existing audit patterns in coordinator; (2) Create Mission Control audit event schema and redaction module; (3) Add comprehensive tests; (4) Run quality gates.
---
author: oompah
created: 2026-08-01 13:21
---
Discovery & Implementation: Created exocomp_mission_control app with:

1. AuditEvent module (lib/exocomp/mission_control/audit_event.ex):
   - Immutable audit event struct with fields: event_id, organization_id, cluster_id, actor_type, actor_sub, actor_display_name, event_type, target, outcome, outcome_details, correlation_id, occurred_at, inserted_at
   - Supports three actor types: :operator (human), :system (automatic), :cluster (cluster-initiated)
   - Generates unique event_id (evt_*) and correlation_id (corr_*) using url-safe base64
   - Enforces actor_type invariants (e.g., actor_sub only for operators)
   - Provides to_map/1 for JSON serialization
   - Organization-scoped immutability by design

2. Redaction module (lib/exocomp/mission_control/redaction.ex):
   - Redacts sensitive fields: api_key, authorization, cookie, credential, credentials, password, passwd, private_key, secret, token
   - Supports exact and suffix matches (e.g., db_password, webhook_secret)
   - Case-insensitive with hyphen/underscore normalization
   - Recursive redaction for nested maps and lists
   - Used before audit and webhook serialization

3. Comprehensive test coverage (79 passing tests):
   - 53 AuditEvent tests: creation, validation, actor types, correlation, organization scoping, JSON serialization
   - 26 Redaction tests: exact/suffix matches, case insensitivity, nested structures, real-world audit scenarios

Quality gates: make test ✓ (79/79), make fmt-check ✓, make lint ✓
---
<!-- COMMENTS:END -->
