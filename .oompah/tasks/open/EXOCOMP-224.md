---
id: EXOCOMP-224
type: task
status: Open
priority: 2
title: Report policy version, lease, and enforcement status
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-223
labels: []
assignee: null
created_at: '2026-08-03T14:25:19.911306Z'
updated_at: '2026-08-03T15:49:38.644308Z'
work_branch: epic-EXOCOMP-210--task-EXOCOMP-224
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 30d32a07fb721bc85e506f06f5abc43f31f57a0a355a8d6f4e9d93feb715b8c7
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: inconclusive\n\
    Matches: none\nEvidence: The supplied corpus omits the active EXOCOMP-210 peer\
    \ tasks named in context, so duplicate screening cannot reliably compare them.\
    \ Reviewed historical tasks EXOCOMP-14 and EXOCOMP-15 are terminal and unrelated.\
    \ No files or tracker state were modified.\nFocus handoff: duplicate_detector\
    \  \nDuplicate preflight verdict: inconclusive  \nMatches: none  \n\nEvidence:\
    \ The supplied corpus omits the active EXOCOMP-210 peer tasks named in context,\
    \ so duplicate screening cannot reliably compare them. Reviewed historical tasks\
    \ EXOCOMP-14 and EXOCOMP-15 are terminal and unrelated. No files or tracker state\
    \ were modified."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: '2026-08-03T15:50:34.374464+00:00'
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 9c3f3942-19d2-43d6-984d-54c74e376e66
oompah.work_branch: epic-EXOCOMP-210--task-EXOCOMP-224
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-210--task-EXOCOMP-224
  base_branch: epic-EXOCOMP-210
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:48:20.215415+00:00'
oompah.task_costs:
  total_input_tokens: 219057
  total_output_tokens: 1831
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 219057
      output_tokens: 1831
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 219057
    output_tokens: 1831
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:49:34.373529+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-224__20260803T154824Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-210--task-EXOCOMP-224
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:49:34.382722+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Extend coordinator heartbeats, status snapshots, Mission Control persistence, and metrics with policy enforcement state.

Acceptance criteria:
- Report applied policy version, lease expiry, signing-key ID, enforcement protocol version, effective-mode summary, and last rejection/fallback reason.
- Mission Control distinguishes pending delivery, applied, rejected, expired, disconnected, and unsupported states.
- Status reduction is sequence-safe, idempotent, organization-scoped, and bounded.
- Metrics count apply/reject/expire/fallback transitions without target or service cardinality explosion.

Tests: Add protocol, reducer, persistence, duplicate/out-of-order, restart, PubSub, metrics, redaction, and organization-isolation tests; run make test, make fmt-check, and make lint.

Out of scope: Policy editing UI, broker execution, and qualification.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:48
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:48
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:49
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 2
- Tokens: 219.1K in / 1.8K out [220.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 18s
- Log: EXOCOMP-224__20260803T154824Z.jsonl
---
<!-- COMMENTS:END -->
