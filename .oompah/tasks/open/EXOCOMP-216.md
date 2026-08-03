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
updated_at: '2026-08-03T16:19:48.426162Z'
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
  verdict: no_duplicate
  checked_at: '2026-08-03T16:19:45.604689+00:00'
  matched_identifiers: []
  evidence: Owner reviewed the active EXOCOMP-209 task family. EXOCOMP-213 defines
    policy types, EXOCOMP-214 maps service keys, EXOCOMP-215 persists policies, EXOCOMP-217
    exposes HTTP APIs, and EXOCOMP-218 builds the UI; EXOCOMP-216 alone implements
    transactional mutation authorization and audit. No equivalent active task exists.
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: '2026-08-03T16:19:45.604689+00:00'
  owner_login: oompah-cli
  owner_resolution_reason: Owner reviewed the active EXOCOMP-209 task family. EXOCOMP-213
    defines policy types, EXOCOMP-214 maps service keys, EXOCOMP-215 persists policies,
    EXOCOMP-217 exposes HTTP APIs, and EXOCOMP-218 builds the UI; EXOCOMP-216 alone
    implements transactional mutation authorization and audit. No equivalent active
    task exists.
oompah.agent_run_id: 09144930-380a-4595-a562-5e4393e3f59f
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-216
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-216
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:38:39.571963+00:00'
oompah.task_costs:
  total_input_tokens: 1514543
  total_output_tokens: 7481
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 1514543
      output_tokens: 7481
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 493671
    output_tokens: 2274
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:32:00.640667+00:00'
  - profile: default
    model: haiku
    input_tokens: 359212
    output_tokens: 2539
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:36:07.802694+00:00'
  - profile: default
    model: haiku
    input_tokens: 661660
    output_tokens: 2668
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:40:31.394972+00:00'
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
  - run_id: EXOCOMP-216__20260803T153434Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-209--task-EXOCOMP-216
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:36:07.817749+00:00'
  - run_id: EXOCOMP-216__20260803T153845Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-209--task-EXOCOMP-216
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:40:31.416726+00:00'
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
author: oompah
created: 2026-08-03 15:34
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:34
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:36
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 5
- Tokens: 359.2K in / 2.5K out [361.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 51s
- Log: EXOCOMP-216__20260803T153434Z.jsonl
---
author: oompah
created: 2026-08-03 15:38
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:38
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:40
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 6
- Tokens: 661.7K in / 2.7K out [664.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 59s
- Log: EXOCOMP-216__20260803T153845Z.jsonl
---
author: oompah
created: 2026-08-03 15:40
---
Duplicate screening was inconclusive 3 times. Human action required: a project owner must review the authoritative task corpus and use the authenticated duplicate-screening owner-resolution action (POST /api/v1/issues/EXOCOMP-216/duplicate-screening/owner-resolution) with a conclusive verdict and reason. This records the owner decision, resets the retry budget, and returns no_duplicate tasks to Open (or routes a verified duplicate to Duplicate Candidate). A plain verdict comment is not authoritative.
---
<!-- COMMENTS:END -->
