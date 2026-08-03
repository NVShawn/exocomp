---
id: EXOCOMP-229
type: task
status: Open
priority: 1
title: Enforce policy and permits at the node safety gate
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-226
- EXOCOMP-228
labels: []
assignee: null
created_at: '2026-08-03T14:26:29.308857Z'
updated_at: '2026-08-03T15:50:22.290741Z'
work_branch: epic-EXOCOMP-211--task-EXOCOMP-229
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 7a16b6b54aa67febf96673384a4a4b9120bfb1fe15fea03839e8794d007e43ca
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 71fd843a-e4b6-4a63-ba9f-37eec3959dfb
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:50:05.462625+00:00'
  claim_expires_at: '2026-08-03T16:20:05.462625+00:00'
  retry_count: 2
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 8b24c8f5-e8ab-4c83-8160-80a345cadb13
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-229
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-229
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:50:19.832005+00:00'
oompah.task_costs:
  total_input_tokens: 107990
  total_output_tokens: 3747
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 107990
      output_tokens: 3747
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2114
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:44:54.627143+00:00'
  - profile: default
    model: haiku
    input_tokens: 107980
    output_tokens: 1633
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:47:22.472839+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-229__20260803T154351Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-229
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:44:54.631765+00:00'
  - run_id: EXOCOMP-229__20260803T154618Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-229
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:47:22.489130+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Require a fresh signed policy bundle and matching action permit for every state-changing node workflow and invoke the broker through a bounded client.

Acceptance criteria:
- Direct node recovery requests without both artifacts fail as observe.
- Node verifies signatures, identities, action/target/service bindings, evidence hash, idempotency, and both expiry limits before broker invocation.
- Node independently resolves effective mode and requires manage.
- Duplicate permits return the durable prior result and cannot repeat execution.
- Diagnostic and proposal skills remain available without a permit.

Tests: Cover valid invocation, absent artifacts, every binding mismatch, observe, lease/permit expiry, replay, node restart, broker timeout/failure, diagnostic availability, and no invocation on denial; run make test, make fmt-check, and make lint.

Out of scope: Broker internals, sudoers installation, and specific action adapters.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
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
author: oompah
created: 2026-08-03 15:44
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 2.1K out [2.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 13s
- Log: EXOCOMP-229__20260803T154351Z.jsonl
---
author: oompah
created: 2026-08-03 15:46
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:46
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:47
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 11
- Tokens: 108.0K in / 1.6K out [109.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 13s
- Log: EXOCOMP-229__20260803T154618Z.jsonl
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
