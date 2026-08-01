---
id: EXOCOMP-205
type: task
status: Open
priority: 2
title: Document desired-state modes and Ceph profile operations
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-188
- EXOCOMP-195
- EXOCOMP-204
labels: []
assignee: null
created_at: '2026-07-30T21:38:37.688511Z'
updated_at: '2026-08-01T16:08:32.561199Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-205
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: b8b019986cadb62c28285b4ab33395e07efb79ea382c6d5789d0c9f9d060aef6
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 07d18e6c-13d7-4034-b061-679969a4d3f8
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T16:08:21.169109+00:00'
  claim_expires_at: '2026-08-01T16:38:21.169109+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 21250acb-0b35-403a-9bb7-a38d4b1663c3
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-205
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-205
  base_branch: epic-EXOCOMP-186
  base_sha: 7b4b2af51f12b228fbaabe25bbaa3a757e776022
  updated_at: '2026-08-01T16:08:29.023340+00:00'
---
## Summary

Plan: plans/mission-control.md, operator documentation.

Deliverable: Add user-facing documentation for manual service lists, automatic enabled-service monitoring, Ceph profile activation, credential bootstrap, coverage errors, and safe restart behavior.

Acceptance criteria:
- Include validated configuration examples and v1-to-v2 upgrade guidance.
- Document the client.exocomp least-privilege cephx caps and secret-file permissions.
- Explain monitoring versus recovery authority and why automatic mode cannot broaden privileges.
- Include troubleshooting for unsupported nodes, topology mismatches, stale evidence, helper denial, and cooldown.
- State that broad Ceph repair remains unavailable.

Tests: Run make check-links, make test-compliance, and documentation fixture tests.

Out of scope: Implementing configuration, collectors, or repair actions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 16:08
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 16:08
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
