---
id: EXOCOMP-229
type: task
status: Open
priority: 1
title: Enforce policy and permits at the node safety gate
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-226
- EXOCOMP-228
labels: []
assignee: null
created_at: '2026-08-03T14:26:29.308857Z'
updated_at: '2026-08-03T15:43:50.507022Z'
work_branch: epic-EXOCOMP-211--task-EXOCOMP-229
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 7a16b6b54aa67febf96673384a4a4b9120bfb1fe15fea03839e8794d007e43ca
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 6a5b313e-1e14-4cd6-a0fd-6b58e08213d0
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:43:33.354833+00:00'
  claim_expires_at: '2026-08-03T16:13:33.354833+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 106349cc-a4a2-43ff-aae2-76a231cf4ba2
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-229
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-229
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:43:45.427155+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Require a fresh signed policy bundle and matching action permit for every state-changing node workflow and invoke the broker through a bounded client.

Acceptance criteria:
- Direct node recovery requests without both artifacts fail as observe.
- Node verifies signatures, identities, action/target/service bindings, evidence hash, idempotency, and both expiry limits before broker invocation.
- Node independently resolves effective mode and requires manage.
- Duplicate permits return the durable prior result and cannot repeat execution.
- Diagnostic and proposal skills remain available without a permit.

Tests: Cover valid invocation, absent artifacts, every binding mismatch, observe, lease/permit expiry, replay, node restart, broker timeout/failure, diagnostic availability, and no invocation on denial; run make test, make fmt-check, and make lint.

Out of scope: Broker internals, sudoers installation, and specific action adapters.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:43
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:43
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
