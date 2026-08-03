---
id: EXOCOMP-223
type: task
status: Open
priority: 1
title: Renew policy leases and fall back to observe on expiry
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-222
labels: []
assignee: null
created_at: '2026-08-03T14:25:17.678179Z'
updated_at: '2026-08-03T15:39:01.683768Z'
work_branch: epic-EXOCOMP-210--task-EXOCOMP-223
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 4aa594617a73fcff8ea1298cd2434863dbcb70c2bcc95f33feb06fe8b164e5e1
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: inconclusive\n\
    Matches: none\nEvidence: The supplied corpus lacks full descriptions, statuses,\
    \ and comments for the relevant peers (EXOCOMP-210, EXOCOMP-219\u2013222, EXOCOMP-224,\
    \ EXOCOMP-227), so an active duplicate cannot be confirmed or excluded. No files\
    \ or tracker state were modified.\nFocus handoff: duplicate_detector  \nDuplicate\
    \ preflight verdict: inconclusive  \nMatches: none\n\nEvidence: The supplied corpus\
    \ lacks full descriptions, statuses, and comments for the relevant peers (EXOCOMP-210,\
    \ EXOCOMP-219\u2013222, EXOCOMP-224, EXOCOMP-227), so an active duplicate cannot\
    \ be confirmed or excluded. No files or tracker state were modified."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: '2026-08-03T15:39:55.651474+00:00'
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 9f23cb53-e0ba-4759-a5b7-3af67d1c3fd5
oompah.work_branch: epic-EXOCOMP-210--task-EXOCOMP-223
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-210--task-EXOCOMP-223
  base_branch: epic-EXOCOMP-210
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:37:36.443232+00:00'
oompah.task_costs:
  total_input_tokens: 317977
  total_output_tokens: 1520
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 317977
      output_tokens: 1520
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 317977
    output_tokens: 1520
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:38:55.648375+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-223__20260803T153747Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-210--task-EXOCOMP-223
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:38:55.670617+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add Mission Control renewal and coordinator lease-timer behavior with a five-minute default and validated configuration.

Acceptance criteria:
- Lease configuration accepts 60 through 3600 seconds; renewal defaults to 60 seconds and must be below half the lease.
- Mission Control issues fresh signed bundles without changing policy version when only the lease changes.
- Coordinator timers use monotonic time while running and validated wall time after restart.
- Expiry atomically switches all effective policy to observe, invalidates pending execution, and writes durable audit state.
- Reconnect requires a fresh bundle before manage resumes.

Tests: Use injectable clocks for bounds, renewal, delayed delivery, disconnect, clock movement, restart before/after expiry, invalid configuration, pending-work invalidation, and reconnection; run make test, make fmt-check, and make lint.

Out of scope: Action execution and LiveView rendering.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:37
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:37
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:38
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 3
- Tokens: 318.0K in / 1.5K out [319.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 24s
- Log: EXOCOMP-223__20260803T153747Z.jsonl
---
<!-- COMMENTS:END -->
