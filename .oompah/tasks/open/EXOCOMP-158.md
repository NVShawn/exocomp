---
id: EXOCOMP-158
type: task
status: Open
priority: 1
title: Store bounded conversations, messages, and evidence references
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-138
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:16.513296Z'
updated_at: '2026-08-01T12:34:45.835886Z'
work_branch: epic-EXOCOMP-132--task-EXOCOMP-158
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 832bcb18a7b711dada0dc827d18c063664c39661f8fd3d7af6aeb2fdcdfa7532
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 1c99fafe-7466-4190-a005-0fef8f326900
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:34:37.272788+00:00'
  claim_expires_at: '2026-08-01T13:04:37.272788+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 32e04359-354d-4ead-85b3-fdd498a54ce9
oompah.work_branch: epic-EXOCOMP-132--task-EXOCOMP-158
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-132--task-EXOCOMP-158
  base_branch: epic-EXOCOMP-132
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:34:43.429575+00:00'
---
## Summary

Plan: plans/mission-control.md, Conversations and Cluster-Local Reasoning.

Deliverables:
- Add organization-scoped conversations, memberships, ordered messages, and structured evidence-reference schemas.
- Support incident-attached and ad hoc cluster conversations.
- Enforce 16 KiB per message and a newest-50-messages-or-64-KiB context selector.
- Track queued, delivered, reasoning, completed, failed, and expired states.

Acceptance:
- Tests cover ordering, limits, context truncation, state transitions, incident membership, cluster membership, and organization isolation.
- Arbitrary file attachments and raw-log blobs are rejected.

Out of scope: transport and model calls.
Quality gate: focused context tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:34
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:34
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
