---
id: EXOCOMP-142
type: task
status: In Validation
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
updated_at: '2026-08-03T15:22:46.797259Z'
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
  state: integrated
  attempts: 1
  task_branch: epic-EXOCOMP-129--task-EXOCOMP-142
  base_branch: epic-EXOCOMP-129
  base_sha: f1e60cb4a3aa94d1af2cdbdf4767e6a2ed4cc1fa
  head_sha: 5b60d46a078ed14b35d2f5c298f9cdc274dfdb3e
  integrated_sha: 5b60d46a078ed14b35d2f5c298f9cdc274dfdb3e
  submitted_at: '2026-08-01T12:16:15.061043+00:00'
  updated_at: '2026-08-03T15:22:13.269038+00:00'
  dependency_heads:
    EXOCOMP-141: d4c703e94c5ef16a5b0b9474e27a800ae5622d86
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
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-361e857359c2
    project_id: proj-c260b117
    task_id: EXOCOMP-142
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 7d4b304ab55f1c9ef3c9220a3361432255c208f9c07d75285042450da88db192
    attempts:
    - version: 1
      attempt_id: attempt-891d35d962ff
      target_state: Done
      request_state: in_progress
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 7d4b304ab55f1c9ef3c9220a3361432255c208f9c07d75285042450da88db192
      created_at: '2026-08-03T15:22:42.039788+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-03T15:22:42.039788+00:00'
      branch_key: epic-EXOCOMP-129--task-EXOCOMP-142
    requested_by:
      version: 1
      identity: oompah-integration
      source: service
    previous_state: Ready to Integrate
    created_at: '2026-08-03T15:22:15.383447+00:00'
    updated_at: '2026-08-03T15:22:42.039788+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-891d35d962ff
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 7d4b304ab55f1c9ef3c9220a3361432255c208f9c07d75285042450da88db192
    created_at: '2026-08-03T15:22:42.039788+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-03T15:22:42.039788+00:00'
    branch_key: epic-EXOCOMP-129--task-EXOCOMP-142
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
author: oompah
created: 2026-08-03 13:57
---
Operator workaround propagated dependency EXOCOMP-171 exact integrated SHA e826d0d5 through common parent EXOCOMP-127 into epic EXOCOMP-129. This task is no longer container-deadlocked and should become eligible immediately after EXOCOMP-171 passes terminal audit.
---
author: oompah
created: 2026-08-03 15:18
---
Operator deadlock workaround: the Ready row was waiting for EXOCOMP-171's repaired integrated SHA f1e60cb4a3aa94d1af2cdbdf4767e6a2ed4cc1fa to reach epic-EXOCOMP-129, while epic-EXOCOMP-134 already contained EXOCOMP-141's exact integrated SHA d4c703e94c5ef16a5b0b9474e27a800ae5622d86. Fast-forwarded epic-EXOCOMP-129 from e826d0d5 to f1e60cb4 and pushed with an exact lease. Both epic-EXOCOMP-129 and epic-EXOCOMP-134 now resolve to f1e60cb4, and both prerequisite SHAs are ancestors. OOMPAH-718 is the merged server fix that detects/fences this cross-container cycle class.
---
author: oompah
created: 2026-08-03 15:22
---
Queued for terminal transition to Done. An auditor will review and apply the terminal status.
---
author: oompah
created: 2026-08-03 15:22
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-03 15:22
---
Focus: Completion Auditor
---
<!-- COMMENTS:END -->
