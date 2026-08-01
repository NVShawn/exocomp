---
id: EXOCOMP-142
type: task
status: Ready to Integrate
priority: 1
title: Create one-use cluster invitations
parent: EXOCOMP-129
children: []
blocked_by:
- EXOCOMP-141
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:14:24.463171Z'
updated_at: '2026-08-01T12:16:51.818948Z'
work_branch: epic-EXOCOMP-129--task-EXOCOMP-142
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: a878dc9c2770ae74c029518ed160ca9480609de0e2d6c26628971002a325ce17
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T11:56:05.509706+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active EXOCOMP-127, EXOCOMP-128, EXOCOMP-129,\
    \ EXOCOMP-138, EXOCOMP-141, EXOCOMP-143, EXOCOMP-144, EXOCOMP-170, EXOCOMP-171,\
    \ and EXOCOMP-181. They cover parent planning, organization scoping, authorization,\
    \ CSR enrollment, UI display, audit storage, or security tests; none duplicate\
    \ EXOCOMP-142\u2019s invitation creation and atomic single-use backend scope."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 962749f5-b91a-428a-b530-5c134ad09e35
oompah.work_branch: epic-EXOCOMP-129--task-EXOCOMP-142
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: epic-EXOCOMP-129--task-EXOCOMP-142
  head_sha: 97439b59b7134f4bdd7483d64763043aa86109da
  submitted_at: '2026-08-01T12:16:15.061043+00:00'
  updated_at: '2026-08-01T12:16:15.061043+00:00'
oompah.task_costs:
  total_input_tokens: 10200538
  total_output_tokens: 56711
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10200538
      output_tokens: 56711
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 801245
    output_tokens: 3780
    cost_usd: 0.0
    recorded_at: '2026-08-01T11:56:05.509321+00:00'
  - profile: default
    model: haiku
    input_tokens: 9399293
    output_tokens: 52931
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:16:50.580920+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-142__20260801T115430Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-129--task-EXOCOMP-142
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T11:56:05.515247+00:00'
---
## Summary

Plan: plans/mission-control.md, Cluster Enrollment and Identity.

Deliverables:
- Add cluster and invitation schemas scoped to an organization.
- Add an admin-only POST /api/v1/cluster-invitations endpoint.
- Generate a random invitation, show it once, store only its digest, and bind it to cluster name and optional labels.
- Add expiry and atomic single-use consumption helpers.

Acceptance:
- Tests cover creation, expiry, replay, wrong organization, duplicate cluster names, and concurrent consumption.
- Invitation plaintext is absent from the database and logs.
- Viewer and operator roles receive a forbidden response.

Out of scope: CSR signing and certificate renewal.
Quality gate: focused context/API tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 11:54
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 11:54
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 11:56
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 25
- Tokens: 801.2K in / 3.8K out [805.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 49s
- Log: EXOCOMP-142__20260801T115430Z.jsonl
---
author: oompah
created: 2026-08-01 11:56
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 11:56
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 11:56
---
Understanding: I will trace the existing organization auth, schema, persistence, and test patterns; implement scoped one-use cluster invitation creation and atomic consumption with digest-only storage; add focused coverage for expiry, replay, organization/role/name conflicts, and concurrency; then run the required quality gates.
---
author: oompah
created: 2026-08-01 11:57
---
Discovery: this branch has no Ecto/database layer or Mission Control app yet; the coordinator Plug router and GenServer-backed EnrollmentToken are the available integration points. I will follow that existing pattern with cryptographic digest-only storage, injected clocks/randomness, serialized atomic consumption, persistence, redacted audit metadata, and organization/role enforcement.
---
author: oompah
created: 2026-08-01 12:10
---
Implementation: added organization-scoped Cluster and ClusterInvitation schemas, durable serialized ClusterInvitationStore/context, digest-only random issuance, expiry and atomic single-use consumption, coordinator supervision/config wiring, and admin-only POST /api/v1/cluster-invitations handler/router integration. Added focused tests for creation, expiry, replay, wrong organization, duplicate names, concurrency, plaintext absence, and role enforcement.
---
author: oompah
created: 2026-08-01 12:13
---
Verification: manual OTP checks passed for digest-only persistence, restart durability, expiry boundary, wrong-organization non-consumption, replay rejection, and serialized concurrent consumption; new/changed files parse and are formatter-clean, and the pure store compiles with --warnings-as-errors. make test/make lint/make fmt-check reached the pinned builder invocation but could not run because the environment's docker/podman wrapper cannot access its read-only libpod config; direct mix test is additionally blocked by local Elixir 1.18.3 versus project Elixir 1.20.2.
---
author: oompah
created: 2026-08-01 12:16
---
Completion: delivered organization-scoped Cluster/ClusterInvitation schemas, digest-only random one-use invitations with expiry and serialized atomic consumption, durable staged-rename storage/configuration, admin-only POST /api/v1/cluster-invitations, and focused acceptance tests. Commit 97439b59 is pushed and the branch is up to date with origin. Focused/manual checks and static formatting passed; full Make gates were attempted but blocked at the unavailable docker/podman pinned-builder runtime, and direct mix test by the local Elixir 1.18.3 versus declared 1.20.2 mismatch.
---
author: oompah
created: 2026-08-01 12:16
---
Implemented organization-scoped one-use cluster invitations, digest-only persistence, expiry/replay/concurrency protection, admin API authorization, and focused tests. Pushed commit 97439b59.
---
author: oompah
created: 2026-08-01 12:16
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 111
- Tokens: 9.4M in / 52.9K out [9.5M total]
- Cost: $0.0000
- Exit: terminated, Duration: 20m 30s
- Log: EXOCOMP-142__20260801T115627Z.jsonl
---
<!-- COMMENTS:END -->
