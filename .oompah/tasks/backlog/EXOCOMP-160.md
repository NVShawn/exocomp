---
id: EXOCOMP-160
type: task
status: Backlog
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
updated_at: '2026-07-30T14:21:27.075752Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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

