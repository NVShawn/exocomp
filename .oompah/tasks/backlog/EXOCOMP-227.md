---
id: EXOCOMP-227
type: task
status: Backlog
priority: 1
title: Enforce observe mode in Mission Control and coordinator workflows
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T14:26:23.857357Z'
updated_at: '2026-08-03T14:26:23.857357Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Gate proposals, approvals, queued execution, automatic remediation, and dispatch with the current effective policy.

Acceptance criteria:
- Observe preserves evidence collection, chat, alerts, and remedy proposals but marks proposals non-executable.
- Mission Control rejects approval and execution commands in observe.
- Coordinator resolves policy again before approval, signing, automatic action, and dispatch.
- A switch to observe invalidates pending approvals and queued execution commands with deterministic terminal reasons.
- An expired or unavailable policy is observe.

Tests: Cover manual and automatic remedies at every scope, pending approval invalidation, queued command invalidation, proposal visibility, disconnect/expiry, stale policy version, and audit failure; run make test, make fmt-check, and make lint.

Out of scope: Permit encoding, node enforcement, and operating-system execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

