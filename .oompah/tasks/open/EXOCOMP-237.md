---
id: EXOCOMP-237
type: task
status: Open
priority: null
title: Qualify upgrade, downgrade, and mixed-version behavior
parent: EXOCOMP-212
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-224
- EXOCOMP-230
- EXOCOMP-234
labels: []
assignee: null
created_at: '2026-08-03T14:28:18.903629Z'
updated_at: '2026-08-03T15:54:17.987384Z'
work_branch: epic-EXOCOMP-212--task-EXOCOMP-237
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 751aaad444813fccc903aaeb2d15801e6c67e887e381126b2666ca4abe2a130b
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: inconclusive\n\
    Matches: none\nEvidence: The supplied corpus lacks full records for the relevant\
    \ active peer tasks (EXOCOMP-212, EXOCOMP-224, EXOCOMP-230, EXOCOMP-234, EXOCOMP-235,\
    \ EXOCOMP-236, EXOCOMP-238, and EXOCOMP-239). The closest reviewed task, EXOCOMP-115,\
    \ is terminal and has a different scope.\nFocus handoff: duplicate_detector  \n\
    Duplicate preflight verdict: inconclusive  \nMatches: none  \n\nEvidence: The\
    \ supplied corpus lacks full records for the relevant active peer tasks (EXOCOMP-212,\
    \ EXOCOMP-224, EXOCOMP-230, EXOCOMP-234, EXOCOMP-235, EXOCOMP-236, EXOCOMP-238,\
    \ and EXOCOMP-239). The closest reviewed task, EXOCOMP-115, is terminal and has\
    \ a different scope."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: '2026-08-03T15:55:12.786939+00:00'
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: e1ad49a4-5bf5-46d7-9a5b-0d6158fab443
oompah.work_branch: epic-EXOCOMP-212--task-EXOCOMP-237
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-212--task-EXOCOMP-237
  base_branch: epic-EXOCOMP-212
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:53:22.858072+00:00'
oompah.task_costs:
  total_input_tokens: 48612
  total_output_tokens: 1142
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 48612
      output_tokens: 1142
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 48612
    output_tokens: 1142
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:54:12.781732+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-237__20260803T155338Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-212--task-EXOCOMP-237
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:54:12.830227+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable:
Add and execute supported-version scenarios that prove upgrades enter observe safely and that unsupported mixed-version combinations cannot manage nodes.

Acceptance criteria:
- Upgrade a previously managed installation and verify no policy is synthesized that enables manage mode.
- Verify a node without a valid current policy lease remains observe after restart and reconnect.
- Cover supported mixed-version coordinator and node combinations and verify management is enabled only when every required enforcement layer is present.
- Document and test downgrade refusal or safe fallback behavior for versions that cannot preserve the enforcement boundary.
- Demonstrate a rollback procedure that leaves the cluster in observe mode.

Tests:
- Add automated upgrade and mixed-version scenarios using repository fixtures or VM harnesses.
- Run the focused Makefile targets plus make test, make fmt-check, and make lint.

Out of scope:
- General release qualification unrelated to hierarchical management policy.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:53
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:53
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:54
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 0
- Tokens: 48.6K in / 1.1K out [49.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 54s
- Log: EXOCOMP-237__20260803T155338Z.jsonl
---
<!-- COMMENTS:END -->
