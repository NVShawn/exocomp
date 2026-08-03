---
id: EXOCOMP-242
type: bug
status: In Progress
priority: 1
title: Repair M7B invitation and SPIFFE certificate regressions
parent: null
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T17:14:37.656789Z'
updated_at: '2026-08-03T18:30:06.860761Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 14c1ea8de63462c2e449fce9b670ce773684e978440c72ad92d1146eb5ea31e9
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T17:19:41.133992+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: The task corpus contains no active task covering SPIFFE\
    \ certificate-enrollment regressions, CSR fixture GeneralName representation issues,\
    \ cluster-invitation test helper lifecycle safety, or clock fixture determinism.\
    \ The closest related tasks (EXOCOMP-107, EXOCOMP-119) are in terminal states\
    \ and address distinct scopes: node-side enrollment implementation and production\
    \ PKI component wiring, not the test infrastructure and certificate-issuance regressions\
    \ EXOCOMP-242 repairs. All other coordinator tasks predate M7B work. No duplicate\
    \ found; this task should proceed to implementation.\nLooking at **EXOCOMP-242**\
    \ against the supplied project task corpus, I need to determine if this is a duplicate\
    \ of an existing active task.\n\n## Analysis\n\n**Current task (EXOCOMP-242):**\
    \ Repair M7B invitation and SPIFFE certificate regressions\n- Specific issues:\
    \ OTP/X509 GeneralName representation for SPIFFE URI SANs in CSR fixtures, cluster-invitation\
    \ test helper attrs normalization, clock fixture lifecycle safety, deterministic\
    \ 401 auth rejection\n- Triggered by: EXOCOMP-143 (parent integration failure)\n\
    - Scope: apps/exocomp_coordinator PKI and test infrastructure\n\n**Reviewed candidates\
    \ from corpus:**\n\n1. **EXOCOMP-119** (Archived/Merged): \"Start production coordinator\
    \ PKI and enrollment services\"\n   - Covers production PKI/enrollment component\
    \ wiring, not test regressions\n   - No mention of SPIFFE URI SANs, CSR fixture\
    \ issues, or test helper lifecycle problems\n   - Terminal state (historical)\n\
    \n2. **EXOCOMP-107** (Archived/Merged): \"Implement node-agent enrollment client,\
    \ credential installer, renewal scheduler\"\n   - Node-side enrollment implementation,\
    \ not coordinator-side PKI issuance bugs\n   - Doesn't address CSR fixture representation\
    \ or test helper normalization\n   - Terminal state (historical)\n\n3. **EXOCOMP-14,\
    \ EXOCOMP-15, EXOCOMP-100-105**: Coordinator scaffolding and orchestration\n \
    \  - Distinct scopes (inventory, polling, diagnostic orchestration)\n   - Pre-date\
    \ the M7B certificate enrollment work\n   - All in terminal states\n\n**Active\
    \ tasks in corpus:** Only EXOCOMP-242 is Open; all others are Archived or Merged.\n\
    \nThe specific regression issues EXOCOMP-242 addresses\u2014SPIFFE URI SAN representation,\
    \ CSR fixture format, test helper attrs normalization, clock fixture lifecycle,\
    \ deterministic auth rejection without async leakage\u2014do not appear in any\
    \ completed task's scope.\n\n---\n\nFocus handoff: duplicate_detector\n\nDuplicate\
    \ preflight verdict: no_duplicate\n\nMatches: none\n\nEvidence: The task corpus\
    \ contains no active task covering SPIFFE certificate-enrollment regress"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 6c975227-bf9a-4908-a527-20f79bb2c8e7
oompah.task_costs:
  total_input_tokens: 1528
  total_output_tokens: 2043
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 1528
      output_tokens: 2043
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1691
    cost_usd: 0.0
    recorded_at: '2026-08-03T17:19:41.133127+00:00'
  - profile: default
    model: haiku
    input_tokens: 1518
    output_tokens: 352
    cost_usd: 0.0
    recorded_at: '2026-08-03T18:29:23.323299+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-242__20260803T171840Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: EXOCOMP-242
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T17:19:41.142721+00:00'
---
## Summary

