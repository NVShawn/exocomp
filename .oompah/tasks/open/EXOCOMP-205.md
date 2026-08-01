---
id: EXOCOMP-205
type: task
status: Open
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
updated_at: '2026-08-01T16:26:51.060435Z'
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
oompah.agent_run_id: 21250acb-0b35-403a-9bb7-a38d4b1663c3
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-205
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-205
  base_branch: epic-EXOCOMP-186
  base_sha: 7b4b2af51f12b228fbaabe25bbaa3a757e776022
  updated_at: '2026-08-01T16:08:29.023340+00:00'
oompah.task_costs:
  total_input_tokens: 471380
  total_output_tokens: 9121
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 471380
      output_tokens: 9121
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 471380
    output_tokens: 9121
    cost_usd: 0.0
    recorded_at: '2026-08-01T16:26:40.692322+00:00'
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
<!-- COMMENTS:END -->
