---
id: EXOCOMP-128
type: epic
status: In Validation
priority: 1
title: 'M7A: Mission Control foundation and persistence'
parent: EXOCOMP-127
children:
- EXOCOMP-136
- EXOCOMP-137
- EXOCOMP-138
- EXOCOMP-139
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:12:16.107664Z'
updated_at: '2026-08-03T21:58:37.487502Z'
work_branch: epic-EXOCOMP-128
target_branch: epic-EXOCOMP-127
review_url: https://github.com/NVShawn/exocomp/pull/21
review_number: '21'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/21
oompah.review_number: '21'
oompah.work_branch: epic-EXOCOMP-128
oompah.target_branch: epic-EXOCOMP-127
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-9e721291b92b: '2026-08-01T16:25:28.504381+00:00'
    attempt-effb31c964f7: '2026-08-01T16:30:15.211519+00:00'
    attempt-492d64b9af7b: '2026-08-03T21:18:25.726717+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-128
    target_state: Done
    evidence_fingerprint: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    audit_ids:
    - audit-8dacff3cc8f3
    kind: result
    applied: true
    retired_at: '2026-08-01T16:25:28.504389+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-128
    target_state: Merged
    evidence_fingerprint: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    audit_ids:
    - audit-8bf58132f5c0
    - audit-f33556e74f5c
    kind: result
    applied: false
    retired_at: '2026-08-01T16:30:15.211532+00:00'
    lifecycle_reconciled: true
    reconciled_to: Done
    retired_reason: shared_epic_parent_not_landed
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-128
    audit_id: audit-8dacff3cc8f3
    attempt_id: attempt-9e721291b92b
    target_state: Done
    evidence_fingerprint: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    status: In Validation
    audit_ids:
    - audit-8dacff3cc8f3
    applied: true
    created_at: '2026-08-01T16:25:28.504399+00:00'
    applied_at: '2026-08-01T16:25:31.272739+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-128
    audit_id: audit-8bf58132f5c0
    attempt_id: attempt-effb31c964f7
    target_state: Merged
    evidence_fingerprint: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    status: Merged
    audit_ids:
    - audit-8bf58132f5c0
    applied: true
    created_at: '2026-08-01T16:30:15.211546+00:00'
    applied_at: '2026-08-01T16:30:19.106664+00:00'
    retired_by_reconciliation: true
    retired_reason: shared_epic_parent_not_landed
    reconciled_at: '2026-08-03T21:21:52.974456+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-128
    audit_id: audit-f33556e74f5c
    attempt_id: attempt-492d64b9af7b
    target_state: Merged
    evidence_fingerprint: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    status: Merged
    audit_ids:
    - audit-f33556e74f5c
    applied: true
    created_at: '2026-08-03T21:18:25.726751+00:00'
    applied_at: '2026-08-03T21:18:30.916142+00:00'
    retired_by_reconciliation: true
    retired_reason: shared_epic_parent_not_landed
    reconciled_at: '2026-08-03T21:21:52.974456+00:00'
  oompah.terminal_override_records: []
  oompah.lifecycle_reconciliations:
  - project_id: proj-c260b117
    task_id: EXOCOMP-128
    from: Merged
    to: Done
    reason: shared_epic_parent_not_landed
    conflict: 'Cannot transition shared-epic child EXOCOMP-128 to Merged: parent epic
      EXOCOMP-127 could not be verified. The parent review must land on its configured
      target branch first.'
    done_audit_ids:
    - audit-8dacff3cc8f3
    created_at: '2026-08-03T20:06:03.322283+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-128
    from: Merged
    to: Done
    reason: shared_epic_parent_not_landed
    conflict: 'Cannot transition shared-epic child EXOCOMP-128 to Merged: parent epic
      EXOCOMP-127 could not be verified. The parent review must land on its configured
      target branch first.'
    done_audit_ids:
    - audit-8dacff3cc8f3
    created_at: '2026-08-03T21:21:52.974456+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-8dacff3cc8f3
    project_id: proj-c260b117
    task_id: EXOCOMP-128
    target_state: Done
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    attempts:
    - version: 1
      attempt_id: attempt-9e721291b92b
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
      created_at: '2026-08-01T16:18:25.073295+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T16:18:25.073295+00:00'
      branch_key: epic-EXOCOMP-128
      verdict: pass
      completed_at: '2026-08-01T16:25:28.504274+00:00'
      ended_at: '2026-08-01T16:25:28.504274+00:00'
    requested_by:
      version: 1
      identity: NVShawn
      source: forge
    previous_state: In Review
    created_at: '2026-08-01T16:17:53.124916+00:00'
    updated_at: '2026-08-01T16:25:28.504274+00:00'
  - version: 1
    audit_id: audit-8bf58132f5c0
    project_id: proj-c260b117
    task_id: EXOCOMP-128
    target_state: Merged
    request_state: superseded
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    attempts:
    - version: 1
      attempt_id: attempt-effb31c964f7
      target_state: Merged
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
      created_at: '2026-08-01T16:25:53.991925+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T16:25:53.991925+00:00'
      branch_key: epic-EXOCOMP-128
      verdict: pass
      completed_at: '2026-08-01T16:30:15.211387+00:00'
      ended_at: '2026-08-01T16:30:15.211387+00:00'
    requested_by:
      version: 1
      identity: NVShawn
      source: forge
    previous_state: In Review
    created_at: '2026-08-01T16:17:53.124916+00:00'
    updated_at: '2026-08-03T20:06:03.322283+00:00'
  - version: 1
    audit_id: audit-f33556e74f5c
    project_id: proj-c260b117
    task_id: EXOCOMP-128
    target_state: Merged
    request_state: superseded
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    attempts:
    - version: 1
      attempt_id: attempt-6332a7bf1fe6
      target_state: Merged
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
      created_at: '2026-08-03T20:48:57.386035+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-03T20:48:57.386035+00:00'
      branch_key: epic-EXOCOMP-128
      failure_classification: infrastructure_error
      ended_at: '2026-08-03T20:55:00.309604+00:00'
      failure_reason: normal
      next_retry_at: '2026-08-03T20:55:10.309580+00:00'
    - version: 1
      attempt_id: attempt-492d64b9af7b
      target_state: Merged
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
      created_at: '2026-08-03T20:57:23.874488+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-08-03T20:57:23.874488+00:00'
      branch_key: epic-EXOCOMP-128
      candidate_rotation_count: 1
      verdict: pass
      completed_at: '2026-08-03T21:18:25.726505+00:00'
      ended_at: '2026-08-03T21:18:25.726505+00:00'
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: In Review
    created_at: '2026-08-03T20:43:53.494982+00:00'
    updated_at: '2026-08-03T21:21:52.974456+00:00'
  - version: 1
    audit_id: audit-87c928b700fb
    project_id: proj-c260b117
    task_id: EXOCOMP-128
    target_state: Merged
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    attempts: []
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: In Review
    created_at: '2026-08-03T21:58:34.950936+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-9e721291b92b
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    created_at: '2026-08-01T16:18:25.073295+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T16:18:25.073295+00:00'
    branch_key: epic-EXOCOMP-128
  - version: 1
    attempt_id: attempt-effb31c964f7
    target_state: Merged
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    created_at: '2026-08-01T16:25:53.991925+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T16:25:53.991925+00:00'
    branch_key: epic-EXOCOMP-128
  - version: 1
    attempt_id: attempt-6332a7bf1fe6
    target_state: Merged
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    created_at: '2026-08-03T20:48:57.386035+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-03T20:48:57.386035+00:00'
    branch_key: epic-EXOCOMP-128
    failure_classification: infrastructure_error
    ended_at: '2026-08-03T20:55:00.309604+00:00'
    failure_reason: normal
    next_retry_at: '2026-08-03T20:55:10.309580+00:00'
  - version: 1
    attempt_id: attempt-492d64b9af7b
    target_state: Merged
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 938d45f0c64e41b72f8473b32531bbded81d1a8391503c5edf4a654bac9ee9d7
    created_at: '2026-08-03T20:57:23.874488+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-08-03T20:57:23.874488+00:00'
    branch_key: epic-EXOCOMP-128
    candidate_rotation_count: 1
