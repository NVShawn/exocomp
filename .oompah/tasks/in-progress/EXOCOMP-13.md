---
id: EXOCOMP-13
type: chore
status: In Progress
priority: 1
title: Verify the M1 node-agent milestone
parent: EXOCOMP-1
children: []
blocked_by:
- EXOCOMP-12
labels: []
assignee: null
created_at: '2026-07-23T19:08:57.920933Z'
updated_at: '2026-07-24T02:30:11.796684Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 1dd15b50-0f8b-49cf-a311-4312326fa14a
oompah.work_branch: epic-EXOCOMP-1
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Verify the M1 node-agent milestone.

Implementation
Build a clean Linux integration fixture using test certificates and fake or pinned llama.cpp; exercise release startup, Agent Card discovery, diagnostics, proposal failure behavior, task lifecycle, concurrency, and shutdown; collect evidence for every M1 acceptance criterion.

Testing
Run the full ExUnit/integration suite and make build, make test, make lint, and make fmt-check; verify the fixture host state before and after.

Acceptance Criteria
- [ ] Every M1-CRIT-* item in the plan has recorded pass/fail evidence.
- [ ] The node release works without development tooling.
- [ ] The end-to-end test proves no host state change.
- [ ] All repository quality gates pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:30
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:30
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
