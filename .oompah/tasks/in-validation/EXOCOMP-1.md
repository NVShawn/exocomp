---
id: EXOCOMP-1
type: epic
status: In Validation
priority: 1
title: 'M1: Prototype Elixir node agent'
parent: null
children:
- EXOCOMP-7
- EXOCOMP-8
- EXOCOMP-9
- EXOCOMP-10
- EXOCOMP-11
- EXOCOMP-12
- EXOCOMP-13
- EXOCOMP-93
- EXOCOMP-94
blocked_by: []
labels:
- epic:rebasing
assignee: null
created_at: '2026-07-23T19:07:34.132470Z'
updated_at: '2026-08-07T11:15:03.292894Z'
work_branch: epic-EXOCOMP-1
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/8
review_number: '8'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/8
oompah.review_number: '8'
oompah.work_branch: epic-EXOCOMP-1
oompah.target_branch: main
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-587b1d655ca0: '2026-07-31T04:15:05.910387+00:00'
    attempt-fb8d7e9d1798: '2026-07-31T04:40:35.904060+00:00'
    attempt-6bf9ac5e9f1a: '2026-07-31T05:56:12.430513+00:00'
    attempt-379413328a1d: '2026-08-07T09:38:39.941844+00:00'
    attempt-ccf2cb332c9b: '2026-08-07T10:45:48.897019+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-1
    target_state: Archived
    evidence_fingerprint: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
    audit_ids:
    - audit-a8043727fea8
    kind: result
    applied: true
    retired_at: '2026-08-07T09:38:39.941857+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-1
    target_state: Done
    evidence_fingerprint: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
    audit_ids:
    - audit-c199fcd84f4b
    kind: result
    applied: true
    retired_at: '2026-08-07T10:45:48.897036+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-1
    audit_id: audit-a8043727fea8
    attempt_id: attempt-379413328a1d
    target_state: Archived
    evidence_fingerprint: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
    status: Needs Human
    audit_ids:
    - audit-a8043727fea8
    applied: true
    created_at: '2026-08-07T09:38:39.941875+00:00'
    applied_at: '2026-08-07T09:38:49.658700+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-1
    audit_id: audit-c199fcd84f4b
    attempt_id: attempt-ccf2cb332c9b
    target_state: Done
    evidence_fingerprint: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
    status: Needs Human
    audit_ids:
    - audit-c199fcd84f4b
    applied: true
    created_at: '2026-08-07T10:45:48.897055+00:00'
    applied_at: '2026-08-07T10:45:55.177548+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-89016608bf79
    project_id: proj-c260b117
    task_id: EXOCOMP-1
    target_state: Archived
    request_state: superseded
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
    attempts:
    - version: 1
      attempt_id: attempt-587b1d655ca0
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
      created_at: '2026-07-31T04:12:20.147318+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-31T04:12:20.147318+00:00'
      branch_key: epic-EXOCOMP-1
      verdict: fail
      failure_classification: unsafe_archive
      completed_at: '2026-07-31T04:15:05.910192+00:00'
      ended_at: '2026-07-31T04:15:05.910192+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-31T04:12:14.491522+00:00'
    updated_at: '2026-07-31T04:15:05.910192+00:00'
  - version: 1
    audit_id: audit-fbf0c16421eb
    project_id: proj-c260b117
    task_id: EXOCOMP-1
    target_state: Done
    request_state: superseded
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
    attempts:
    - version: 1
      attempt_id: attempt-fb8d7e9d1798
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
      created_at: '2026-07-31T04:38:39.138199+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-31T04:38:39.138199+00:00'
      branch_key: epic-EXOCOMP-1
      verdict: needs_human
      failure_classification: unsafe_archive
      completed_at: '2026-07-31T04:40:35.903856+00:00'
      ended_at: '2026-07-31T04:40:35.903856+00:00'
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: In Progress
    created_at: '2026-07-31T04:22:38.213097+00:00'
    updated_at: '2026-07-31T04:40:35.903856+00:00'
  - version: 1
    audit_id: audit-ba5cb27057e8
    project_id: proj-c260b117
    task_id: EXOCOMP-1
    target_state: Merged
    request_state: superseded
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
    attempts:
    - version: 1
      attempt_id: attempt-6bf9ac5e9f1a
      target_state: Merged
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
      created_at: '2026-07-31T05:52:07.370115+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-31T05:52:07.370115+00:00'
      branch_key: epic-EXOCOMP-1
      verdict: pass
      completed_at: '2026-07-31T05:56:12.430293+00:00'
      ended_at: '2026-07-31T05:56:12.430293+00:00'
    requested_by:
      version: 1
      identity: epic-rollup-reconciliation
      source: oompah
    previous_state: In Progress
    created_at: '2026-07-31T04:22:38.213097+00:00'
    updated_at: '2026-07-31T05:56:12.430293+00:00'
  - version: 1
    audit_id: audit-a8043727fea8
    project_id: proj-c260b117
    task_id: EXOCOMP-1
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
    attempts:
    - version: 1
      attempt_id: attempt-b6480c4ed1ef
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
      created_at: '2026-08-07T08:55:15.443319+00:00'
      provider_id: prov-651d553c
      model: haiku
      started_at: '2026-08-07T08:55:15.443319+00:00'
      branch_key: epic-EXOCOMP-1
      selected_ref: origin/main
      selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
      ended_at: '2026-08-07T09:16:44.140329+00:00'
      failure_reason: auditor session abandoned; no live worker owns the attempt
    - version: 1
      attempt_id: attempt-b714ad8ea7a5
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
      created_at: '2026-08-07T09:17:07.097210+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-08-07T09:17:07.097210+00:00'
      branch_key: epic-EXOCOMP-1
      selected_ref: origin/main
      selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
      candidate_rotation_count: 1
      failure_classification: finalization_failure
      ended_at: '2026-08-07T09:29:48.452948+00:00'
      failure_reason: normal
      next_retry_at: '2026-08-07T09:30:08.452914+00:00'
    - version: 1
      attempt_id: attempt-379413328a1d
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
      created_at: '2026-08-07T09:32:21.042420+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-07T09:32:21.042420+00:00'
      branch_key: epic-EXOCOMP-1
      selected_ref: origin/main
      selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
      candidate_rotation_count: 2
      verdict: needs_human
      failure_classification: unsafe_archive
      completed_at: '2026-08-07T09:38:39.941566+00:00'
      ended_at: '2026-08-07T09:38:39.941566+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-07T08:43:17.486543+00:00'
    selected_ref: origin/main
    selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
    updated_at: '2026-08-07T09:38:39.941566+00:00'
  - version: 1
    audit_id: audit-c199fcd84f4b
    project_id: proj-c260b117
    task_id: EXOCOMP-1
    target_state: Done
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
    attempts:
    - version: 1
      attempt_id: attempt-1bbdd184fe3d
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
      created_at: '2026-08-07T10:14:58.825251+00:00'
      provider_id: prov-651d553c
      model: haiku
      started_at: '2026-08-07T10:14:58.825251+00:00'
      branch_key: epic-EXOCOMP-1
      selected_ref: origin/main
      selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
      ended_at: '2026-08-07T10:34:10.143456+00:00'
      failure_reason: auditor session abandoned; no live worker owns the attempt
    - version: 1
      attempt_id: attempt-824af6b522ac
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
      created_at: '2026-08-07T10:34:27.111584+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-08-07T10:34:27.111584+00:00'
      branch_key: epic-EXOCOMP-1
      selected_ref: origin/main
      selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
      candidate_rotation_count: 1
      ended_at: '2026-08-07T10:40:37.853702+00:00'
      failure_reason: auditor session abandoned; no live worker owns the attempt
    - version: 1
      attempt_id: attempt-ccf2cb332c9b
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
      created_at: '2026-08-07T10:40:49.919188+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-07T10:40:49.919188+00:00'
      branch_key: epic-EXOCOMP-1
      selected_ref: origin/main
      selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
      candidate_rotation_count: 2
      verdict: needs_human
      failure_classification: policy_incompatibility
      completed_at: '2026-08-07T10:45:48.896719+00:00'
      ended_at: '2026-08-07T10:45:48.896719+00:00'
    requested_by:
      version: 1
      identity: orchestrator
    previous_state: In Review
    created_at: '2026-08-07T09:56:54.489394+00:00'
    selected_ref: origin/main
    selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
    updated_at: '2026-08-07T10:45:48.896719+00:00'
  - version: 1
    audit_id: audit-db44b90646cf
    project_id: proj-c260b117
    task_id: EXOCOMP-1
    target_state: Merged
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
    attempts:
    - version: 1
      attempt_id: attempt-8b2a1f06c37c
      target_state: Merged
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
      created_at: '2026-08-07T11:00:35.478157+00:00'
      provider_id: prov-651d553c
      model: haiku
      started_at: '2026-08-07T11:00:35.478157+00:00'
      branch_key: epic-EXOCOMP-1
      selected_ref: origin/main
      selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
      ended_at: '2026-08-07T11:15:01.936509+00:00'
      failure_reason: auditor session abandoned; no live worker owns the attempt
    requested_by:
      version: 1
      identity: orchestrator
    previous_state: In Review
    created_at: '2026-08-07T09:56:54.489394+00:00'
    selected_ref: origin/main
    selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
    updated_at: '2026-08-07T11:00:35.478157+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-587b1d655ca0
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
    created_at: '2026-07-31T04:12:20.147318+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-31T04:12:20.147318+00:00'
    branch_key: epic-EXOCOMP-1
  - version: 1
    attempt_id: attempt-fb8d7e9d1798
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
    created_at: '2026-07-31T04:38:39.138199+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-31T04:38:39.138199+00:00'
    branch_key: epic-EXOCOMP-1
  - version: 1
    attempt_id: attempt-6bf9ac5e9f1a
    target_state: Merged
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
    created_at: '2026-07-31T05:52:07.370115+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-31T05:52:07.370115+00:00'
    branch_key: epic-EXOCOMP-1
  - version: 1
    attempt_id: attempt-b6480c4ed1ef
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
    created_at: '2026-08-07T08:55:15.443319+00:00'
    provider_id: prov-651d553c
    model: haiku
    started_at: '2026-08-07T08:55:15.443319+00:00'
    branch_key: epic-EXOCOMP-1
    selected_ref: origin/main
    selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
    ended_at: '2026-08-07T09:16:44.140329+00:00'
    failure_reason: auditor session abandoned; no live worker owns the attempt
  - version: 1
    attempt_id: attempt-b714ad8ea7a5
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
    created_at: '2026-08-07T09:17:07.097210+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-08-07T09:17:07.097210+00:00'
    branch_key: epic-EXOCOMP-1
    selected_ref: origin/main
    selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
    candidate_rotation_count: 1
    failure_classification: finalization_failure
    ended_at: '2026-08-07T09:29:48.452948+00:00'
    failure_reason: normal
    next_retry_at: '2026-08-07T09:30:08.452914+00:00'
  - version: 1
    attempt_id: attempt-379413328a1d
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 07db39edafe6f15ff50cb49726a8c14f0bfd801d1f06be3278a1fffc12cea9bd
    created_at: '2026-08-07T09:32:21.042420+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-07T09:32:21.042420+00:00'
    branch_key: epic-EXOCOMP-1
    selected_ref: origin/main
    selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
    candidate_rotation_count: 2
  - version: 1
    attempt_id: attempt-1bbdd184fe3d
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
    created_at: '2026-08-07T10:14:58.825251+00:00'
    provider_id: prov-651d553c
    model: haiku
    started_at: '2026-08-07T10:14:58.825251+00:00'
    branch_key: epic-EXOCOMP-1
    selected_ref: origin/main
    selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
    ended_at: '2026-08-07T10:34:10.143456+00:00'
    failure_reason: auditor session abandoned; no live worker owns the attempt
  - version: 1
    attempt_id: attempt-824af6b522ac
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
    created_at: '2026-08-07T10:34:27.111584+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-08-07T10:34:27.111584+00:00'
    branch_key: epic-EXOCOMP-1
    selected_ref: origin/main
    selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
    candidate_rotation_count: 1
    ended_at: '2026-08-07T10:40:37.853702+00:00'
    failure_reason: auditor session abandoned; no live worker owns the attempt
  - version: 1
    attempt_id: attempt-ccf2cb332c9b
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
    created_at: '2026-08-07T10:40:49.919188+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-07T10:40:49.919188+00:00'
    branch_key: epic-EXOCOMP-1
    selected_ref: origin/main
    selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
    candidate_rotation_count: 2
  - version: 1
    attempt_id: attempt-8b2a1f06c37c
    target_state: Merged
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 2991efce4dbc33ef79d479689af5556fec8ec13c0aa7894c1de2d8d28ad5c37e
    created_at: '2026-08-07T11:00:35.478157+00:00'
    provider_id: prov-651d553c
    model: haiku
    started_at: '2026-08-07T11:00:35.478157+00:00'
    branch_key: epic-EXOCOMP-1
    selected_ref: origin/main
    selected_sha: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
    ended_at: '2026-08-07T11:15:01.936509+00:00'
    failure_reason: auditor session abandoned; no live worker owns the attempt
