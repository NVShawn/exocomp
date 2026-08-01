---
id: EXOCOMP-196
type: task
status: Open
priority: 1
title: Validate Ceph profile configuration and read-only credentials
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-195
labels: []
assignee: null
created_at: '2026-07-30T21:38:18.558307Z'
updated_at: '2026-08-01T14:02:46.911189Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-196
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: a03743bc0cb5768c8457f1924bc0c71e5d799f4774b7c2bd7f219a52690e6384
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 4393493c-8cba-4e3f-a276-7730fa7e9a53
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T14:02:39.848371+00:00'
  claim_expires_at: '2026-08-01T14:32:39.848371+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: bc9be6e8-7378-4c32-afef-0ba3c06b48c5
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-196
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-196
  base_branch: epic-EXOCOMP-186
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:02:44.919230+00:00'
---
## Summary

Plan: plans/mission-control.md, Ceph profile configuration.

Deliverable: Add protected coordinator configuration for a fixed Ceph binary, ceph.conf, and client.exocomp keyring.

Acceptance criteria:
- Profile activation requires exact absolute paths and a supported profile version.
- Startup validates file existence, ownership, keyring permissions, and executable identity without logging key material.
- Missing or unsafe configuration degrades profile coverage and emits an actionable audit event instead of crashing unrelated monitoring.
- Documentation specifies read-only mon, mgr, osd, and mds cephx capabilities.

Tests: Cover valid configuration, missing files, relative paths, unsafe permissions, wrong ownership, absent binary, and secret redaction; run make test.

Out of scope: Creating Ceph credentials automatically, parsing Ceph command output, and remediation.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:02
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:02
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
