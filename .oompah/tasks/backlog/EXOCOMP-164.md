---
id: EXOCOMP-164
type: task
status: Backlog
priority: 2
title: Build the authenticated LiveView shell and navigation
parent: EXOCOMP-133
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:55.693389Z'
updated_at: '2026-07-30T14:16:55.693389Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Add the authenticated root layout, navigation, flash/error handling, organization context, and role-aware route guards.
- Add reusable components for connectivity, health, severity, timestamps, empty states, and loading/error states.
- Redirect unauthenticated users through OIDC and show a bounded forbidden page for denied roles.

Acceptance:
- LiveView tests cover unauthenticated, viewer, operator, and admin navigation.
- Organization and actor identity survive reconnect without being accepted from client parameters.
- Accessibility checks cover landmarks, focus, labels, and keyboard navigation.

Out of scope: feature pages.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

