---
id: EXOCOMP-7
type: feature
status: Open
priority: 1
title: Scaffold the Elixir umbrella and quality gates
parent: EXOCOMP-1
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T19:08:52.964005Z'
updated_at: '2026-07-23T19:21:15.626597Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: e9fe845f-6fd6-4075-8329-4486e0e1de90
oompah.work_branch: epic-EXOCOMP-1
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Scaffold the Elixir umbrella and quality gates.

Implementation
Create the Elixir 1.20/OTP 28 umbrella with shared core/protocol, node, and coordinator applications; configure separate node and coordinator releases with ERTS; pin exact toolchain and builder versions; replace placeholder Make targets with non-interactive build, test, lint, format, and format-check targets.

Testing
Run every Make target from a clean checkout; add ExUnit smoke tests that start each application in test mode and build both releases.

Acceptance Criteria
- [ ] Clean checkout builds without host Elixir when using the pinned builder.
- [ ] Both releases contain ERTS and start in test mode.
- [ ] make build, make test, make lint, and make fmt-check pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 19:20
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 19:20
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
