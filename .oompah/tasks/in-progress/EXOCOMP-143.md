---
id: EXOCOMP-143
type: task
status: In Progress
priority: 1
title: Issue cluster certificates from validated CSRs
parent: EXOCOMP-129
children: []
blocked_by:
- EXOCOMP-142
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:14:25.708004Z'
updated_at: '2026-08-01T11:59:53.045759Z'
work_branch: epic-EXOCOMP-129--task-EXOCOMP-143
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 61c3ed9793b90e51c9ccee4659a410e6fd66b6995ecb7ead785f83d2833424b8
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T11:58:08.352182+00:00'
  matched_identifiers: []
  evidence: "Acknowledged. This coordination message from EXOCOMP-141 confirms another\
    \ epic-sibling has started implementation. This is consistent with the epic-EXOCOMP-129\
    \ decomposition where multiple related but distinct work streams are proceeding\
    \ in parallel.\n\nThe coordination system is working as intended\u2014notifying\
    \ related tasks when peers start work. This does not indicate duplication; it\
    \ indicates coordinated, parallel implementation of different Mission Control\
    \ components.\n\n**Investigation Status: Complete**\n\nMy duplicate investigation\
    \ conclusion remains unchanged:\n\n**Focus handoff: duplicate_detector**\n\n**Duplicate\
    \ preflight verdict: no_duplicate**\n\n**Matches: none**\n\n**Evidence:** Comprehensive\
    \ search of codebase, plans, and task coordination metadata reveals EXOCOMP-143\
    \ is a discrete implementation task for cluster certificate issuance. Epic-siblings\
    \ EXOCOMP-140, 141, 142, and 144 are starting in parallel with distinct scopes.\
    \ No existing code, completed tasks, or competing implementations cover the same\
    \ functionality. The POST /api/v1/clusters/enroll endpoint and certificate-signing\
    \ logic do not exist in the codebase."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 9e3454f8-3dde-4ffb-9c9d-ca487440253c
oompah.work_branch: epic-EXOCOMP-129--task-EXOCOMP-143
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-129--task-EXOCOMP-143
  base_branch: epic-EXOCOMP-129
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T11:58:29.695935+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 416
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 416
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 416
    cost_usd: 0.0
    recorded_at: '2026-08-01T11:58:08.351339+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-143__20260801T115618Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-129--task-EXOCOMP-143
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T11:58:08.358906+00:00'
---
## Summary

Plan: plans/mission-control.md, Cluster Enrollment and Identity.

Deliverables:
- Add the POST /api/v1/clusters/enroll invitation-and-CSR exchange.
- Validate CSR signature and allowed key parameters.
- Issue a 30-day client certificate from the configured online intermediate using the planned SPIFFE URI identity.
- Persist certificate serial and public metadata; never receive or store the coordinator private key.

Acceptance:
- Tests cover a valid CSR, malformed/unsigned CSR, unsupported key, expired/replayed invitation, wrong cluster binding, and signing failure.
- The returned chain validates to the configured Mission Control trust root.
- The certificate organization and cluster IDs match persisted records.

Out of scope: renewal, revocation, and WebSocket authentication.
Quality gate: focused PKI/API tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 11:56
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 11:56
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 11:58
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 55, Tool calls: 27
- Tokens: 10 in / 416 out [426 total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 56s
- Log: EXOCOMP-143__20260801T115618Z.jsonl
---
author: oompah
created: 2026-08-01 11:58
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 11:58
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 11:59
---
**Understanding**: Need to implement POST /api/v1/clusters/enroll endpoint for Mission Control cluster certificate issuance (separate from existing node enrollment at POST /v1/enroll). Must: validate cluster CSR signature & key params, issue 30-day cert with SPIFFE URI identity, persist cert serial/metadata without storing coordinator private key. Acceptance: tests for valid/malformed CSR, unsupported key, expired/replayed invitation, wrong binding, signing failure; returned chain validates to trust root; org/cluster IDs match persisted records. Next: explore EXOCOMP-142 outputs, check if invitation infrastructure exists, implement cluster enrollment handler and PKI updates.
---
<!-- COMMENTS:END -->