oompah.task_costs:
  total_input_tokens: 451
  total_output_tokens: 31360
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 451
      output_tokens: 31360
      cost_usd: 0.0
  runs:
  - profile: auditor
    model: unknown
    input_tokens: 46
    output_tokens: 8762
    cost_usd: 0.0
    recorded_at: '2026-07-31T04:15:12.304538+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 47
    output_tokens: 579
    cost_usd: 0.0
    recorded_at: '2026-07-31T04:40:49.533823+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 39
    output_tokens: 9565
    cost_usd: 0.0
    recorded_at: '2026-07-31T05:56:25.748207+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 82
    output_tokens: 9
    cost_usd: 0.0
    recorded_at: '2026-08-07T09:08:13.723320+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 18
    output_tokens: 7080
    cost_usd: 0.0
    recorded_at: '2026-08-07T09:29:48.456539+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 29
    output_tokens: 142
    cost_usd: 0.0
    recorded_at: '2026-08-07T09:40:36.778886+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 90
    output_tokens: 12
    cost_usd: 0.0
    recorded_at: '2026-08-07T10:32:26.707517+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 14
    output_tokens: 90
    cost_usd: 0.0
    recorded_at: '2026-08-07T10:39:29.621740+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 12
    output_tokens: 5103
    cost_usd: 0.0
    recorded_at: '2026-08-07T10:47:41.828610+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 74
    output_tokens: 18
    cost_usd: 0.0
    recorded_at: '2026-08-07T11:13:18.698457+00:00'
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Deliver the diagnostic-only Elixir node-agent milestone described in the linked design.

