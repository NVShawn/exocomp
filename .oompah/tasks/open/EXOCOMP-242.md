---
id: EXOCOMP-242
type: bug
status: Open
priority: 1
title: Repair M7B invitation and SPIFFE certificate regressions
parent: null
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T17:14:37.656789Z'
updated_at: '2026-08-03T17:27:07.956135Z'
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
oompah.agent_run_id: b85f91c2-179f-4ce7-b84f-529e60597611
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 1691
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 1691
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1691
    cost_usd: 0.0
    recorded_at: '2026-08-03T17:19:41.133127+00:00'
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
<!-- COMMENTS:END -->
