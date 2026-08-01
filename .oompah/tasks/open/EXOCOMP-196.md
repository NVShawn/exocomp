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
updated_at: '2026-08-01T14:05:16.760288Z'
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
  verdict: no_duplicate
  checked_at: '2026-08-01T14:05:12.917713+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active task records EXOCOMP-186, EXOCOMP-195,\
    \ EXOCOMP-197\u2013EXOCOMP-206. EXOCOMP-195 covers the profile registry/version\
    \ contract, EXOCOMP-197 covers Ceph collection, EXOCOMP-202 covers helper packaging,\
    \ and EXOCOMP-205 covers user documentation; none owns protected coordinator configuration\
    \ validation. Terminal tasks were excluded."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
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
oompah.task_costs:
  total_input_tokens: 925743
  total_output_tokens: 5957
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 925743
      output_tokens: 5957
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 925743
    output_tokens: 5957
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:05:12.912429+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-196__20260801T140247Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-186--task-EXOCOMP-196
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:05:12.922722+00:00'
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
author: oompah
created: 2026-08-01 14:05
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 21
- Tokens: 925.7K in / 6.0K out [931.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 32s
- Log: EXOCOMP-196__20260801T140247Z.jsonl
---
<!-- COMMENTS:END -->
