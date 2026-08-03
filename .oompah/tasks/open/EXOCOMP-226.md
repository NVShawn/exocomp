---
id: EXOCOMP-226
type: task
status: Open
priority: 1
title: Verify policy and resolve effective mode inside the broker
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-220
- EXOCOMP-225
labels: []
assignee: null
created_at: '2026-08-03T14:26:21.729863Z'
updated_at: '2026-08-03T15:42:07.602201Z'
work_branch: epic-EXOCOMP-211--task-EXOCOMP-226
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 02c245b3c6bf5f3451fd21e8ce67c8244a6739540f6d6ac84f90c5aea197653c
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:42:01.478223+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: The authoritative project task corpus contains no other\
    \ Open tasks. All 100+ indexed tasks are in terminal states (Archived or Merged).\
    \ EXOCOMP-226's scope \u2014 policy-bundle verification, Mission Control signature\
    \ checks, and broker-side effective mode resolution \u2014 does not overlap with\
    \ any task in the corpus, which focuses on node diagnostics (M1), coordinator\
    \ orchestration (M2), testing/qualification (M3-M6), and recovery work (EXOCOMP-110\
    \ epic). The task is unique to the hierarchical-management-modes epic (EXOCOMP-211)\
    \ and ready to proceed to implementation.\nLooking at EXOCOMP-226 and the current\
    \ project task corpus, I need to determine whether this task is a duplicate of\
    \ an existing active task.\n\n## Analysis\n\n**Current Task (EXOCOMP-226):**\n\
    - Title: \"Verify policy and resolve effective mode inside the broker\"\n- Scope:\
    \ Policy-bundle verification, Mission Control signature validation, effective\
    \ mode resolution using shared resolver\n- Components: Policy verification, key\
    \ ID checks, organization/cluster/node identity validation, policy version/expiry/signature\
    \ checks, audit with bounded reason codes\n\n**Corpus Review:**\nThe provided\
    \ authoritative corpus contains 100+ tasks across multiple milestones. Scanning\
    \ for scope overlap:\n\n- **M1 tasks (EXOCOMP-7 through EXOCOMP-13):** Node diagnostics,\
    \ collectors, llama.cpp, A2A service\n- **M2 tasks (EXOCOMP-14 through EXOCOMP-20):**\
    \ Coordinator inventory, DNS discovery, PKI initialization, enrollment\n- **M3-M5\
    \ tasks:** Acceptance testing, benchmarking, multi-node orchestration\n- **M6\
    \ tasks (EXOCOMP-118-123):** Release qualification, bundle reproducibility, cross-architecture\
    \ testing\n- **Recovery tasks (EXOCOMP-111-116):** A2A codec recovery, benchmark\
    \ work, acceptance/fault-injection recovery, governance/builder recovery, implementation\
    \ of previously undelivered work\n\n**Active vs. Terminal Tasks:**\nPer instructions,\
    \ I excluded all terminal-state tasks (Done, Merged, Archived). In the entire\
    \ corpus provided, **EXOCOMP-226 is the only Open task** \u2014 all other 100+\
    \ tasks are in terminal states (Archived or Merged).\n\n**Scope Match Assessment:**\n\
    No task in the corpus addresses:\n- Privileged broker policy verification\n- Mission\
    \ Control signature validation\n- Effective mode resolution/computation\n- Policy-bundle\
    \ independent verification\n- The hierarchical management modes work described\
    \ in the deliverable\n\nThe coordination notes reference siblings (EXOCOMP-225,\
    \ 227-234) and dependencies (EXOCOMP-127, 220) as part of epic EXOCOMP-211, but\
    \ these are not present in the authoritative corpus, su"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: fccecec1-4688-4a8e-9e54-38955eb30cb3
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-226
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-226
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:40:14.772326+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 2247
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 2247
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2247
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:42:01.477774+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-226__20260803T154022Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-226
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:42:01.485274+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add independent policy-bundle verification and shared observe/manage resolution to the privileged broker.

Acceptance criteria:
- Verify Mission Control signature, key ID, organization/cluster/node identity, policy version, issue/expiry time, and canonical service key.
- Recompute the effective mode using the shared resolver and require manage.
- Missing policy, expired lease, unsupported version, invalid signature, resolver disagreement, or target mismatch denies without invoking an action.
- Broker audit output contains only bounded reason codes and safe identities.

Tests: Consume shared golden fixtures and cover every scope, peer conflict, node/service override, tamper, wrong identity, expiry, clock boundary, unknown key, malformed key, resolver disagreement, and proof that the command runner was not called; run broker tests plus make test, make fmt-check, and make lint.

Out of scope: Coordinator permits and action-specific preconditions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:40
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:40
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:42
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 2.2K out [2.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 51s
- Log: EXOCOMP-226__20260803T154022Z.jsonl
---
<!-- COMMENTS:END -->
