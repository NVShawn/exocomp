---
id: EXOCOMP-165
type: task
status: In Progress
priority: 2
title: Build the fleet overview LiveView
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-164
- EXOCOMP-152
- EXOCOMP-155
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:58.020040Z'
updated_at: '2026-08-01T15:18:41.338092Z'
work_branch: epic-EXOCOMP-133--task-EXOCOMP-165
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 8bdc46b38dfb6fd4d3ffb049596cc67c32cbca1a319939044eb2391e7f82a71f
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T15:18:14.413721+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed EXOCOMP-164 (shell), EXOCOMP-152 (status\
    \ persistence), EXOCOMP-155 (health rules), and sibling UI tasks EXOCOMP-166\u2013\
    170. Their scopes are distinct foundations or feature views; none duplicates the\
    \ fleet overview LiveView."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 4b806305-bd64-4142-b644-1f8f7c465d7f
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-165
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-165
  base_branch: epic-EXOCOMP-133
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:18:39.651979+00:00'
oompah.task_costs:
  total_input_tokens: 328548
  total_output_tokens: 4331
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 328548
      output_tokens: 4331
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 328548
    output_tokens: 4331
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:18:14.412872+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-165__20260801T151425Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-133--task-EXOCOMP-165
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T15:18:14.420445+00:00'
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Render cluster connectivity, health/severity counts, versions, node counts, labels, last contact, and open incident counts.
- Add organization-scoped filters and deterministic sorting.
- Subscribe to committed PubSub updates and update only affected rows.

Acceptance:
- LiveView tests cover empty/loading/error states, filters, sorting, connect/disconnect updates, health updates, and organization isolation.
- A disconnected cluster is visually distinct from a healthy connected cluster.
- Viewer access is read-only.

Out of scope: cluster detail and incident mutations.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:14
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:14
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 15:18
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 2, Tool calls: 39
- Tokens: 328.5K in / 4.3K out [332.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 58s
- Log: EXOCOMP-165__20260801T151425Z.jsonl
---
author: oompah
created: 2026-08-01 15:18
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 15:18
---
Focus: Maintenance Engineer
---
<!-- COMMENTS:END -->
