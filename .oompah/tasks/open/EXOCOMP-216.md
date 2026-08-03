---
id: EXOCOMP-216
type: task
status: Open
priority: 1
title: Enforce policy mutation authorization and auditing
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-214
- EXOCOMP-215
labels: []
assignee: null
created_at: '2026-08-03T14:24:17.168394Z'
updated_at: '2026-08-03T15:32:06.491460Z'
work_branch: epic-EXOCOMP-209--task-EXOCOMP-216
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 94d8ec70989c4cae677576c6db83da1707a701a5ff634e5692ae100733bf9a57
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: inconclusive\n\
    Matches: none\nEvidence: The supplied corpus lacks full descriptions/comments\
    \ for active peers EXOCOMP-209, 213\u2013215, 217\u2013218, and 227, so duplicate\
    \ status cannot be confirmed. Reviewed terminal tasks EXOCOMP-14 and EXOCOMP-16\
    \ are distinct historical coordinator/audit and PKI scopes.\nFocus handoff: duplicate_detector\
    \  \nDuplicate preflight verdict: inconclusive  \nMatches: none\n\nEvidence: The\
    \ supplied corpus lacks full descriptions/comments for active peers EXOCOMP-209,\
    \ 213\u2013215, 217\u2013218, and 227, so duplicate status cannot be confirmed.\
    \ Reviewed terminal tasks EXOCOMP-14 and EXOCOMP-16 are distinct historical coordinator/audit\
    \ and PKI scopes."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: '2026-08-03T15:33:00.642690+00:00'
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: f315b346-763b-4d8b-81ef-0eb8ee301723
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-216
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-216
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:30:20.469042+00:00'
oompah.task_costs:
  total_input_tokens: 493671
  total_output_tokens: 2274
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 493671
      output_tokens: 2274
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 493671
    output_tokens: 2274
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:32:00.640667+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-216__20260803T153032Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-209--task-EXOCOMP-216
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:32:00.655038+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add Mission Control context functions that authorize and audit every management-policy mutation.

Acceptance criteria:
- Admins may set either mode and remove overrides.
- Operators may only preserve or reduce effective authority and cannot delete an override when inheritance broadens authority.
- Viewers cannot mutate policy.
- Authorization is evaluated against the post-change effective result within the same transaction.
- Successful and rejected changes record actor, scope, before/after values, version, organization, and correlation ID without secrets.

Tests: Cover every role, every scope, direct and indirect broadening, concurrent stale version, cross-organization IDs, audit failure rollback, and deletion inheritance; run make test, make fmt-check, and make lint.

Out of scope: Web controllers, LiveView, distribution, and execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:30
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:30
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:32
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 5
- Tokens: 493.7K in / 2.3K out [495.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 45s
- Log: EXOCOMP-216__20260803T153032Z.jsonl
---
<!-- COMMENTS:END -->
