---
id: EXOCOMP-145
type: task
status: Backlog
priority: 1
title: Add optional Mission Control coordinator configuration
parent: EXOCOMP-130
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:01.267951Z'
updated_at: '2026-07-30T14:15:01.267951Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Rollout and Connection Protocol.

Deliverables:
- Add a versioned coordinator configuration block for Mission Control URL, trust root, client certificate/key paths, heartbeat interval, reconnect bounds, and outbox path.
- Validate paths, TLS settings, and numeric bounds at startup.
- Start the Mission Control client supervision subtree only when the block is present and enabled.

Acceptance:
- Existing coordinator behavior is unchanged when configuration is absent.
- Invalid partial configuration fails with actionable bounded errors.
- Tests prove Mission Control disablement cannot stop local inventory, diagnostics, or recovery.

Out of scope: network connections and enrollment.
Quality gate: focused configuration/supervision tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

