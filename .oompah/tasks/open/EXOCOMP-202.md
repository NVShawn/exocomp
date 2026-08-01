---
id: EXOCOMP-202
type: task
status: Open
priority: 1
title: Package the profile helper with exact sudo authorization
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-201
labels: []
assignee: null
created_at: '2026-07-30T21:38:33.244906Z'
updated_at: '2026-08-01T14:17:07.107564Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-202
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: c2919d420c4e11b546e9bf47bda6a138e512fc2fb07a47de176fd011c267510e
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 9a593d84-abc3-4d3d-8c3e-deb4837d1900
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:16:58.753460+00:00'
  claim_expires_at: '2026-08-01T14:46:58.753460+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 69ab5a61-c7d8-412b-a0e3-e9adca646d06
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-202
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-202
  base_branch: epic-EXOCOMP-186
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:17:04.652999+00:00'
---
## Summary

Plan: plans/mission-control.md, profile helper packaging.

Deliverable: Install the profile helper as a root-owned executable and grant the node account one exact no-argument sudo command for it.

Acceptance criteria:
- Release archives include both supported architectures and record the helper in manifests and SBOMs.
- Installer sets root ownership and non-writable executable permissions.
- Sudoers grants only the exact helper path with no arguments; direct systemctl wildcard privileges are not added.
- Upgrade, dry-run, rollback, and uninstall handle the helper and sudoers entry idempotently.
- visudo validation failure rolls back the policy installation.

Tests: Extend installer, packaging, tamper-detection, upgrade, uninstall, and sudoers tests; run make test-installer, make test-release-packaging, and make test-bundle.

Out of scope: Helper parsing logic, recovery policy, and Ceph health collection.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:17
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:17
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
