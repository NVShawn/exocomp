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
updated_at: '2026-08-01T11:52:55.954829Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
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
<!-- COMMENTS:END -->