Triggered by: EXOCOMP-143

The integrated EXOCOMP-142/143 parent fails the repository make test gate. Repair the cluster invitation and certificate-enrollment regressions in apps/exocomp_coordinator: use the OTP/X509 GeneralName representation accepted by the pinned runtime for SPIFFE URI SANs in both CSR fixtures and production certificate issuance; correct the cluster-invitation test helper's attrs normalization; make its clock fixture lifecycle-safe; and ensure a request with no authentication deterministically returns 401 without leaking async test context. Add or retain regression coverage proving valid CSR issuance, multiple/wrong SPIFFE identity rejection, invitation expiry/replay behavior, plaintext-token non-persistence, and missing-auth rejection. Acceptance: make fmt-check, make test, and make lint pass on the repaired branch, including release smoke tests.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 17:18
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 17:18
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 17:19
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 1.7K out [1.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 10s
- Log: EXOCOMP-242__20260803T171840Z.jsonl
---
author: oompah
created: 2026-08-03 17:21
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-03 17:21
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-03 17:21
---
Understanding: I will inspect the coordinator's cluster-invitation and SPIFFE certificate paths, reproduce the pinned-runtime regressions, add focused regression coverage, run the required Makefile quality gates, then commit, push, and submit the repaired branch.
---
author: oompah
created: 2026-08-03 17:26
---
Operator workaround is validated and published in merge commit 24f84e9459c72cb9354dc47e6f531118e14fcfaa on epic-EXOCOMP-132. It fixes GeneralName encoding/normalization, missing-auth fallback, attrs normalization, and supervised clock fixtures. Focused invitation/enrollment tests: 18 passed. Full make test: 682 passed plus both release smoke tests. make fmt-check and make lint passed. Permanent repair still belongs on the authoritative EXOCOMP-127 parent/main path, so this task is being returned to Open for normal server implementation/integration.
---
author: oompah
created: 2026-08-03 17:27
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 55
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 6m 3s
- Log: EXOCOMP-242__20260803T172124Z.jsonl
---
author: oompah
created: 2026-08-03 17:28
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-03 17:28
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-03 17:29
---
Understanding: Reviewing the current branch state. The branch has 4 commits implementing cluster invitations (EXOCOMP-142) and certificate enrollment (EXOCOMP-143). Previous work indicated regressions exist in GeneralName encoding, attrs normalization, clock fixtures, and missing-auth handling. Will verify test state and ensure all quality gates pass (make fmt-check, make test, make lint, including release smoke tests).
---
author: oompah
created: 2026-08-03 17:39
---
Discovery: 6 tests failing - all cluster enrollment tests returning 422 instead of expected 200/401/503. The issue is with CSR validation likely in SPIFFE URI SAN GeneralName representation. Examining cluster_issuer.ex and test fixtures for: (1) GeneralName encoding for SPIFFE URIs, (2) attrs normalization in test helper, (3) clock fixture lifecycle safety, (4) missing-auth handling returning correct status codes.
---
author: oompah
created: 2026-08-03 18:28
---
Progress: Fixed missing-auth handler to return 401 instead of 403 by checking if role is nil before validating role is admin. All ClusterInvitationTest tests now passing (524/529 total). Remaining issue: 5 ClusterEnrollmentTest tests getting 422 instead of expected 200/401/503. All CSR validations failing - need to investigate CSR fixture creation or validation logic.
---
author: oompah
created: 2026-08-03 18:29
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 189, Tool calls: 87
- Tokens: 1.5K in / 352 out [1.9K total]
- Cost: $0.0000
- Exit: stalled, Duration: 1h 0m 57s
- Log: EXOCOMP-242__20260803T172833Z.jsonl
---
author: oompah
created: 2026-08-03 18:29
---
Agent stalled 1 time(s) (3657s (1870 tokens)). Escalating from 'default' to 'deep'. Retrying in 10s (attempt #1)
---
author: oompah
created: 2026-08-03 18:29
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-08-03 18:30
---
Focus: Maintenance Engineer
---
<!-- COMMENTS:END -->
