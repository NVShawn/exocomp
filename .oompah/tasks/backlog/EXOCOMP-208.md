---
id: EXOCOMP-208
type: epic
status: Backlog
priority: 1
title: 'M8: Hierarchical observe/manage policy'
parent: null
children:
- EXOCOMP-209
- EXOCOMP-210
- EXOCOMP-211
- EXOCOMP-212
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T14:23:02.893809Z'
updated_at: '2026-08-03T14:23:28.582368Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
---
## Summary

Triggered by: EXOCOMP-127

Plan: plans/hierarchical-management-modes.md

Outcome: Implement global, cluster, cluster/service, node, and node/service observe/manage policy after Mission Control is complete. The default is observe; observe preserves diagnostics and proposals but blocks every mutation; manage only permits the existing deterministic safety pipeline to consider an action.

Required invariants:
- This epic and every descendant have a hard-start dependency on EXOCOMP-127.
- More-specific policy overrides less-specific policy, with observe winning node versus cluster/service disagreement.
- Cached manage authority is leased and expires to observe.
- Every mutation is enforced by the privileged broker.
- Upgrade creates no implicit manage policy.

The work is decomposed into area epics and focused junior-sized tasks. Each task links the plan and includes acceptance criteria, tests, and explicit out-of-scope boundaries.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