oompah.task_costs:
  total_input_tokens: 123
  total_output_tokens: 24466
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 123
      output_tokens: 24466
      cost_usd: 0.0
  runs:
  - profile: auditor
    model: unknown
    input_tokens: 56
    output_tokens: 9653
    cost_usd: 0.0
    recorded_at: '2026-08-01T16:25:41.238539+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 47
    output_tokens: 1382
    cost_usd: 0.0
    recorded_at: '2026-08-01T16:30:41.631121+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 6
    output_tokens: 2823
    cost_usd: 0.0
    recorded_at: '2026-08-03T20:54:57.020143+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 14
    output_tokens: 10608
    cost_usd: 0.0
    recorded_at: '2026-08-03T21:19:51.692062+00:00'
---
## Summary

Plan sections: Architecture; Organization and Operator Identity; Persistence and Retention.

Deliver the Phoenix LiveView application skeleton, PostgreSQL/Ecto foundation, mandatory organization scope, and versioned Mission Control event/command protocol types. This epic establishes shared interfaces only; feature-specific fleet, incident, chat, and webhook behavior belongs to later epics.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 16:17
---
Queued for terminal transition to Merged. An auditor will review and apply the terminal status.
---
author: oompah
created: 2026-08-01 16:17
---
YOLO: merged PR #21.
---
author: oompah
created: 2026-08-01 16:18
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 16:18
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-01 16:25
---
Audit PASS — Done

[REDACTED]

