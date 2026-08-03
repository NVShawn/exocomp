---
id: EXOCOMP-227
type: task
status: Open
priority: 1
title: Enforce observe mode in Mission Control and coordinator workflows
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-216
- EXOCOMP-223
- EXOCOMP-228
labels: []
assignee: null
created_at: '2026-08-03T14:26:23.857357Z'
updated_at: '2026-08-03T15:45:09.111665Z'
work_branch: epic-EXOCOMP-211--task-EXOCOMP-227
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: d11e3b9a0fdd5d2ac3427536c1613abaf3449690d58ebd230f001e5fea435014
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 5a4d14e1-132f-46c0-8c8a-1f4eb781aed8
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:44:54.515776+00:00'
  claim_expires_at: '2026-08-03T16:14:54.515776+00:00'
  retry_count: 1
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 4252d4d9-1f3f-4839-b8f1-a747f1c870df
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-227
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-227
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:45:06.293912+00:00'
oompah.task_costs:
  total_input_tokens: 217935
  total_output_tokens: 1708
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 217935
      output_tokens: 1708
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 217935
    output_tokens: 1708
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:42:32.233730+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-227__20260803T154144Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-227
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:42:32.261366+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Gate proposals, approvals, queued execution, automatic remediation, and dispatch with the current effective policy.

Acceptance criteria:
- Observe preserves evidence collection, chat, alerts, and remedy proposals but marks proposals non-executable.
- Mission Control rejects approval and execution commands in observe.
- Coordinator resolves policy again before approval, signing, automatic action, and dispatch.
- A switch to observe invalidates pending approvals and queued execution commands with deterministic terminal reasons.
- An expired or unavailable policy is observe.

Tests: Cover manual and automatic remedies at every scope, pending approval invalidation, queued command invalidation, proposal visibility, disconnect/expiry, stale policy version, and audit failure; run make test, make fmt-check, and make lint.

Out of scope: Permit encoding, node enforcement, and operating-system execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:41
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:41
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:42
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 12
- Tokens: 217.9K in / 1.7K out [219.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 59s
- Log: EXOCOMP-227__20260803T154144Z.jsonl
---
author: oompah
created: 2026-08-03 15:45
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:45
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
