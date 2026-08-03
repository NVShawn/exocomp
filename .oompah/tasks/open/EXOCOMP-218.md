---
id: EXOCOMP-218
type: task
status: Open
priority: 2
title: Build management-policy LiveViews
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-217
labels: []
assignee: null
created_at: '2026-08-03T14:24:22.138173Z'
updated_at: '2026-08-03T15:49:46.135413Z'
work_branch: epic-EXOCOMP-209--task-EXOCOMP-218
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 64f121926bd781aaccd4719fba5f94d5e105c7e18703e801bd09b97646f77327
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:49:42.469097+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: ** The provided authoritative task corpus contains no\
    \ active duplicates of EXOCOMP-218. All peer tasks in the corpus are in terminal\
    \ states (Archived/Done/Merged). No archived task addresses Mission Control policy\
    \ LiveViews for inspection and editing. The coordination peers listed (EXOCOMP-127,\
    \ 209, 213\u2013238) are outside the corpus scope and cannot be evaluated without\
    \ their full descriptions; escalation to those peers should proceed via the coordination\
    \ mechanism if overlapping interfaces arise.\n# Duplicate Investigation: EXOCOMP-218\n\
    \nI'll analyze whether EXOCOMP-218 is a duplicate of an existing active task by\
    \ examining the provided task corpus.\n\n## Analysis\n\n**Current Task Summary:**\n\
    - EXOCOMP-218: \"Build management-policy LiveViews\" (Open)\n- Scope: Mission\
    \ Control views for policy inspection/editing at global, cluster, cluster/service,\
    \ node, and node/service levels\n- Key features: role-based access control, observation/management\
    \ modes, confirmation dialogs, PubSub updates\n- Tests required: role/scope coverage,\
    \ inheritance, conflict, stale updates, lease expiry, proposal controls\n\n**Corpus\
    \ Review:**\nScanning the authoritative task corpus provided, I find:\n- EXOCOMP-218:\
    \ Open \u2713 (the current task)\n- All other tasks (EXOCOMP-10\u2013EXOCOMP-123):\
    \ Terminal states (Archived/Done/Merged) \u2717\n\nThe corpus contains only EXOCOMP-218\
    \ as an active task. While coordination metadata lists peer tasks (EXOCOMP-127,\
    \ 209, 213\u2013217, 235, 238), these are not present in the authoritative corpus\
    \ extract.\n\n**Scope Comparison Against Terminal Tasks:**\n- None of the archived\
    \ tasks address \"management-policy LiveViews\" or \"Mission Control views\"\n\
    - EXOCOMP-3 (archived) covers policy ENGINE implementation and service recovery,\
    \ not UI inspection/editing\n- Other archived tasks focus on coordinator diagnostics,\
    \ PKI, benchmarking, and release work \u2014 orthogonal scopes\n\n---\n\nFocus\
    \ handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\n\
    Matches: none\n\n**Evidence:** The provided authoritative task corpus contains\
    \ no active duplicates of EXOCOMP-218. All peer tasks in the corpus are in terminal\
    \ states (Archived/Done/Merged). No archived task addresses Mission Control policy\
    \ LiveViews for inspection and editing. The coordination peers listed (EXOCOMP-127,\
    \ 209, 213\u2013238) are outside the corpus scope and cannot be evaluated without\
    \ their full descriptions; escalation to those peers should proceed via the coordination\
    \ mechanism if overlapping interfaces arise."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: ca22748b-4a24-40be-859d-123480d860bf
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-218
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-218
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:48:10.304372+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 2163
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 2163
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2163
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:49:42.465936+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-218__20260803T154814Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-209--task-EXOCOMP-218
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:49:42.479773+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add Mission Control views for global, cluster, cluster/service, node, and node/service policy inspection and editing.

Acceptance criteria:
- Show configured, inherited, and effective mode; winning scope; observe-wins conflict; policy version; acknowledgement; and lease expiry.
- Observe-to-manage uses a normal confirmation dialog showing scope and resulting effective value.
- Operators see only restriction controls, admins see both modes, and viewers see no mutation controls.
- Observe-mode proposals remain visible but approval and execution controls are disabled with an explanation.
- PubSub updates active views only after policy transactions commit.

Tests: Add LiveView tests for every role and scope, inheritance, conflict, confirmation/cancel, stale update, disconnected cluster, lease expiry, proposal controls, and organization isolation; run make test, make fmt-check, and make lint.

Out of scope: Policy persistence internals, bundle delivery, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:48
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:48
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:49
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 2.2K out [2.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 36s
- Log: EXOCOMP-218__20260803T154814Z.jsonl
---
<!-- COMMENTS:END -->
