---
id: EXOCOMP-239
type: task
status: Open
priority: null
title: Qualify two clusters on amd64 and arm64
parent: EXOCOMP-212
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-235
- EXOCOMP-236
- EXOCOMP-237
- EXOCOMP-238
labels: []
assignee: null
created_at: '2026-08-03T14:28:24.686582Z'
updated_at: '2026-08-03T15:57:11.141928Z'
work_branch: epic-EXOCOMP-212--task-EXOCOMP-239
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: bd6670c160522d88fc38e1f6fc867b952b8fa2f454fd10a1f84664efe74f61d8
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: eaf3aada-ee0d-4254-89ea-7f22688656de
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:56:59.332462+00:00'
  claim_expires_at: '2026-08-03T16:26:59.332462+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 8beb852d-aed3-46f3-af92-9634284a87eb
oompah.work_branch: epic-EXOCOMP-212--task-EXOCOMP-239
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-212--task-EXOCOMP-239
  base_branch: epic-EXOCOMP-212
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:57:08.762214+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable:
Run final acceptance qualification against two Mission Control-connected clusters, including amd64 and arm64 nodes, and retain evidence for every plan acceptance criterion.

Acceptance criteria:
- Exercise global, cluster, cluster/service, node, and node/service settings on both architectures.
- Demonstrate precedence and the node versus cluster/service observe-wins disagreement rule.
- Demonstrate that observe permits status, diagnostics, chat, and proposals while blocking actual mutations.
- Demonstrate at least one permitted typed systemd action and one permitted shipped cluster-profile action in manage mode.
- Interrupt connectivity long enough to expire a lease and verify every layer returns to observe.
- Verify policy source, effective mode, lease state, and denial reasons are visible in Mission Control.
- Attach repeatable commands, logs, and results to the task and record any failures as oompah follow-up tasks.

Tests:
- Run the documented qualification Makefile target or VM workflow on both architectures.
- Run make test, make fmt-check, make lint, make check-links, and make test-compliance before recording final results.

Out of scope:
- Fixing unrelated defects discovered during qualification; file them as separate oompah tasks.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:57
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:57
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
