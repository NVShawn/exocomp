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
updated_at: '2026-08-01T13:09:05.953898Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-176
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 4a6f8158709e1ee2895f9ef8fd058289fc251a62fe0f746557d674cc2bb84598
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 8d3696d6-a1a7-44ca-a959-0af98856eaca
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:08:54.667849+00:00'
  claim_expires_at: '2026-08-01T13:38:54.667849+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 8fecdb5f-7bca-4f10-80a7-e0864f883dea
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-176
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-176
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:09:02.126669+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:08
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:09
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
