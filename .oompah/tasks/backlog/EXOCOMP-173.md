---
id: EXOCOMP-173
type: task
status: Backlog
priority: 1
title: Sign, deliver, retry, and replay webhook events
parent: EXOCOMP-134
children: []
blocked_by:
- EXOCOMP-172
- EXOCOMP-171
- EXOCOMP-139
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:37.354425Z'
updated_at: '2026-07-30T14:21:48.505483Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Webhooks.

Deliverables:
- Add durable webhook events and delivery-attempt records.
- Sign event ID, delivery timestamp, and exact JSON body with HMAC-SHA256.
- Deliver with bounded timeouts and jittered exponential retry for up to 24 hours.
- Add admin inspection and manual replay that creates a new attempt for the retained event.

Acceptance:
- Tests cover signature vectors, successful delivery, duplicate-safe event ID, timeout, 4xx/5xx, retry schedule, terminal failure, disabled endpoint, rotation, replay, and redaction.
- Request bodies are byte-identical to the signed content.

Out of scope: native Slack/email/PagerDuty integrations.
Quality gate: focused delivery tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

