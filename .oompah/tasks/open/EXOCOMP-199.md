---
id: EXOCOMP-199
type: task
status: Open
priority: 1
title: Correlate Ceph topology with coordinator inventory nodes
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-189
- EXOCOMP-197
- EXOCOMP-198
labels: []
assignee: null
created_at: '2026-07-30T21:38:23.958273Z'
updated_at: '2026-08-01T14:10:07.370951Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-199
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 8866e61026aca03ffd41b1ff7c3aff9c96ceb6301d0967ce43c4b023751eb487
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: bb526e55-9429-4afd-a304-c3cf873a2e8d
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:10:01.080716+00:00'
  claim_expires_at: '2026-08-01T14:40:01.080716+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 376538e6-e961-4cc0-a51a-0a1e8ea79bf1
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-199
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-199
  base_branch: epic-EXOCOMP-186
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:10:05.689753+00:00'
---
## Summary

Plan: plans/mission-control.md, Ceph topology reconciliation.

Deliverable: Map authoritative Ceph daemon topology to node discoveries using stable inventory hostnames and reported daemon identities.

Acceptance criteria:
- Produce one deterministic mapping or a structured missing, ambiguous, conflicting-FSID, or orphan-daemon result.
- Nodes that support the profile but contain no Ceph units remain valid non-members.
- Older nodes that cannot inspect the declared profile degrade coverage explicitly.
- Derived daemon services enter the shared desired-service resolver with source cluster:ceph.

Tests: Cover exact and case-normalized hostname matches, missing hosts, duplicate matches, FSID mismatch, orphan local units, non-member nodes, and unsupported nodes; run make test.

Out of scope: Health severity, incident creation, credentials, and recovery.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:10
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:10
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
