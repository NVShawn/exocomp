---
id: EXOCOMP-235
type: task
status: Open
priority: null
title: Add cross-layer observe/manage integration coverage
parent: EXOCOMP-212
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-218
- EXOCOMP-224
- EXOCOMP-234
labels: []
assignee: null
created_at: '2026-08-03T14:28:13.272722Z'
updated_at: '2026-08-03T16:02:10.319847Z'
work_branch: epic-EXOCOMP-212--task-EXOCOMP-235
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: ec654c94276f90909869cd27657e24abab3e0e99db74f775a50d7423e2440383
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T16:02:04.872090+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: EXOCOMP-235 is distinct from EXOCOMP-234 (bypass/mixed-version\
    \ gating), EXOCOMP-236 (security negatives), EXOCOMP-237 (upgrade qualification),\
    \ EXOCOMP-238 (documentation), and EXOCOMP-239 (final amd64/arm64 release qualification).\
    \ Its focused cross-layer fixture suite is a prerequisite to EXOCOMP-239, not\
    \ a duplicate. No repository or tracker changes were made.\nFocus handoff: duplicate_detector\
    \  \nDuplicate preflight verdict: no_duplicate  \nMatches: none  \n\nEvidence:\
    \ EXOCOMP-235 is distinct from EXOCOMP-234 (bypass/mixed-version gating), EXOCOMP-236\
    \ (security negatives), EXOCOMP-237 (upgrade qualification), EXOCOMP-238 (documentation),\
    \ and EXOCOMP-239 (final amd64/arm64 release qualification). Its focused cross-layer\
    \ fixture suite is a prerequisite to EXOCOMP-239, not a duplicate. No repository\
    \ or tracker changes were made."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 2
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: b55dbd44-e367-4df6-8e77-f067ee34f984
oompah.work_branch: epic-EXOCOMP-212--task-EXOCOMP-235
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-212--task-EXOCOMP-235
  base_branch: epic-EXOCOMP-212
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T16:00:26.063349+00:00'
oompah.task_costs:
  total_input_tokens: 976476
  total_output_tokens: 7461
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 976476
      output_tokens: 7461
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 156395
    output_tokens: 1751
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:53:32.262543+00:00'
  - profile: default
    model: haiku
    input_tokens: 98170
    output_tokens: 1760
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:57:15.317041+00:00'
  - profile: default
    model: haiku
    input_tokens: 721911
    output_tokens: 3950
    cost_usd: 0.0
    recorded_at: '2026-08-03T16:02:04.870295+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-235__20260803T155225Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-212--task-EXOCOMP-235
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:53:32.268381+00:00'
  - run_id: EXOCOMP-235__20260803T155617Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-212--task-EXOCOMP-235
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:57:15.359681+00:00'
  - run_id: EXOCOMP-235__20260803T160029Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-212--task-EXOCOMP-235
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T16:02:04.883948+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable:
Add deterministic integration coverage for policy authoring, distribution, resolution, and enforcement across Mission Control, the coordinator, and a node.

Acceptance criteria:
- Cover the implicit observe default and explicit settings at global, cluster, cluster/service, node, and node/service scopes.
- Cover the same-rank node versus cluster/service disagreement rule, where observe wins.
- Show that diagnostics, status reporting, chat, and remediation proposals remain available in observe mode.
- Show that approving a proposal in observe mode cannot execute a mutation.
- Show that manage mode can execute one registered typed action when every enforcement layer has valid policy and authorization.
- Use stable fixtures and assertions that identify which scope selected the effective mode.

Tests:
- Add focused integration tests for the scenarios above.
- Run the focused Makefile target plus make test, make fmt-check, and make lint.

Out of scope:
- Installer privilege-boundary tests and physical dual-architecture qualification.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:52
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:52
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:53
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 2
- Tokens: 156.4K in / 1.8K out [158.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 22s
- Log: EXOCOMP-235__20260803T155225Z.jsonl
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
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 0
- Tokens: 98.2K in / 1.8K out [99.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 5s
- Log: EXOCOMP-235__20260803T155617Z.jsonl
---
author: oompah
created: 2026-08-03 16:00
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 16:00
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 16:02
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 11
- Tokens: 721.9K in / 4.0K out [725.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 46s
- Log: EXOCOMP-235__20260803T160029Z.jsonl
---
<!-- COMMENTS:END -->
