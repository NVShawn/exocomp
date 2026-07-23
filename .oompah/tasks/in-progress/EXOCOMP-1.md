---
id: EXOCOMP-1
type: epic
status: In Progress
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
blocked_by: []
labels:
- epic:stale
assignee: null
created_at: '2026-07-23T19:07:34.132470Z'
updated_at: '2026-07-23T22:49:24.451941Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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

