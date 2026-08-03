---
id: EXOCOMP-236
type: task
status: Open
priority: null
title: Add broker and privilege-boundary security tests
parent: EXOCOMP-212
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-230
- EXOCOMP-234
labels: []
assignee: null
created_at: '2026-08-03T14:28:16.134826Z'
updated_at: '2026-08-03T15:53:08.369186Z'
work_branch: epic-EXOCOMP-212--task-EXOCOMP-236
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: e1e24cc1f1fdf59b4829e1cb1ace27917212d4e7a147bf55781aa99e0fe75e10
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 6bc2da7b-73ed-41ad-bed8-9ba4ee544659
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:52:49.077171+00:00'
  claim_expires_at: '2026-08-03T16:22:49.077171+00:00'
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: abdc34ed-8a52-4aa2-8833-dbfbbd288eb7
oompah.work_branch: epic-EXOCOMP-212--task-EXOCOMP-236
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-212--task-EXOCOMP-236
  base_branch: epic-EXOCOMP-212
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:53:05.551074+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable:
Add automated negative tests proving that untrusted processes cannot bypass the privileged broker or use malformed authorization data to mutate a node.

Acceptance criteria:
- Reject missing, expired, replayed, forged, wrongly scoped, and tampered policy bundles and action permits.
- Reject unknown actions, extra arguments, target mismatches, and requests whose resolved mode is observe.
- Verify package and sudo configuration exposes only the exact no-argument broker entry point required by the plan.
- Add a static or packaging check that detects newly introduced direct mutation sudo paths.
- Verify failures are fail-closed and emit useful audit records without leaking signing material.

Tests:
- Add focused broker, installer, and packaging negative tests.
- Run the applicable installer or packaging Makefile targets plus make test, make fmt-check, and make lint.

Out of scope:
- Implementing broker actions or operating the dual-architecture qualification environment.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:52
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:53
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
