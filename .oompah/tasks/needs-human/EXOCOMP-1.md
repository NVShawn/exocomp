---
id: EXOCOMP-1
type: epic
status: Needs Human
priority: 1
title: 'M1: Prototype Elixir node agent'
parent: null
children:
- EXOCOMP-7
- EXOCOMP-8
- EXOCOMP-9
- EXOCOMP-10
- EXOCOMP-11
- EXOCOMP-12
- EXOCOMP-13
- EXOCOMP-93
- EXOCOMP-94
blocked_by: []
labels:
- epic:rebasing
assignee: null
created_at: '2026-07-23T19:07:34.132470Z'
updated_at: '2026-07-31T04:15:14.356989Z'
work_branch: epic-EXOCOMP-1
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/8
review_number: '8'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/8
oompah.review_number: '8'
oompah.work_branch: epic-EXOCOMP-1
oompah.target_branch: main
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-587b1d655ca0: '2026-07-31T04:15:05.910387+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-89016608bf79
    project_id: proj-c260b117
    task_id: EXOCOMP-1
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
    attempts:
    - version: 1
      attempt_id: attempt-587b1d655ca0
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
      created_at: '2026-07-31T04:12:20.147318+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-31T04:12:20.147318+00:00'
      branch_key: epic-EXOCOMP-1
      verdict: fail
      failure_classification: unsafe_archive
      completed_at: '2026-07-31T04:15:05.910192+00:00'
      ended_at: '2026-07-31T04:15:05.910192+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-31T04:12:14.491522+00:00'
    updated_at: '2026-07-31T04:15:05.910192+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-587b1d655ca0
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
    created_at: '2026-07-31T04:12:20.147318+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-31T04:12:20.147318+00:00'
    branch_key: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 46
  total_output_tokens: 8762
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 46
      output_tokens: 8762
      cost_usd: 0.0
  runs:
  - profile: auditor
    model: unknown
    input_tokens: 46
    output_tokens: 8762
    cost_usd: 0.0
    recorded_at: '2026-07-31T04:15:12.304538+00:00'
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Deliver the diagnostic-only Elixir node-agent milestone described in the linked design.

Scope
Coordinate the child tasks for the umbrella foundation, A2A protocol types, node identity and TLS, Linux diagnostics, llama.cpp supervision, the node A2A service, and milestone acceptance testing. The node must not expose or perform state-changing actions in this milestone.

Testing
All child-task tests and the complete M1 integration suite must pass through repository Make targets.

Acceptance Criteria
- [ ] Every child task is complete and its focused tests pass.
- [ ] Every M1-CRIT-* criterion in the linked plan has recorded evidence.
- [ ] The node release performs authenticated diagnostics without modifying host state.
- [ ] make build, make test, make lint, and make fmt-check pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 03:10
---
YOLO: merged PR #8.
---
author: oompah
created: 2026-07-31 04:12
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-07-31 04:12
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-07-31 04:12
---
Focus: Completion Auditor
---
author: oompah
created: 2026-07-31 04:15
---
Needs Human — Archived audit requires operator input.

[REDACTED]

Instructions:
- Do not archive while task state is not Merged. Return the aged-Merged auto-archive to the queue only after the task re-enters Merged with all children in terminal (Merged/Archived/Done) states.
- Because the 'epic:rebasing' label is present, treat this epic as active and skip auto-archival until the rebase-and-revalidate cycle completes and the label is removed.
---
author: oompah
created: 2026-07-31 04:15
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 50, Tool calls: 40
- Tokens: 46 in / 8.8K out [8.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 50s
- Log: EXOCOMP-1__20260731T041228Z.jsonl
---
<!-- COMMENTS:END -->
