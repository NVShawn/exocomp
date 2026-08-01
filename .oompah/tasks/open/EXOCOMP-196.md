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
updated_at: '2026-08-01T11:50:19.796101Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
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

