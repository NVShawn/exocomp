---
id: EXOCOMP-214
type: task
status: Open
priority: 1
title: Map systemd and profile targets to canonical service keys
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-213
labels: []
assignee: null
created_at: '2026-08-03T14:24:11.664051Z'
updated_at: '2026-08-03T15:31:03.116952Z'
work_branch: epic-EXOCOMP-209--task-EXOCOMP-214
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 6c7da08549a6c621212b6b3d5f0b06918329b6042465d72aaf01e19d194e7015
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: inconclusive\n\
    Matches: none\nEvidence: The supplied corpus omits active EXOCOMP-209 sibling\
    \ descriptions/comments, and the task server was unavailable for authoritative\
    \ retrieval. Closest reviewed tasks (EXOCOMP-10, EXOCOMP-14, EXOCOMP-15) are terminal\
    \ and unrelated in scope.\nFocus handoff: duplicate_detector  \nDuplicate preflight\
    \ verdict: inconclusive  \nMatches: none  \n\nEvidence: The supplied corpus omits\
    \ active EXOCOMP-209 sibling descriptions/comments, and the task server was unavailable\
    \ for authoritative retrieval. Closest reviewed tasks (EXOCOMP-10, EXOCOMP-14,\
    \ EXOCOMP-15) are terminal and unrelated in scope."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: '2026-08-03T15:31:58.837188+00:00'
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 5e5400cd-0392-49af-a857-d07a3c50d28d
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-214
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-214
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:29:55.534006+00:00'
oompah.task_costs:
  total_input_tokens: 430071
  total_output_tokens: 2160
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 430071
      output_tokens: 2160
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 430071
    output_tokens: 2160
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:30:58.836188+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-214__20260803T153000Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-209--task-EXOCOMP-214
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:30:58.865901+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add the shared canonical service-key mapper used before policy resolution.

Acceptance criteria:
- Exact systemd units map to systemd:<unit> after existing strict unit validation.
- Shipped profiles map daemon instances to stable keys such as ceph:mon, ceph:mgr, and ceph:osd.
- Unknown profiles, malformed units, ambiguous mappings, and missing keys fail to observe with structured reasons.
- Mapping is deterministic across coordinator, node, broker, and serialized fixtures.

Tests: Cover ordinary and templated systemd units, every shipped Ceph role, multiple daemon instances, invalid names, unknown profiles, and fixture round trips; run make test, make fmt-check, and make lint.

Out of scope: Policy precedence, desired-service discovery, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:29
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:29
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:31
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 5
- Tokens: 430.1K in / 2.2K out [432.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 14s
- Log: EXOCOMP-214__20260803T153000Z.jsonl
---
<!-- COMMENTS:END -->
