---
id: EXOCOMP-136
type: task
status: Backlog
priority: 2
title: Scaffold the Mission Control Phoenix application
parent: EXOCOMP-128
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:13:49.889616Z'
updated_at: '2026-07-30T14:13:49.889616Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Architecture.

Deliverables:
- Add a new Phoenix LiveView application to the umbrella with a separate Mission Control OTP release.
- Add a minimal endpoint, router, supervision tree, static asset pipeline, and GET /health response.
- Keep the application independent from node and coordinator startup.

Acceptance:
- The application starts in test mode and the health route returns 200.
- A focused endpoint test and application supervision test pass.
- Existing node/coordinator tests remain unchanged.

Out of scope: PostgreSQL schemas, authentication, fleet pages, and container packaging.
Quality gate: make fmt-check, make test, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

