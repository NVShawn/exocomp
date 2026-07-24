---
id: EXOCOMP-1
type: epic
status: Merged
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
updated_at: '2026-07-24T03:15:00.584379Z'
work_branch: epic-EXOCOMP-1
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/8
review_number: '8'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/8
oompah.review_number: '8'
oompah.work_branch: epic-EXOCOMP-1
oompah.target_branch: main
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
<!-- COMMENTS:END -->
