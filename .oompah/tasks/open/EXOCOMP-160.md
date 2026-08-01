---
id: EXOCOMP-160
type: task
status: Open
priority: 1
title: Deliver conversation commands and evidence-linked replies
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-158
- EXOCOMP-159
- EXOCOMP-149
- EXOCOMP-150
- EXOCOMP-151
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:18.620833Z'
updated_at: '2026-08-01T12:38:42.500010Z'
work_branch: epic-EXOCOMP-132--task-EXOCOMP-160
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: afb9c231849f2a633a8619e19e400dad474643c8f297ea056bba78b73614d7eb
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 0fd07e69-68f5-46e4-aa17-58455c9df243
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:38:31.409638+00:00'
  claim_expires_at: '2026-08-01T13:08:31.409638+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 726b1b64-3355-4510-a569-e8c83bbf84d1
oompah.work_branch: epic-EXOCOMP-132--task-EXOCOMP-160
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-132--task-EXOCOMP-160
  base_branch: epic-EXOCOMP-132
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:38:39.374611+00:00'
---
## Summary

Plan: plans/mission-control.md, Conversations and Cluster-Local Reasoning.

Deliverables:
- Translate an operator message into a durable server command addressed to one connected cluster.
- Handle coordinator conversation.reply results and persist Markdown plus structured evidence IDs, node identities, and observation timestamps.
- Update delivery/reasoning/terminal states only from committed command and event transitions.
- Mark unsupported or stale claims explicitly.

Acceptance:
- Tests cover online delivery, offline queue display, reconnect, duplicate reply, failed reasoning, expired command, invalid citation, and organization/cluster mismatch.
- UI-facing state never labels an unacknowledged command delivered.

Out of scope: LiveView rendering and proposals.
Quality gate: focused context/transport tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:38
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:38
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
