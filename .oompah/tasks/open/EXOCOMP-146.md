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
updated_at: '2026-08-01T12:11:18.572951Z'
work_branch: epic-EXOCOMP-130--task-EXOCOMP-146
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: e89e27b3fcf6b07f45d8bc5633fc0ace9c4e108c95db7a100a80b4ac8266591a
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: eee815c1-ea26-4398-b2b6-e1f9675cf103
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:11:06.187470+00:00'
  claim_expires_at: '2026-08-01T12:41:06.187470+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 3b3f1553-7461-4c11-abbd-6b7d5e197bfc
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-146
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-146
  base_branch: epic-EXOCOMP-130
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:11:15.869531+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:11
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:11
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
