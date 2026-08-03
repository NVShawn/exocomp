---
id: EXOCOMP-130
type: epic
status: In Progress
priority: 1
title: 'M7C: Cluster transport and durable delivery'
parent: EXOCOMP-127
children:
- EXOCOMP-145
- EXOCOMP-146
- EXOCOMP-147
- EXOCOMP-148
- EXOCOMP-149
- EXOCOMP-150
- EXOCOMP-151
- EXOCOMP-240
blocked_by: []
start_blocked_by: []
labels:
- rebase-requested
- epic:rebasing
assignee: null
created_at: '2026-07-30T14:12:18.299606Z'
updated_at: '2026-08-03T18:32:21.032837Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan section: Connection and Delivery Protocol.

Deliver the optional coordinator client, outbound mTLS WebSocket sessions, heartbeats, reconnect behavior, durable coordinator event outbox, idempotent server ingestion, sequence acknowledgements, and durable server command delivery. Local cluster operation must not depend on this connection.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 18:32
---
Operator queue-unblock workaround for OOMPAH-733: preserved old epic head 8400a54a under recovery/epic-EXOCOMP-130-pre-parent-sync-8400a54a, rebased the remaining unique plan and EventOutbox commits onto authoritative parent epic-EXOCOMP-127 at 2d08fde7, combined current invitation configuration with EventOutbox configuration in the only source conflicts, passed git diff --check and make fmt-check, and force-pushed with exact lease to 9663f4b2. Parent is an ancestor and local/remote heads match. Ready children may resume normal dependency-ordered integration.
---
<!-- COMMENTS:END -->
