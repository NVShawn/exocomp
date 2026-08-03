---
id: EXOCOMP-221
type: task
status: Open
priority: 1
title: Deliver policy bundles through the durable command outbox
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-219
- EXOCOMP-220
labels: []
assignee: null
created_at: '2026-08-03T14:25:14.532816Z'
updated_at: '2026-08-03T15:43:38.777802Z'
work_branch: epic-EXOCOMP-210--task-EXOCOMP-221
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 465c809ea013c895a78a173c66c096ba2c38f5d0dbba0824ccbc111382404b0b
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: e1413eba-d37c-4d18-ac2a-18dd31abc87c
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:43:29.763480+00:00'
  claim_expires_at: '2026-08-03T16:13:29.763480+00:00'
  retry_count: 2
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 452a981f-f3ac-44c5-a767-6a976d22a8f2
oompah.work_branch: epic-EXOCOMP-210--task-EXOCOMP-221
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-210--task-EXOCOMP-221
  base_branch: epic-EXOCOMP-210
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:43:36.108676+00:00'
oompah.task_costs:
  total_input_tokens: 146425
  total_output_tokens: 1283
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 146425
      output_tokens: 1283
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 97925
    output_tokens: 731
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:37:47.428783+00:00'
  - profile: default
    model: haiku
    input_tokens: 48500
    output_tokens: 552
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:40:35.413055+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-221__20260803T153700Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-210--task-EXOCOMP-221
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:37:47.440168+00:00'
  - run_id: EXOCOMP-221__20260803T154007Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-210--task-EXOCOMP-221
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:40:35.416390+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add a policy-replace command and policy acknowledgement to the existing Mission Control coordinator transport.

Acceptance criteria:
- Every committed policy version produces at most one logical pending bundle per affected cluster while allowing safe retry.
- Newer versions supersede older undelivered policy bundles; acknowledged versions are idempotent.
- Commands survive Mission Control restart and reconnect and remain organization/cluster identity-bound.
- Expired bundles are replaced with fresh leases rather than delivered.
- Ordinary approvals and execution commands retain their existing behavior.

Tests: Cover fan-out, supersession, retry, duplicate acknowledgement, wrong cluster, expiry before delivery, reconnect, process restart, and two Mission Control replicas; run make test, make fmt-check, and make lint.

Out of scope: Coordinator validation, cache persistence, and UI.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:36
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:36
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:37
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 6
- Tokens: 97.9K in / 731 out [98.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 57s
- Log: EXOCOMP-221__20260803T153700Z.jsonl
---
author: oompah
created: 2026-08-03 15:40
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:40
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:40
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 0
- Tokens: 48.5K in / 552 out [49.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 35s
- Log: EXOCOMP-221__20260803T154007Z.jsonl
---
author: oompah
created: 2026-08-03 15:43
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:43
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
