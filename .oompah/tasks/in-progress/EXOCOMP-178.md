---
id: EXOCOMP-178
type: task
status: In Progress
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
updated_at: '2026-08-02T04:13:12.551043Z'
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
oompah.agent_run_id: d71347eb-48a7-4070-a518-4e0be51211c0
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-178
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-178
  base_branch: epic-EXOCOMP-135
  base_sha: 333c3b81b8bcdd448166707f28b5a00ee8e2c469
  updated_at: '2026-08-02T04:13:10.399774+00:00'
oompah.task_costs:
  total_input_tokens: 9624132
  total_output_tokens: 49235
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 394
      cost_usd: 0.0
    sonnet:
      input_tokens: 9624122
      output_tokens: 48841
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 394
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:50:41.192201+00:00'
  - profile: standard
    model: sonnet
    input_tokens: 9624122
    output_tokens: 48841
    cost_usd: 0.0
    recorded_at: '2026-08-02T04:12:46.112326+00:00'
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
  - run_id: EXOCOMP-178__20260802T035519Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-terra
    focus: callback_auth
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-178
    source_sha: 74d6049b1e2c1da5c9537c5e07f393135b692dc4
    completed_at: '2026-08-02T04:12:46.116585+00:00'
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
author: oompah
created: 2026-08-02 03:44
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-02 03:44
---
Focus: Callback Auth Validation Specialist
---
author: oompah
created: 2026-08-02 03:45
---
Understanding: I will audit the Mission Control implementation and existing docs, then add source-tree-independent operator guides covering installation, auth/PKI, enrollment, webhooks, retention, backup/restore, rotation, upgrades, troubleshooting, and uninstall. I will also incorporate the EXOCOMP-205 inventory/monitoring/Ceph/restart/authority guidance, link docs and release checklist entries, validate examples with the repository's Makefile gates, then commit, push, and submit.
---
author: oompah
created: 2026-08-02 03:49
---
Discovery: the synced parent provides the Mission Control OCI contract (, , ), read-only UID 10001:10001 runtime, state/log mounts, digest-pinned PostgreSQL image test, and , , ,  interfaces. The roadmap defines OIDC/PKI/enrollment, retention, webhook, and cluster authority contracts; EXOCOMP-205 adds the required inventory-v2, three monitoring paths, Ceph bootstrap, coverage troubleshooting, safe-restart, and monitoring-versus-recovery guidance. I will document these as source-tree-independent operator procedures and make the command tests cover the new pages.
---
author: oompah
created: 2026-08-02 03:54
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 65
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 10m 4s
- Log: EXOCOMP-178__20260802T034500Z.jsonl
---
author: oompah
created: 2026-08-02 03:55
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-08-02 03:55
---
Focus: Callback Auth Validation Specialist
---
author: oompah
created: 2026-08-02 04:12
---
Agent completed successfully in 1054s (9672963 tokens)
---
author: oompah
created: 2026-08-02 04:12
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/gpt-5.6-terra]
- Turns: 1, Tool calls: 146
- Tokens: 9.6M in / 48.8K out [9.7M total]
- Cost: $0.0000
- Exit: normal, Duration: 17m 34s
- Log: EXOCOMP-178__20260802T035519Z.jsonl
---
author: oompah
created: 2026-08-02 04:12
---
Agent completed without closing this issue (1054s (9672963 tokens)). Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-08-02 04:13
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-08-02 04:13
---
Focus: Callback Auth Validation Specialist
---
<!-- COMMENTS:END -->
