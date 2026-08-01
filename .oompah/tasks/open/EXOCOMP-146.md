---
id: EXOCOMP-146
type: task
status: Open
priority: 1
title: Connect coordinators over an outbound mTLS WebSocket
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-145
- EXOCOMP-144
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:02.496448Z'
updated_at: '2026-08-01T11:48:55.619353Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Cluster Enrollment and Connection Protocol.

Deliverables:
- Implement the coordinator WebSocket client for GET /api/v1/clusters/connect using TLS 1.3, server trust validation, and its enrolled client certificate.
- Implement the Mission Control upgrade endpoint, extract organization/cluster identity only from the validated certificate, reject revoked certificates, and create a random session ID.
- Enforce one live session per cluster; a newer authenticated session supersedes the old one.

Acceptance:
- Integration tests cover success, missing/wrong certificate, wrong trust root, revoked identity, payload identity spoofing, and session replacement.
- No inbound listener is added to the coordinator.

Out of scope: heartbeat, replay, and domain events.
Quality gate: focused transport tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