Scope
Coordinate the child tasks for the umbrella foundation, A2A protocol types, node identity and TLS, Linux diagnostics, llama.cpp supervision, the node A2A service, and milestone acceptance testing. The node must not expose or perform state-changing actions in this milestone.

Testing
All child-task tests and the complete M1 integration suite must pass through repository Make targets.

Acceptance Criteria
- [ ] Every child task is complete and its focused tests pass.
- [ ] Every M1-CRIT-* criterion in the linked plan has recorded evidence.
- [ ] The node release performs authenticated diagnostics without modifying host state.
- [ ] make build, make test, make lint, and make fmt-check pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 03:10
---
YOLO: merged PR #8.
---
author: oompah
created: 2026-07-31 04:12
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-07-31 04:12
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-07-31 04:12
---
Focus: Completion Auditor
---
author: oompah
created: 2026-07-31 04:15
---
Needs Human — Archived audit requires operator input.

[REDACTED]

Instructions:
- Do not archive while task state is not Merged. Return the aged-Merged auto-archive to the queue only after the task re-enters Merged with all children in terminal (Merged/Archived/Done) states.
- Because the 'epic:rebasing' label is present, treat this epic as active and skip auto-archival until the rebase-and-revalidate cycle completes and the label is removed.
---
author: oompah
created: 2026-07-31 04:15
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 50, Tool calls: 40
- Tokens: 46 in / 8.8K out [8.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 50s
- Log: EXOCOMP-1__20260731T041228Z.jsonl
---
author: oompah
created: 2026-07-31 04:38
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-07-31 04:38
---
Focus: Completion Auditor
---
author: oompah
created: 2026-07-31 04:40
---
Needs Human — Done audit requires operator input.

[REDACTED]

Questions:
- Should the Done audit wait until all six 'In Validation' children reach terminal (Merged/Archived/Done) states?
- Should the 'epic:rebasing' label be removed before promoting EXOCOMP-1 to a terminal state, per the prior auditor's guidance?
- Is the intent to promote this parent epic to Done despite EXOCOMP-93's rebase task still being In Validation?

Instructions:
- Complete the epic-EXOCOMP-1 rebase-and-revalidate cycle: drive EXOCOMP-93, EXOCOMP-7, EXOCOMP-10, EXOCOMP-11, EXOCOMP-12, and EXOCOMP-13 to terminal states (Merged/Archived/Done).
- Remove the 'epic:rebasing' label once the rebase-and-revalidate cycle completes.
- Reschedule the Done audit for EXOCOMP-1 only after the tracker graph shows all children in terminal states and the rebasing label is cleared.
---
author: oompah
created: 2026-07-31 04:40
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 0, Tool calls: 18
- Tokens: 47 in / 579 out [626 total]
- Cost: $0.0000
- Exit: terminated, Duration: 2m 10s
- Log: EXOCOMP-1__20260731T043842Z.jsonl
---
author: oompah
created: 2026-07-31 05:52
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-07-31 05:52
---
Focus: Completion Auditor
---
author: oompah
created: 2026-07-31 05:56
---
Audit PASS — Merged

[REDACTED]

Instructions:
- After this Merged audit is applied, an operator or the scheduler should remove the 'epic:rebasing' label from EXOCOMP-1 before scheduling any Archive/Done audit, per prior auditor guidance.
- Subsequent Archive audit can be scheduled once the label is cleared and the standard Merged-to-Archived aging window has elapsed.

Safe evidence:
- branch_head: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
- main_head: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
- branch_matches_main: true
- children_terminal_count: 9/9
- children_states: EXOCOMP-93:Archived, EXOCOMP-94:Archived, EXOCOMP-7:Archived, EXOCOMP-8:Merged, EXOCOMP-9:Archived, EXOCOMP-10:Archived, EXOCOMP-11:Archived, EXOCOMP-12:Archived, EXOCOMP-13:Archived
- m1_crit_checked_count: 7/7 in plans/milestone-1-node-agent.md
- m1_acceptance_test_file: apps/exocomp_node/test/integration/m1_acceptance_test.exs
- epic_rebasing_label_present: true (does not block Merged, but must be cleared for subsequent Archive/Done audit)
---
author: oompah
created: 2026-07-31 05:56
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 45, Tool calls: 33
- Tokens: 39 in / 9.6K out [9.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 4m 18s
- Log: EXOCOMP-1__20260731T055209Z.jsonl
---
author: oompah
created: 2026-08-07 08:55
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/haiku)
---
author: oompah
created: 2026-08-07 08:55
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-07 09:08
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/haiku]
- Turns: 0, Tool calls: 6
- Tokens: 82 in / 9 out [91 total]
- Cost: $0.0000
- Exit: terminated, Duration: 12m 54s
- Log: EXOCOMP-1__20260807T085530Z.jsonl
---
author: oompah
created: 2026-08-07 09:17
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-08-07 09:17
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-07 09:29
---
Run #2 [attempt=2, profile=auditor, role=auditor -> Claude/sonnet]
- Turns: 24, Tool calls: 8
- Tokens: 18 in / 7.1K out [7.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 12m 34s
- Log: EXOCOMP-1__20260807T091731Z.jsonl
---
author: oompah
created: 2026-08-07 09:30
---
Auditor attempt ended: auditor exited (normal) without a result. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-07 09:32
---
Auditor dispatched (attempt #3, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-07 09:32
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-07 09:38
---
Needs Human — Archived audit requires operator input.

[REDACTED]

Questions:
- Why is EXOCOMP-1 currently in 'In Validation' rather than 'Merged' when the scheduler queued an aged-Merged Archive audit — was it manually moved, or did a re-validation cycle reopen it?
- Should the 'epic:rebasing' label be removed by an operator before this Archive audit is re-queued, per prior auditor guidance?
- Is any additional child work outstanding, or is this purely a state/label reconciliation before Archive can proceed?

Instructions:
- Reconcile EXOCOMP-1's current 'In Validation' state to 'Merged' before rescheduling the Archived audit — Archive is only valid from Merged.
- Remove the 'epic:rebasing' label from EXOCOMP-1 before rescheduling any Archive/Done audit, per prior auditor guidance from 2026-07-31 05:56.
- After both preconditions are met and the standard Merged-to-Archived aging window has elapsed, re-queue the Archived audit.
---
author: oompah
created: 2026-08-07 09:39
---
[watchdog:stalled_task] Stalled-task watchdog audit (run #5)

**State audited:** `Needs Human`
**Classification:** `actionable`
**Action:** `reopen`
**Evidence:** current review 8 is merged
**Evidence result:** `merged`

*This comment is posted automatically by the oompah stalled-task watchdog. No human action required unless the classification above is incorrect.*
---
author: oompah
created: 2026-08-07 09:40
---
Run #3 [attempt=3, profile=auditor, role=auditor -> Claude/opus]
- Turns: 0, Tool calls: 6
- Tokens: 29 in / 142 out [171 total]
- Cost: $0.0000
- Exit: terminated, Duration: 8m 10s
- Log: EXOCOMP-1__20260807T093231Z.jsonl
---
author: oompah
created: 2026-08-07 10:15
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/haiku)
---
author: oompah
created: 2026-08-07 10:15
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-07 10:32
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/haiku]
- Turns: 0, Tool calls: 6
- Tokens: 90 in / 12 out [102 total]
- Cost: $0.0000
- Exit: terminated, Duration: 17m 10s
- Log: EXOCOMP-1__20260807T101541Z.jsonl
---
author: oompah
created: 2026-08-07 10:34
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-08-07 10:34
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-07 10:39
---
Run #2 [attempt=2, profile=auditor, role=auditor -> Claude/sonnet]
- Turns: 0, Tool calls: 4
- Tokens: 14 in / 90 out [104 total]
- Cost: $0.0000
- Exit: terminated, Duration: 4m 51s
- Log: EXOCOMP-1__20260807T103444Z.jsonl
---
author: oompah
created: 2026-08-07 10:40
---
Auditor dispatched (attempt #3, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-07 10:40
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-07 10:45
---
Needs Human — Done audit requires operator input.

[REDACTED]

Questions:
- Why does the tracker show state='In Validation' when the scheduler's trusted contract records previous_state='In Review' — was the state reset by the stalled-task watchdog reopen action (comment #25) rather than a genuine re-review?
- Should an operator remove the 'epic:rebasing' label from EXOCOMP-1 before this Done audit is re-queued, matching the guidance issued by every prior terminal-state auditor since 2026-07-31 04:40?
- If the intent is to promote this epic straight to Done rather than following the standard Merged → aged → Archived path, is there an explicit operator decision documenting that route for a labeled 'epic:rebasing' epic?

Instructions:
- Remove the 'epic:rebasing' label from EXOCOMP-1 before re-queueing any Done or Archive audit, per prior auditor guidance from 2026-07-31 04:40, 2026-07-31 05:56, and 2026-08-07 09:38.
- Reconcile EXOCOMP-1's tracker state so that it matches the scheduler contract's previous_state expectation (Merged or In Review) before rescheduling the Done audit; if the current 'In Validation' is intentional, complete validation first.
- After the label is cleared and state is reconciled, the substantive M1 evidence (branch==main at 58f3cec5, 9/9 terminal children, 7/7 M1-CRIT items, acceptance test present) should support a straightforward Done audit pass on the next dispatch.
---
author: oompah
created: 2026-08-07 10:47
---
Run #3 [attempt=3, profile=auditor, role=auditor -> Claude/opus]
- Turns: 16, Tool calls: 9
- Tokens: 12 in / 5.1K out [5.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 6m 50s
- Log: EXOCOMP-1__20260807T104108Z.jsonl
---
author: oompah
created: 2026-08-07 10:47
---
[watchdog:stalled_task] Stalled-task watchdog audit (run #10)

**State audited:** `Needs Human`
**Classification:** `actionable`
**Action:** `reopen`
**Evidence:** current review 8 is merged
**Evidence result:** `merged`

*This comment is posted automatically by the oompah stalled-task watchdog. No human action required unless the classification above is incorrect.*
---
author: oompah
created: 2026-08-07 11:01
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/haiku)
---
author: oompah
created: 2026-08-07 11:01
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-07 11:13
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/haiku]
- Turns: 0, Tool calls: 5
- Tokens: 74 in / 18 out [92 total]
- Cost: $0.0000
- Exit: terminated, Duration: 12m 3s
- Log: EXOCOMP-1__20260807T110141Z.jsonl
---
<!-- COMMENTS:END -->
