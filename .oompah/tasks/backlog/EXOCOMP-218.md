---
id: EXOCOMP-218
type: task
status: Backlog
priority: 2
title: Build management-policy LiveViews
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T14:24:22.138173Z'
updated_at: '2026-08-03T14:24:22.138173Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add Mission Control views for global, cluster, cluster/service, node, and node/service policy inspection and editing.

Acceptance criteria:
- Show configured, inherited, and effective mode; winning scope; observe-wins conflict; policy version; acknowledgement; and lease expiry.
- Observe-to-manage uses a normal confirmation dialog showing scope and resulting effective value.
- Operators see only restriction controls, admins see both modes, and viewers see no mutation controls.
- Observe-mode proposals remain visible but approval and execution controls are disabled with an explanation.
- PubSub updates active views only after policy transactions commit.

Tests: Add LiveView tests for every role and scope, inheritance, conflict, confirmation/cancel, stale update, disconnected cluster, lease expiry, proposal controls, and organization isolation; run make test, make fmt-check, and make lint.

Out of scope: Policy persistence internals, bundle delivery, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

