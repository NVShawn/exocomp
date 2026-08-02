---
id: EXOCOMP-205
type: task
status: Done
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
updated_at: '2026-08-02T03:44:48.232763Z'
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
  verdict: no_duplicate
  checked_at: '2026-08-01T16:26:40.697802+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active tasks EXOCOMP-178, 185, 186, 193, 194, 196, 197, 199,
    200, 203, 204, and 206. They cover separate implementation, protocol, Ceph collection,
    topology, health, recovery, qualification, or broader Mission Control documentation
    scopes. EXOCOMP-178 explicitly depends on EXOCOMP-205. No active task owns the
    requested combined operator documentation.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 7781a56d-65f5-401c-9386-a7fdf225830d
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-205
oompah.integration:
  version: 2
  state: integrated
  attempts: 1
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-205
  base_branch: epic-EXOCOMP-186
  base_sha: 40cda2a08fa095fc8ce41aad92b603bfe54c176f
  head_sha: 35efbaa230ecd552e2c472a89a279d2585aff186
  integrated_sha: 35efbaa230ecd552e2c472a89a279d2585aff186
  submitted_at: '2026-08-02T03:39:48.270937+00:00'
  updated_at: '2026-08-02T03:40:55.984635+00:00'
oompah.task_costs:
  total_input_tokens: 472282
  total_output_tokens: 9358
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 472282
      output_tokens: 9358
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 471380
    output_tokens: 9121
    cost_usd: 0.0
    recorded_at: '2026-08-01T16:26:40.692322+00:00'
  - profile: default
    model: haiku
    input_tokens: 902
    output_tokens: 237
    cost_usd: 0.0
    recorded_at: '2026-08-02T03:40:17.706854+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-205__20260801T160834Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-186--task-EXOCOMP-205
    source_sha: 7b4b2af51f12b228fbaabe25bbaa3a757e776022
    completed_at: '2026-08-01T16:26:40.706782+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-bdbf1b1d5cf2: '2026-08-02T03:44:46.191924+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-205
    target_state: Done
    evidence_fingerprint: 77317d1368bda8add455e9dfd450fc9201759e82e79f8d076234e88665d9cc92
    audit_ids:
    - audit-8379ab4792f2
    kind: result
    applied: true
    retired_at: '2026-08-02T03:44:46.191939+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-205
    audit_id: audit-8379ab4792f2
    attempt_id: attempt-bdbf1b1d5cf2
    target_state: Done
    evidence_fingerprint: 77317d1368bda8add455e9dfd450fc9201759e82e79f8d076234e88665d9cc92
    status: Done
    audit_ids:
    - audit-8379ab4792f2
    applied: false
    created_at: '2026-08-02T03:44:46.191962+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-8379ab4792f2
    project_id: proj-c260b117
    task_id: EXOCOMP-205
    target_state: Done
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 77317d1368bda8add455e9dfd450fc9201759e82e79f8d076234e88665d9cc92
    attempts:
    - version: 1
      attempt_id: attempt-bdbf1b1d5cf2
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 77317d1368bda8add455e9dfd450fc9201759e82e79f8d076234e88665d9cc92
      created_at: '2026-08-02T03:41:02.671545+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-02T03:41:02.671545+00:00'
      branch_key: epic-EXOCOMP-186--task-EXOCOMP-205
      verdict: pass
      completed_at: '2026-08-02T03:44:46.191676+00:00'
      ended_at: '2026-08-02T03:44:46.191676+00:00'
    requested_by:
      version: 1
      identity: oompah-integration
      source: service
    previous_state: Ready to Integrate
    created_at: '2026-08-02T03:40:57.169724+00:00'
    updated_at: '2026-08-02T03:44:46.191676+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-bdbf1b1d5cf2
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 77317d1368bda8add455e9dfd450fc9201759e82e79f8d076234e88665d9cc92
    created_at: '2026-08-02T03:41:02.671545+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-02T03:41:02.671545+00:00'
    branch_key: epic-EXOCOMP-186--task-EXOCOMP-205
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
author: oompah
created: 2026-08-01 16:26
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 4, Tool calls: 145
- Tokens: 471.4K in / 9.1K out [480.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 18m 17s
- Log: EXOCOMP-205__20260801T160834Z.jsonl
---
author: oompah
created: 2026-08-02 03:33
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-02 03:33
---
Focus: Callback Auth Validation Specialist
---
author: oompah
created: 2026-08-02 03:34
---
Understanding: Task is to create user-facing documentation for desired-state modes, Ceph profile operations, manual/automatic service management, credential bootstrap, and troubleshooting. Dependencies (EXOCOMP-197/198/199/200/203/204) have been integrated. Starting by exploring codebase to understand implemented functionality.
---
author: oompah
created: 2026-08-02 03:35
---
Discovery: Project is a distributed AI agent system with node and coordinator components. Existing docs cover installation, PKI ops, policy, lifecycle, and Ceph profiles. Task requires new docs for: (1) manual service lists configuration, (2) automatic service monitoring features, (3) Ceph profile activation workflow, (4) credential bootstrap for Ceph, (5) coverage errors and unsupported nodes, (6) safe restart behavior with policy system. Examining implementation to identify exact features to document.
---
author: oompah
created: 2026-08-02 03:37
---
Implementation: Created comprehensive docs/service-management.md covering (1) manual service list configuration and allow-lists, (2) automatic enabled-service monitoring for Ceph, (3) Ceph profile activation workflow, (4) credential bootstrap with least-privilege cephx caps, (5) coverage errors and troubleshooting, (6) safe restart behavior with policy enforcement. Document includes configuration examples, validation procedures, and v1-to-v2 migration guidance.
---
author: oompah
created: 2026-08-02 03:39
---
Verification: Documentation tests pass successfully. Ran: (1) make check-links - PASS, (2) test_operator_docs.py - all 7 tests PASS including shell command parsing, documented flags, required topics, bundle layout, PKI ceremony, qualification guidance, and index linking. Documentation provides complete coverage of manual service lists, automatic monitoring, Ceph profile activation, credential bootstrap, coverage errors, and safe restart behavior with troubleshooting guides.
---
author: oompah
created: 2026-08-02 03:39
---
Comprehensive user-facing documentation for desired-state modes and Ceph profile operations complete. Covers manual service lists, automatic enabled-service monitoring, Ceph profile activation and credential bootstrap with least-privilege cephx capabilities, coverage error troubleshooting, and safe restart behavior with policy enforcement. All documentation tests pass including link validation and shell command parsing. Added v1-to-v2 migration guide with configuration examples.
---
author: oompah
created: 2026-08-02 03:39
---
Completion: EXOCOMP-205 submitted. Deliverable: docs/service-management.md (22.8 KB, comprehensive guide) plus updated docs/README.md index. Documentation covers: (1) manual service lists with allow-list configuration, sudoers generation, and health checks; (2) automatic enabled-service monitoring for Ceph daemons; (3) Ceph profile activation workflow with validation; (4) credential bootstrap with client.exocomp least-privilege cephx caps (mon/mgr/osd/mds read-only); (5) coverage errors with 7 troubleshooting scenarios; (6) safe restart behavior with automatic (failed) vs approval-required (active/degraded) policy. Includes v1-to-v2 migration guide and configuration examples. All acceptance criteria met. Tests: check-links PASS, test-compliance (pre-existing failures in scripts, not docs), test_operator_docs.py 7/7 PASS.
---
author: oompah
created: 2026-08-02 03:40
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 0, Tool calls: 53
- Tokens: 902 in / 237 out [1.1K total]
- Cost: $0.0000
- Exit: terminated, Duration: 6m 39s
- Log: EXOCOMP-205__20260802T033350Z.jsonl
---
author: oompah
created: 2026-08-02 03:40
---
Queued for terminal transition to Done. An auditor will review and apply the terminal status.
---
author: oompah
created: 2026-08-02 03:41
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-02 03:41
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-02 03:44
---
Audit PASS — Done

[REDACTED]

Safe evidence:
- branch_head: 35efbaa230ecd552e2c472a89a279d2585aff186
- commit_stat: docs/README.md +2; docs/service-management.md +653; total +655 lines
- pushed_to_origin: origin/epic-EXOCOMP-186--task-EXOCOMP-205 and origin/epic-EXOCOMP-186 both point at HEAD
- test_operator_docs: 7 tests pass (unittest discover)
- test_check_compliance: 9 tests pass (unittest discover)
- acceptance_criteria_1_config_and_v1_v2: docs/service-management.md contains validated JSON config examples and a 'Migration Guide: v1 to v2' section
- acceptance_criteria_2_cephx_caps: client.exocomp created with mon/mgr/osd/mds 'allow r' and keyring modes 0600/0640 documented
- acceptance_criteria_3_authority_split: Automatic mode is diagnostics-only; approval-required restart for active/degraded services; fail-closed policy documented
- acceptance_criteria_4_troubleshooting: Sections for unsupported nodes, topology mismatches, stale evidence, helper denial, cooldown all present
- acceptance_criteria_5_no_broad_ceph_repair: Ceph collector documented as read-only; profile does not automatically restart Ceph daemons
- sandbox_limits: Raw `make check-links` and `python3 scripts/check_compliance.py --check links` blocked by auditor sandbox; verified via unittest discover of tests/test_check_compliance.py which exercises the same link-check code path
---
<!-- COMMENTS:END -->
