---
id: EXOCOMP-173
type: task
status: Open
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
updated_at: '2026-08-01T13:07:14.570401Z'
work_branch: epic-EXOCOMP-134--task-EXOCOMP-173
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 974b8b6bcb879f8b26c495c04aeef6d73b48a9b586d101e81e47ecba2dfbe798
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: c90c7691-1f0b-4fa5-ab22-654e934d86ec
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:07:03.521600+00:00'
  claim_expires_at: '2026-08-01T13:37:03.521600+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 5d6dc9e5-b0ce-494a-a6f2-a551c25c80b5
oompah.work_branch: epic-EXOCOMP-134--task-EXOCOMP-173
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-134--task-EXOCOMP-173
  base_branch: epic-EXOCOMP-134
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:07:11.425774+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:07
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:07
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
