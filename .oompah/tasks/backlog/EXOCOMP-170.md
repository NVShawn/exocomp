---
id: EXOCOMP-170
type: task
status: Backlog
priority: 2
title: Build Mission Control administration LiveViews
parent: EXOCOMP-133
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:05.961611Z'
updated_at: '2026-07-30T14:17:05.961611Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Add admin pages for invitation creation, cluster certificate/status display, revocation, OIDC role mappings, retention settings, and webhook endpoint navigation.
- Show invitation plaintext once and clear it after navigation.
- Require confirmation for cluster revocation and record the admin action.

Acceptance:
- LiveView tests cover admin access, viewer/operator denial, invitation one-time display, revocation confirmation, invalid role mapping, retention bounds, and organization isolation.
- Secrets and private keys are never rendered.

Out of scope: webhook delivery-attempt implementation.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