Safe evidence:
- epic_head: f34b7d15612196d3963bcaa9378278ba2e142e50
- merge_commit: 2476a39252e92b4690337d7fe706d1b28781bd60
- pr_number: 21
- child_136_commits: 3a3d6e61,074712f0
- child_137_commit: f1d8f1c0
- child_138_commits: 90653c52,f34b7d15
- child_139_commit: 778b0ae5
- phoenix_app_path: apps/exocomp_mission_control
- protocol_module_path: apps/exocomp_coordinator/lib/exocomp/coordinator/mission_control
- codec_test_path: apps/exocomp_coordinator/test/exocomp/coordinator/mission_control/codec_test.exs
- migrations_dir: apps/exocomp_mission_control/priv/repo/migrations
- makefile_db_target: test-mission-control-db
---
author: oompah
created: 2026-08-01 16:25
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 58, Tool calls: 50
- Tokens: 56 in / 9.7K out [9.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 7m 14s
- Log: EXOCOMP-128__20260801T161837Z.jsonl
---
author: oompah
created: 2026-08-01 16:25
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 16:25
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-01 16:30
---
Audit PASS — Merged

[REDACTED]

Safe evidence:
- merge_commit: 2476a39252e92b4690337d7fe706d1b28781bd60
- epic_head: f34b7d15612196d3963bcaa9378278ba2e142e50
- first_parent: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
- second_parent: f34b7d15612196d3963bcaa9378278ba2e142e50
- pr_number: 21
- merge_branch: origin/epic-EXOCOMP-127
- merge_subject: Merge pull request #21 from NVShawn/epic-EXOCOMP-128
- child_136_commits: 3a3d6e61,074712f0
- child_137_commit: f1d8f1c0
- child_138_commits: 90653c52,f34b7d15
- child_139_commit: 778b0ae5
- phoenix_app_mix_deps_verified: phoenix,phoenix_live_view,phoenix_pubsub,bandit,ecto_sql,postgrex,jason
- codec_test_lines: 965
- makefile_db_target: test-mission-control-db
- files_changed_in_merge: 42
- insertions: 3058
- organization_scope_module: apps/exocomp_mission_control/lib/exocomp/mission_control/organization_scope.ex
- baseline_migration: apps/exocomp_mission_control/priv/repo/migrations/20260801000000_create_mission_control_schema.exs
---
author: oompah
created: 2026-08-01 16:30
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 0, Tool calls: 28
- Tokens: 47 in / 1.4K out [1.4K total]
- Cost: $0.0000
- Exit: terminated, Duration: 4m 47s
- Log: EXOCOMP-128__20260801T162559Z.jsonl
---
author: oompah
created: 2026-08-03 20:06
---
Lifecycle reconciliation restored EXOCOMP-128 to audited Done: Cannot transition shared-epic child EXOCOMP-128 to Merged: parent epic EXOCOMP-127 could not be verified. The parent review must land on its configured target branch first.
---
author: oompah
created: 2026-08-03 20:49
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-03 20:49
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-03 20:55
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 2, Tool calls: 0
- Tokens: 6 in / 2.8K out [2.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 5m 53s
- Log: EXOCOMP-128__20260803T204914Z.jsonl
---
author: oompah
created: 2026-08-03 20:55
---
Auditor attempt ended: auditor exited (normal) without a result. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-03 20:57
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-08-03 20:57
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-03 21:18
---
Audit PASS — Merged

[REDACTED]

Safe evidence:
- merge_commit: 2476a39252e92b4690337d7fe706d1b28781bd60
- pr_number: 21
- merge_subject: Merge pull request #21 from NVShawn/epic-EXOCOMP-128
- merge_parents: 8f80aebf f34b7d15
- files_changed: 42
- insertions: 3058
- ancestor_of_epic_EXOCOMP_127: confirmed (exit_code=0)
- phoenix_app_path: apps/exocomp_mission_control
- phoenix_deps_verified: phoenix,phoenix_live_view,phoenix_pubsub,bandit,ecto_sql,postgrex,jason
- organization_scope_module: apps/exocomp_mission_control/lib/exocomp/mission_control/organization_scope.ex
- baseline_migration: apps/exocomp_mission_control/priv/repo/migrations/20260801000000_create_mission_control_schema.exs
- protocol_module_path: apps/exocomp_coordinator/lib/exocomp/coordinator/mission_control
- codec_test_path: apps/exocomp_coordinator/test/exocomp/coordinator/mission_control/codec_test.exs
- codec_test_coverage: events/commands/acknowledgements/batch/encode/decode/round-trip/edge-cases
- epic_EXOCOMP_127_head: 2d08fde7 EXOCOMP-127: deliver audited prerequisites
- downstream_commits_on_epic_branch: approximately 20 Mission Control feature commits after EXOCOMP-128 merge
---
author: oompah
created: 2026-08-03 21:19
---
Run #2 [attempt=2, profile=auditor, role=auditor -> Claude/sonnet]
- Turns: 32, Tool calls: 20
- Tokens: 14 in / 10.6K out [10.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 22m 8s
- Log: EXOCOMP-128__20260803T205755Z.jsonl
---
author: oompah
created: 2026-08-03 21:21
---
Lifecycle reconciliation restored EXOCOMP-128 to audited Done: Cannot transition shared-epic child EXOCOMP-128 to Merged: parent epic EXOCOMP-127 could not be verified. The parent review must land on its configured target branch first.
---
<!-- COMMENTS:END -->
