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
updated_at: '2026-08-03T15:45:00.073248Z'
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
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: inconclusive\n\
    Matches: none\nEvidence: ** The task corpus is demonstrated to be incomplete.\
    \ EXOCOMP-229's own coordination metadata lists EXOCOMP-225\u2013234 as active\
    \ epic-sibling and dependency peers, none of which are present in the supplied\
    \ corpus. The corpus claims \"availability\": \"authoritative\" and \"scope\"\
    : \"current project tracker,\" but demonstrably omits the most relevant peer tasks\
    \ for duplicate assessment. Without access to those tasks\u2014particularly EXOCOMP-227\
    \ and EXOCOMP-228 (marked as epic-siblings and dependencies)\u2014a reliable duplicate\
    \ determination cannot be made. The earliest visible tasks in the corpus (EXOCOMP-1\u2013\
    16) represent prior milestone work and do not cover policy/permit enforcement.\n\
    # Duplicate Investigation: EXOCOMP-229\n\nI'm conducting duplicate screening for\
    \ EXOCOMP-229 \"Enforce policy and permits at the node safety gate\" against the\
    \ current project task corpus.\n\n**Initial Observations:**\n\n1. **Task Scope**:\
    \ EXOCOMP-229 requires policy bundle enforcement, permit validation, broker invocation,\
    \ and safety gates for state-changing node workflows. It references `plans/hierarchical-management-modes.md`\
    \ (not in corpus).\n\n2. **Coordination Peers**: The coordination message explicitly\
    \ lists EXOCOMP-229's peers as:\n   - Dependencies: EXOCOMP-127, EXOCOMP-226,\
    \ EXOCOMP-228, EXOCOMP-231, EXOCOMP-232\n   - Epic siblings: EXOCOMP-225, EXOCOMP-227,\
    \ EXOCOMP-230, EXOCOMP-233, EXOCOMP-234\n   - Epic parent: EXOCOMP-211\n\n3. **Corpus\
    \ Coverage**: The provided task corpus spans EXOCOMP-1 through EXOCOMP-16 (M1\
    \ and M2 coordinator work) plus recovery/remediation tasks up to EXOCOMP-123.\
    \ **None of the peer tasks EXOCOMP-225-234 are present in the corpus.**\n\n4.\
    \ **Scope Mismatch**: Reviewed tasks address:\n   - Diagnostics collection and\
    \ orchestration (EXOCOMP-100\u2013105)\n   - DNS discovery and node polling (EXOCOMP-15)\n\
    \   - PKI and enrollment (EXOCOMP-16)\n   - Node A2A service (EXOCOMP-12)\n  \
    \ \n   None cover policy bundles, permits, or safety gate enforcement.\n\n---\n\
    \nFocus handoff: duplicate_detector\n\nDuplicate preflight verdict: inconclusive\n\
    \nMatches: none\n\n**Evidence:** The task corpus is demonstrated to be incomplete.\
    \ EXOCOMP-229's own coordination metadata lists EXOCOMP-225\u2013234 as active\
    \ epic-sibling and dependency peers, none of which are present in the supplied\
    \ corpus. The corpus claims \"availability\": \"authoritative\" and \"scope\"\
    : \"current project tracker,\" but demonstrably omits the most relevant peer tasks\
    \ for duplicate assessment. Without access to those tasks\u2014particularly EXOCOMP-227\
    \ and EXOCOMP-228 (marked as epic-siblings and dependencies)\u2014a reliable duplicate\
    \ determination cannot be made. The earliest visible tasks in the corpus (EXOCOMP-1\u2013\
    16) represent prior mil"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: '2026-08-03T15:45:54.627739+00:00'
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 106349cc-a4a2-43ff-aae2-76a231cf4ba2
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-229
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-229
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:43:45.427155+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 2114
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 2114
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2114
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:44:54.627143+00:00'
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
<!-- COMMENTS:END -->
