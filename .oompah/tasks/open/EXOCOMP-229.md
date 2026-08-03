---
id: EXOCOMP-229
type: task
status: Open
priority: 1
title: Enforce policy and permits at the node safety gate
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-226
- EXOCOMP-228
labels: []
assignee: null
created_at: '2026-08-03T14:26:29.308857Z'
updated_at: '2026-08-03T15:53:17.067074Z'
work_branch: epic-EXOCOMP-211--task-EXOCOMP-229
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 7a16b6b54aa67febf96673384a4a4b9120bfb1fe15fea03839e8794d007e43ca
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:53:13.564206+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: Reviewed authoritative project task corpus covering EXOCOMP-10\
    \ through EXOCOMP-123. All tasks with overlapping keywords (policy, enforcement,\
    \ permits, coordinator, safety, broker) are in terminal states (Archived or Done).\
    \ EXOCOMP-229 uniquely addresses node-level safety gate validation of signed policy\
    \ bundles and action permits before state-changing workflows. No active task covers\
    \ this identical scope. Sibling coordination peers are not present in the authoritative\
    \ corpus and cannot be assessed.\nBased on my investigation using the authoritative\
    \ project task corpus, I can now provide my duplicate screening verdict.\n\n**Analysis:**\n\
    \nEXOCOMP-229 focuses specifically on **enforcing policy and permits at the node\
    \ safety gate** \u2014 the third boundary in the hierarchical policy enforcement\
    \ model defined in `plans/hierarchical-management-modes.md`. This involves:\n\
    - Validating fresh signed policy bundles\n- Verifying action permits\n- Checking\
    \ signatures, identities, bindings, evidence hashes, and expiry limits\n- Blocking\
    \ state-changing workflows without both artifacts\n\n**Corpus Review:**\n\nThe\
    \ authoritative project task corpus shows:\n- EXOCOMP-100-105: Coordinator diagnostics\
    \ orchestration (Archived) \u2014 focused on cluster-side coordination, not node-level\
    \ enforcement\n- EXOCOMP-118-123: Release candidate qualification and bundle installation\
    \ (Archived) \u2014 focused on delivery and verification, not policy enforcement\n\
    - EXOCOMP-14-15: Coordinator scaffolding and polling (Archived) \u2014 focused\
    \ on coordinator state and discovery, not node safety gates\n- No other active,\
    \ non-terminal tasks address policy/permit enforcement at the node level\n\nAll\
    \ related policy/management tasks are in terminal states (Archived/Done) and are\
    \ excluded from active duplicate consideration per the guidelines.\n\nThe coordination\
    \ advisory mentions sibling tasks (EXOCOMP-225, 227, 230, 234) but these do not\
    \ appear in the authoritative corpus, suggesting they are either planned but not\
    \ yet instantiated, or are distinct work areas that would be revealed as non-duplicates\
    \ upon detailed review.\n\n---\n\nFocus handoff: duplicate_detector\n\nDuplicate\
    \ preflight verdict: no_duplicate\n\nMatches: none\n\nEvidence: Reviewed authoritative\
    \ project task corpus covering EXOCOMP-10 through EXOCOMP-123. All tasks with\
    \ overlapping keywords (policy, enforcement, permits, coordinator, safety, broker)\
    \ are in terminal states (Archived or Done). EXOCOMP-229 uniquely addresses node-level\
    \ safety gate validation of signed policy bundles and"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 2
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 8b24c8f5-e8ab-4c83-8160-80a345cadb13
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-229
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-229
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:50:19.832005+00:00'
oompah.task_costs:
  total_input_tokens: 108040
  total_output_tokens: 8115
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 108040
      output_tokens: 8115
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2114
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:44:54.627143+00:00'
  - profile: default
    model: haiku
    input_tokens: 107980
    output_tokens: 1633
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:47:22.472839+00:00'
  - profile: default
    model: haiku
    input_tokens: 50
    output_tokens: 4368
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:53:13.563503+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-229__20260803T154351Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-229
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:44:54.631765+00:00'
  - run_id: EXOCOMP-229__20260803T154618Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-229
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:47:22.489130+00:00'
  - run_id: EXOCOMP-229__20260803T155023Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-229
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:53:13.574315+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Require a fresh signed policy bundle and matching action permit for every state-changing node workflow and invoke the broker through a bounded client.

Acceptance criteria:
- Direct node recovery requests without both artifacts fail as observe.
- Node verifies signatures, identities, action/target/service bindings, evidence hash, idempotency, and both expiry limits before broker invocation.
- Node independently resolves effective mode and requires manage.
- Duplicate permits return the durable prior result and cannot repeat execution.
- Diagnostic and proposal skills remain available without a permit.

Tests: Cover valid invocation, absent artifacts, every binding mismatch, observe, lease/permit expiry, replay, node restart, broker timeout/failure, diagnostic availability, and no invocation on denial; run make test, make fmt-check, and make lint.

Out of scope: Broker internals, sudoers installation, and specific action adapters.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:43
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:43
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:44
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 2.1K out [2.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 13s
- Log: EXOCOMP-229__20260803T154351Z.jsonl
---
author: oompah
created: 2026-08-03 15:46
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:46
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:47
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 11
- Tokens: 108.0K in / 1.6K out [109.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 13s
- Log: EXOCOMP-229__20260803T154618Z.jsonl
---
author: oompah
created: 2026-08-03 15:50
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:50
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:53
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 15, Tool calls: 5
- Tokens: 50 in / 4.4K out [4.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 58s
- Log: EXOCOMP-229__20260803T155023Z.jsonl
---
<!-- COMMENTS:END -->
