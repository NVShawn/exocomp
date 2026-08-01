---
id: EXOCOMP-178
type: task
status: Open
priority: 2
title: Document Mission Control installation and operations
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-144
- EXOCOMP-170
- EXOCOMP-173
- EXOCOMP-174
- EXOCOMP-175
- EXOCOMP-176
- EXOCOMP-177
start_blocked_by: &id001
- EXOCOMP-205
labels: []
assignee: null
created_at: '2026-07-30T14:18:32.596455Z'
updated_at: '2026-08-01T15:45:19.908606Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-178
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 9dad50b2fea27555dc4e182a0c5e2d374ae53b8f495717610cd791199ad299d5
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: f851a996-399e-4acb-8f1f-dede9a67380d
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T15:45:12.419009+00:00'
  claim_expires_at: '2026-08-01T16:15:12.419009+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 28c32ca2-c980-47d0-9303-9e0323559ff2
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-178
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-178
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:45:18.178569+00:00'
---
## Summary

Plan: plans/mission-control.md, Deployment and Operations.

Deliverables:
- Add user-facing docs for VM and Kubernetes installation, PostgreSQL, OIDC, Mission Control PKI ceremonies, cluster enrollment/revocation, webhook verification, retention, upgrades, and troubleshooting.
- Add database backup/restore and certificate/secret rotation procedures with verification and rollback steps.
- Link the guides from docs/README.md and the release checklist.

Acceptance:
- Documentation command tests validate all repository-local commands and configuration examples.
- A clean operator walkthrough can install, enroll a cluster, back up, restore, rotate, and uninstall without source-tree assumptions.
- Mermaid is used for diagrams.

Out of scope: hosted-service operations.
Quality gate: make check-links, make compliance-check, and focused operator-doc tests.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: include and link the operator documentation delivered by EXOCOMP-205 for inventory v2, all three monitoring paths, Ceph credential bootstrap, profile coverage troubleshooting, safe restart, and monitoring-versus-recovery authority.
---
author: oompah
created: 2026-08-01 15:45
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:45
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
