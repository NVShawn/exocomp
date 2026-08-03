---
id: EXOCOMP-217
type: task
status: Open
priority: 2
title: Add management-policy HTTP APIs
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-216
labels: []
assignee: null
created_at: '2026-08-03T14:24:19.702752Z'
updated_at: '2026-08-03T15:50:45.365337Z'
work_branch: epic-EXOCOMP-209--task-EXOCOMP-217
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 07c29fc9d134be89d7e319e5554c70a6d13db45beee80f7f1f75ba53808ad1a0
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 808cc2f9-2683-42b5-b57b-2e41f28eca75
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:50:26.876785+00:00'
  claim_expires_at: '2026-08-03T16:20:26.876785+00:00'
  retry_count: 1
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 9c22c570-28c0-4aec-b431-cfbcb787bc9b
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-217
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-217
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:50:42.351401+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 1891
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 1891
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1891
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:48:32.379947+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-217__20260803T154738Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-209--task-EXOCOMP-217
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:48:32.388288+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add versioned Mission Control endpoints to list, resolve, create, update, and delete policy overrides.

Acceptance criteria:
- Organization comes only from the authenticated session.
- Requests validate scope-specific identifiers, canonical service keys, mode, and expected policy version.
- Responses include configured value, inherited value, effective value, winning scope or conflict, policy version, and lease status where available.
- Stale writes return a deterministic conflict response.
- Authorization failures do not reveal cross-organization resources.

Tests: Add controller tests for success and all validation, role, conflict, not-found, malformed JSON, size-limit, and organization-isolation paths; run make test, make fmt-check, and make lint.

Out of scope: HTML UI, policy distribution, and broker behavior.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:47
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:47
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:48
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 1.9K out [1.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 4s
- Log: EXOCOMP-217__20260803T154738Z.jsonl
---
author: oompah
created: 2026-08-03 15:50
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:50
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
