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
updated_at: '2026-08-03T15:57:44.794628Z'
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
  verdict: no_duplicate
  checked_at: '2026-08-03T15:57:36.175584+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: Duplicate preflight verdict: no_duplicate\nMatches: none\n\
    Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence:\n\nReviewed the complete task corpus provided. EXOCOMP-237\
    \ concerns upgrade, downgrade, and mixed-version behavior qualification for the\
    \ hierarchical management policy system\u2014specifically adding and executing\
    \ test scenarios that verify safe transitions, policy enforcement layer completeness,\
    \ and version compatibility.\n\nThe corpus contains only terminal-state tasks\
    \ (Done, Merged, Archived). No active task in the available data overlaps with\
    \ EXOCOMP-237's scope:\n\n- **Release qualification tasks** (EXOCOMP-47, EXOCOMP-123):\
    \ Cover general v0.1.0 qualification, not version transition scenarios\n- **Coordinator/node\
    \ features** (EXOCOMP-14 through EXOCOMP-105): Build coordinator and node capabilities,\
    \ not upgrade/downgrade behavior\n- **Recovery/remediation** (EXOCOMP-110 through\
    \ EXOCOMP-116): Address delivery gaps, not version compatibility\n- **Infrastructure**\
    \ (EXOCOMP-118 through EXOCOMP-122): Fix bundle/PKI/test robustness issues, unrelated\
    \ to version transitions\n\nThe coordination metadata references peer tasks (EXOCOMP-235,\
    \ EXOCOMP-236, EXOCOMP-238, EXOCOMP-239) as epic-siblings, but these are not present\
    \ in the provided corpus, so cannot be evaluated. EXOCOMP-212 (epic-parent) is\
    \ also not in the corpus.\n\n**Conclusion:** No duplicate confirmed in the available\
    \ task data. EXOCOMP-237 is a unique task for version upgrade/downgrade/mixed-version\
    \ qualification that does not appear as an existing active issue."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: e8ff8fea-b834-4a08-a2e0-f6beba0915af
oompah.work_branch: epic-EXOCOMP-212--task-EXOCOMP-237
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-212--task-EXOCOMP-237
  base_branch: epic-EXOCOMP-212
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:56:25.240723+00:00'
oompah.task_costs:
  total_input_tokens: 48622
  total_output_tokens: 2720
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 48622
      output_tokens: 2720
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 48612
    output_tokens: 1142
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:54:12.781732+00:00'
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1578
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:57:36.173398+00:00'
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
  - run_id: EXOCOMP-237__20260803T155628Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-212--task-EXOCOMP-237
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:57:36.192125+00:00'
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
author: oompah
created: 2026-08-03 15:56
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:56
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:57
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 1.6K out [1.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 16s
- Log: EXOCOMP-237__20260803T155628Z.jsonl
---
<!-- COMMENTS:END -->
