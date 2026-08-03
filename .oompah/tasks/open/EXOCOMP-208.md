---
id: EXOCOMP-208
type: epic
status: Open
priority: 1
title: 'M8: Hierarchical observe/manage policy'
parent: null
children:
- EXOCOMP-209
- EXOCOMP-210
- EXOCOMP-211
- EXOCOMP-212
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
labels: []
assignee: null
created_at: '2026-08-03T14:23:02.893809Z'
updated_at: '2026-08-03T16:21:39.192941Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 14:35
---
Planning handoff complete. The plan is committed and pushed on main at 4e013110 (plans/hierarchical-management-modes.md). The tracker graph contains four area epics and 27 junior-scoped leaf tasks. Audit verified all 32 new records carry a hard-start dependency on EXOCOMP-127, every leaf has the required specification sections, and all 53 internal dependency edges are present. Validation passed: make check-links; make test-compliance PYTHON=/home/shedwards/src/oompah/.venv/bin/python; git diff --check.
---
<!-- COMMENTS:END -->
