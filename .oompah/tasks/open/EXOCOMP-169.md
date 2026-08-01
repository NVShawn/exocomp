---
id: EXOCOMP-169
type: task
status: Open
priority: 1
title: Add proposal controls and the action timeline
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-168
- EXOCOMP-162
- EXOCOMP-163
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:05.145960Z'
updated_at: '2026-08-01T13:01:28.538310Z'
work_branch: epic-EXOCOMP-133--task-EXOCOMP-169
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: b26aa4505930df5677c25a312e9c09525d0fd8b19c06dc0003bfee54613f8808
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 682f0e16-54b8-472d-b8df-136095e23cb6
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:01:19.396450+00:00'
  claim_expires_at: '2026-08-01T13:31:19.396450+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: ff6d6347-beb2-4f30-86a2-4b1d060e1a03
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-169
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-169
  base_branch: epic-EXOCOMP-133
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:01:26.232498+00:00'
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Render proposal target, action, parameters, evidence age/hash, risk, disruption, rationale, policy result, and expiry.
- Add operator approve/deny controls bound to the context guards.
- Render decision, command delivery, execution, verification, and terminal artifacts as a correlated timeline.

Acceptance:
- LiveView tests cover allowed approval, denial, offline/expired/stale/terminal disabled states, concurrent decision conflict, viewer denial, execution failure, and verification failure.
- Approved is never displayed as executed until the execution event arrives.

Out of scope: changing proposal content.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:01
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:01
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
