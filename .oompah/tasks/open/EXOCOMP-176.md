---
id: EXOCOMP-176
type: task
status: Open
priority: 1
title: Package the Mission Control release and OCI image
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-136
- EXOCOMP-137
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:18:27.819781Z'
updated_at: '2026-08-01T11:49:54.948718Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md, Deployment and Operations.

Deliverables:
- Add a production Mission Control OTP release and reproducible OCI image using the repository pinned builder conventions.
- Provide explicit noninteractive database migrate and server commands.
- Run as an unprivileged user with a read-only root filesystem except documented state paths.
- Add manifest, checksum, SBOM, provenance, and license coverage.

Acceptance:
- Packaging tests start the image against PostgreSQL, run migrations once, restart safely, reject missing secrets, and inspect runtime dependencies.
- No build tools, source tree, credentials, or test fixtures are shipped.

Out of scope: Kubernetes manifests and final qualification.
Quality gate: focused packaging tests plus repository release-check targets.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

