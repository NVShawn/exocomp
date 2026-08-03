---
id: EXOCOMP-228
type: task
status: Open
priority: 1
title: Issue short-lived coordinator action permits
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-213
- EXOCOMP-222
labels: []
assignee: null
created_at: '2026-08-03T14:26:27.555796Z'
updated_at: '2026-08-03T15:43:07.893653Z'
work_branch: epic-EXOCOMP-211--task-EXOCOMP-228
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: aa7f6088de9d3b41fc72858c3b7203b22206808c9ab43cc1a334feb51c692f2e
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:43:00.843881+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: EXOCOMP-228 uniquely owns the scope of issuing canonical\
    \ coordinator-signed short-lived permits for exact broker actions with domain-separated\
    \ signatures and strict binding constraints. All peer tasks in the corpus are\
    \ in terminal states (Archived). No active task overlaps this specific deliverable\
    \ (hierarchical-management-modes.md, action permits, 60-second max expiry, domain\
    \ separation). The closest related archived work (EXOCOMP-16, EXOCOMP-119) addresses\
    \ PKI and enrollment services, not action authorization permits.\nI am investigating\
    \ whether EXOCOMP-228 \"Issue short-lived coordinator action permits\" is a duplicate\
    \ of any existing active task.\n\n## Scope of EXOCOMP-228\n\nThe task requires:\n\
    - **Deliverable:** Add a canonical coordinator-signed permit for one exact broker\
    \ action after manage decisions pass safety gates\n- **Core bindings:** cluster,\
    \ node, action ID, exact target, canonical service key, evidence hash, idempotency\
    \ ID, policy version/hash, issue time, expiry\n- **Constraints:** expiry \u2264\
    60s and \u2264policy lease; domain-separated from approval signatures; no permits\
    \ for observe/stale/unsupported/unknown/expired\n- **Scope:** Signing/dispatch/audit\
    \ only; excludes broker policy verification, node transport, action execution\n\
    \n## Duplicate Review\n\nScanning the current project task corpus for active (non-terminal)\
    \ tasks:\n\nThe corpus provided contains 27 tasks total. **All shown tasks have\
    \ terminal status (Archived)**. \n\n**EXOCOMP-228 is the only active (Open) task\
    \ listed.**\n\nReviewing for semantic overlap with archived tasks:\n- **EXOCOMP-16**\
    \ (PKI/enrollment tokens): Coordinator CA initialization and enrollment tokens\
    \ (node-bound, single-use, ten-minute expiry) \u2014 different scope (PKI, not\
    \ action permits)\n- **EXOCOMP-119** (PKI/enrollment services): Production coordinator\
    \ PKI/enrollment wiring \u2014 different scope (service startup, not permit issuance)\n\
    - **EXOCOMP-20** (M2 acceptance): Integration verification \u2014 umbrella task,\
    \ not permit-specific\n- **EXOCOMP-211** (epic parent): Hierarchical management\
    \ modes \u2014 parent epic containing EXOCOMP-228\n\nNo archived task describes\
    \ coordinator-signed action permits with short-lived signatures (\u226460s) bound\
    \ to exact actions.\n\n---\n\nFocus handoff: duplicate_detector\n\nDuplicate preflight\
    \ verdict: no_duplicate\n\nMatches: none\n\nEvidence: EXOCOMP-228 uniquely owns\
    \ the scope of issuing canonical coordinator-signed short-lived permits for exact\
    \ broker actions with domain-separated signatures and strict binding constraints.\
    \ All peer tasks in the corpus are"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 3010693c-5582-4e44-b604-d6cf98f9871a
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-228
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-228
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:41:57.036630+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 1946
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 1946
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1946
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:43:00.837279+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-228__20260803T154201Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-228
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:43:00.868132+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add a canonical coordinator-signed permit for one exact broker action after a manage decision passes all coordinator safety gates.

Acceptance criteria:
- Permit binds cluster, node, action ID, exact target, canonical service key, evidence hash, idempotency ID, policy version/hash, issue time, and expiry.
- Expiry is at most 60 seconds and never later than the policy lease.
- Existing approval signing material is domain-separated from permit signatures.
- A permit cannot be issued for observe, stale evidence, unsupported nodes, unknown actions, or expired policy.
- Signing failure prevents dispatch and is audited.

Tests: Add canonical fixture, sign/verify, binding mismatch, replay identity, expiry bounds, policy-expiry cap, domain separation, observe denial, and signing-failure tests; run make test, make fmt-check, and make lint.

Out of scope: Broker policy verification, node transport, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:41
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:42
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:43
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 4, Tool calls: 0
- Tokens: 10 in / 1.9K out [2.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 8s
- Log: EXOCOMP-228__20260803T154201Z.jsonl
---
<!-- COMMENTS:END -->
