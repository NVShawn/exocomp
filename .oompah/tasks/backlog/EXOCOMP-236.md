---
id: EXOCOMP-236
type: task
status: Backlog
priority: null
title: Add broker and privilege-boundary security tests
parent: EXOCOMP-212
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-230
- EXOCOMP-234
labels: []
assignee: null
created_at: '2026-08-03T14:28:16.134826Z'
updated_at: '2026-08-03T14:32:02.040700Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable:
Add automated negative tests proving that untrusted processes cannot bypass the privileged broker or use malformed authorization data to mutate a node.

Acceptance criteria:
- Reject missing, expired, replayed, forged, wrongly scoped, and tampered policy bundles and action permits.
- Reject unknown actions, extra arguments, target mismatches, and requests whose resolved mode is observe.
- Verify package and sudo configuration exposes only the exact no-argument broker entry point required by the plan.
- Add a static or packaging check that detects newly introduced direct mutation sudo paths.
- Verify failures are fail-closed and emit useful audit records without leaking signing material.

Tests:
- Add focused broker, installer, and packaging negative tests.
- Run the applicable installer or packaging Makefile targets plus make test, make fmt-check, and make lint.

Out of scope:
- Implementing broker actions or operating the dual-architecture qualification environment.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

