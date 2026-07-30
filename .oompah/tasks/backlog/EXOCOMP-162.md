---
id: EXOCOMP-162
type: task
status: Backlog
priority: 1
title: Implement operator approval and denial guards
parent: EXOCOMP-132
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:20.549186Z'
updated_at: '2026-07-30T14:16:20.549186Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Typed Remedy Approval.

Deliverables:
- Add operator/admin context functions to approve or deny one pending proposal.
- Reject approval when the cluster is disconnected, proposal expired, evidence freshness elapsed, proposal terminal, or operator lacks role.
- Persist the decision and actor audit fields transactionally, then enqueue one typed approval command.
- Never queue an approval for later when the cluster is offline.

Acceptance:
- Tests cover every guard, duplicate/concurrent decisions, denial reason, queue failure rollback, viewer denial, and organization mismatch.
- An accepted decision is not represented as executed.

Out of scope: local revalidation and LiveView controls.
Quality gate: focused approval tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

