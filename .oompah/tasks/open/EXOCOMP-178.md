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
updated_at: '2026-08-01T15:50:44.602290Z'
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
  verdict: no_duplicate
  checked_at: '2026-08-01T15:50:41.193869+00:00'
  matched_identifiers: []
  evidence: "This coordination message further confirms my investigation result. EXOCOMP-170\
    \ has completed implementation work on \"Mission Control administration LiveViews\"\
    \ \u2014 this is feature development, not documentation. This reinforces that\
    \ **EXOCOMP-178 remains a non-duplicate task** for the separate concern of documenting\
    \ that completed implementation.\n\nMy final verdict stands:\n\n**Focus handoff:\
    \ duplicate_detector**\n\n**Duplicate preflight verdict: no_duplicate**\n\n**Matches:\
    \ none**\n\n**Evidence:** EXOCOMP-178 is a legitimate documentation task for Mission\
    \ Control. The coordination message from EXOCOMP-170 (implementation of LiveViews)\
    \ confirms the blocking dependencies are building the Mission Control features\
    \ that EXOCOMP-178 will document. No existing active tasks or documentation cover\
    \ the installation, configuration, and operational procedures for Mission Control.\
    \ The existing operator documentation is specific to Exocomp Node/Coordinator\
    \ (Milestone 6), while EXOCOMP-178 addresses Mission Control documentation (Milestone\
    \ 7)."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
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
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 394
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 394
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 394
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:50:41.192201+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-178__20260801T154520Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-178
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T15:50:41.205980+00:00'
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
author: oompah
created: 2026-08-01 15:50
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 64, Tool calls: 28
- Tokens: 10 in / 394 out [404 total]
- Cost: $0.0000
- Exit: normal, Duration: 5m 26s
- Log: EXOCOMP-178__20260801T154520Z.jsonl
---
<!-- COMMENTS:END -->
