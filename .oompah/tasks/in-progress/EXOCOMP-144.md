---
id: EXOCOMP-144
type: task
status: In Progress
priority: 1
title: Add cluster certificate renewal and revocation
parent: EXOCOMP-129
children: []
blocked_by:
- EXOCOMP-143
start_blocked_by: []
labels:
- focus-complete:frontend
assignee: null
created_at: '2026-07-30T14:14:27.914202Z'
updated_at: '2026-08-03T16:15:44.173321Z'
work_branch: epic-EXOCOMP-129--task-EXOCOMP-144
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 7f788b690fe18007128498a1d78db1652371cfcd3f0f36c0dc220000f7316674
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:08:51.156614+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active EXOCOMP-143, EXOCOMP-146, EXOCOMP-170,\
    \ EXOCOMP-178, and EXOCOMP-181. EXOCOMP-143 explicitly excludes renewal and revocation;\
    \ the others cover transport, UI, documentation, or security tests. No active\
    \ task duplicates EXOCOMP-144\u2019s implementation scope."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 6397da3e-9a71-4c13-8d99-681e6687bff0
oompah.work_branch: epic-EXOCOMP-129--task-EXOCOMP-144
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-129--task-EXOCOMP-144
  base_branch: epic-EXOCOMP-129
  base_sha: ad46c4b4efb6dea6934c78e26a6ec9e2c10c33b0
  updated_at: '2026-08-03T16:15:16.678646+00:00'
oompah.task_costs:
  total_input_tokens: 1841803
  total_output_tokens: 22368
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 1573726
      output_tokens: 15273
      cost_usd: 0.0
    sonnet:
      input_tokens: 268077
      output_tokens: 7095
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 1573534
    output_tokens: 15224
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:08:51.155808+00:00'
  - profile: default
    model: haiku
    input_tokens: 192
    output_tokens: 49
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:10:12.567101+00:00'
  - profile: standard
    model: sonnet
    input_tokens: 267941
    output_tokens: 2205
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:12:46.704189+00:00'
  - profile: standard
    model: sonnet
    input_tokens: 136
    output_tokens: 4890
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:35:52.157049+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-144__20260801T115823Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-129--task-EXOCOMP-144
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:08:51.185286+00:00'
  - run_id: EXOCOMP-144__20260801T121136Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-terra
    focus: frontend
    source_branch: epic-EXOCOMP-129--task-EXOCOMP-144
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:12:46.707573+00:00'
---
## Summary

Plan: plans/mission-control.md, Cluster Enrollment and Identity.

Deliverables:
- Add authenticated POST /api/v1/clusters/renew certificate renewal.
- Permit renewal after day 20 for a valid non-revoked cluster identity and rotate the certificate serial.
- Add admin context operations to revoke a cluster and its active certificate serials.
- Expose deterministic certificate status lookup for the connection gateway.

Acceptance:
- Tests cover early renewal, valid renewal, expired certificate, revoked cluster, identity mismatch, concurrent renewal, and signing failure.
- Revoked identities cannot renew.
- Private keys remain coordinator-local.

Out of scope: UI and active WebSocket disconnection.
Quality gate: focused PKI tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 11:58
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 11:58
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:08
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 3, Tool calls: 115
- Tokens: 1.6M in / 15.2K out [1.6M total]
- Cost: $0.0000
- Exit: normal, Duration: 10m 37s
- Log: EXOCOMP-144__20260801T115823Z.jsonl
---
author: oompah
created: 2026-08-01 12:09
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:09
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 12:09
---
Understanding: EXOCOMP-144 requires backend PKI implementation including:
1. Authenticated POST /api/v1/clusters/renew endpoint for certificate renewal
2. Certificate serial rotation and 20-day renewal eligibility logic
3. Admin operations to revoke clusters and their certificate serials
4. Deterministic certificate status lookup for the connection gateway

Tests needed for early/valid renewal, expired certs, revoked clusters, identity mismatches, concurrent renewal, signing failures.

However, this task is marked for Frontend Developer focus. The deliverables are backend API and PKI operations with UI explicitly out of scope. No LiveView or UI work is required here. This appears to be a focus mismatch - the work needs a backend specialist, not frontend expertise.
---
author: oompah
created: 2026-08-01 12:09
---
HANDOFF: This task requires backend implementation expertise, not frontend development. The deliverables are:
- API endpoint implementation (POST /api/v1/clusters/renew)
- PKI operations (certificate generation, serial rotation, revocation)
- Database operations (storing certificate serials, revocation status)
- Deterministic certificate lookup logic
- Comprehensive test coverage for PKI scenarios

The task explicitly states 'Out of scope: UI and active WebSocket disconnection,' confirming this is backend-only work. Task is blocked by EXOCOMP-143 (dependency). A backend specialist should take this to implement the certificate renewal/revocation logic in the coordinator app.
---
author: oompah
created: 2026-08-01 12:10
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 0, Tool calls: 11
- Tokens: 192 in / 49 out [241 total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 9s
- Log: EXOCOMP-144__20260801T120912Z.jsonl
---
author: oompah
created: 2026-08-01 12:11
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-08-01 12:11
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 12:11
---
Understanding: EXOCOMP-144 requires coordinator-side certificate renewal, revocation, and status lookup. UI and active WebSocket disconnection are explicitly out of scope. In this frontend-focused session I will verify whether a UI contribution exists, identify the owning backend areas, and hand off with evidence if none does.
---
author: oompah
created: 2026-08-01 12:12
---
Discovery: No frontend application or UI component exists for this scope. The implementation belongs in apps/exocomp_coordinator: coordinator_router.ex, handlers/renewal_handler.ex, PKI issuer/state, plus coordinator PKI/integration tests. The existing mission-control plan confirms renewal is mTLS-authenticated and derives organization/cluster identity solely from the validated certificate.
---
author: oompah
created: 2026-08-01 12:12
---
Verification: Confirmed the worktree is clean and inspected the relevant implementation and test locations. No frontend code change is warranted; therefore no UI test or repository quality gate applies in this focus-only session.
---
author: oompah
created: 2026-08-01 12:12
---
Focus handoff: frontend\n\nOutcome: no UI work is in scope or required; the issue is fully backend PKI/API work.\nEvidence: plans/mission-control.md:127-160 defines the authenticated renewal endpoint and certificate-derived identity. Relevant code is apps/exocomp_coordinator/lib/exocomp/coordinator/coordinator_router.ex, handlers/renewal_handler.ex, pki/{issuer,state}.ex, with existing tests under apps/exocomp_coordinator/test/exocomp/coordinator/pki and test/integration/coordinator_pki_enrollment_test.exs.\nRemaining work/risks: implement renewal eligibility, transactional serial rotation and revocation, deterministic gateway lookup, and the listed failure/concurrency tests while retaining coordinator-local private-key ownership.\nRecommended next focus: feature.
---
author: oompah
created: 2026-08-01 12:12
---
Agent completed successfully in 77s (270146 tokens)
---
author: oompah
created: 2026-08-01 12:12
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/gpt-5.6-terra]
- Turns: 1, Tool calls: 12
- Tokens: 267.9K in / 2.2K out [270.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 17s
- Log: EXOCOMP-144__20260801T121136Z.jsonl
---
author: oompah
created: 2026-08-01 12:12
---
Focus handoff from `frontend` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-08-01 12:13
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-08-01 12:13
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 12:13
---
Understanding: EXOCOMP-144 requires implementing PKI certificate renewal and revocation in the coordinator app. As Maintenance Engineer, I'll implement: (1) POST /api/v1/clusters/renew endpoint authenticated via mTLS, (2) renewal eligibility after day 20 with serial rotation, (3) admin revocation of cluster identities and certificate serials, (4) deterministic certificate status lookup for the gateway. Starting with codebase exploration to understand existing PKI patterns before implementing.
---
author: oompah
created: 2026-08-01 12:21
---
Discovery: Examined the full coordinator PKI stack. The existing renewal handler (apps/exocomp_coordinator/lib/exocomp/coordinator/handlers/renewal_handler.ex) already handles mTLS cert extraction and CSR validation but has NO eligibility check, no revocation support, and no serial tracking. Key files: pki/{issuer,state,bootstrap}.ex, coordinator_router.ex, enrollment_token.ex (pattern for durable store). Implementation plan: (1) New PKI.CertificateRegistry GenServer tracking issued serials + revocations with disk persistence; (2) Enhanced RenewalHandler with day-20 eligibility check, revocation check, serial registration; (3) New /api/v1/clusters/renew route in CoordinatorRouter alongside existing /v1/renew; (4) Admin revoke_identity/revoke_serial functions; (5) certificate_status/1 for gateway. Tests: unit tests for CertificateRegistry + integration tests covering all 7 acceptance scenarios.
---
author: oompah
created: 2026-08-01 12:34
---
Implementation: Added cluster certificate renewal and revocation.

Changes:
1. NEW apps/exocomp_coordinator/lib/exocomp/coordinator/pki/certificate_registry.ex — GenServer tracking issued certificate serials and explicit revocations. Persists state to JSON (mode-0700 dir, mode-0600 files) with atomic rename. Public API: register/5, revoke_serial/2, revoke_identity/2, certificate_status/2, identity_status/2, status/1. Includes ASN.1 time-to-Unix conversion.

2. MODIFIED apps/exocomp_coordinator/lib/exocomp/coordinator/handlers/renewal_handler.ex — Enhanced with-chain: extract cert info → parse body → require CSR → pki_online_state() → check_not_expired → check_renewal_window (day 20 of 30-day cert = renewal_opens_at = not_before + 20*86400) → check_revocation (serial + identity) → validate_csr → issue_leaf → extract_issued_serial → register_serial. New error codes: cert_expired→401, renewal_too_early→403, certificate_revoked→403, identity_revoked→403.

3. MODIFIED apps/exocomp_coordinator/lib/exocomp/coordinator/coordinator_router.ex — Added POST /api/v1/clusters/renew route dispatching to RenewalHandler.

4. MODIFIED apps/exocomp_coordinator/lib/exocomp/coordinator/application.ex — CertificateRegistry added to pki_and_listener_children/0; configurable cert_registry_store_path.

5. NEW apps/exocomp_coordinator/test/exocomp/coordinator/pki/certificate_registry_test.exs — 22 unit tests.

6. NEW apps/exocomp_coordinator/test/integration/coordinator_pki_renewal_test.exs — 28 integration tests covering early renewal, valid renewal, expired cert, revoked cluster, identity mismatch, concurrent renewal, and signing failure.

Private keys remain coordinator-local; serial rotation happens naturally on each new issuance.
---
author: oompah
created: 2026-08-01 12:35
---
Verification: All 561 tests pass (make test / docker run mix test).

- 22 CertificateRegistry unit tests: register, revoke_serial, revoke_identity, certificate_status, identity_status, concurrent safety, ASN.1 time parsing, JSON persistence and reload, path security.
- 28 RenewalHandler/integration tests: early renewal (403), valid renewal window (acceptance via registry + issuer directly tested), expired certificate (401), revoked cluster (403), identity_revoked (403), identity mismatch (CSR CN mismatch → 400), concurrent renewal (no corruption), signing failure (mock injected), missing cert (401), body parse errors.
- All pre-existing 511 tests continue to pass.

make fmt-check: clean. make lint: clean.
---
author: oompah
created: 2026-08-01 12:35
---
Completion: EXOCOMP-144 implementation is complete and pushed.

Delivered:
- POST /api/v1/clusters/renew authenticated renewal endpoint (mTLS cert required)
- Day-20 renewal eligibility window enforced (renewal_opens_at = not_before + 20*86400)
- PKI.CertificateRegistry GenServer for serial tracking and revocation (serial and identity)
- Admin-callable revoke_identity/2 and revoke_serial/2 operations
- Deterministic certificate_status/2 and identity_status/2 lookups for gateway use
- Certificate serial rotation on each renewal (new issuance = new serial)
- Private keys remain coordinator-local throughout
- 50 new tests (22 unit + 28 integration); all 561 total tests pass
- Branch: epic-EXOCOMP-129--task-EXOCOMP-144 @ 2dad75ac
---
author: oompah
created: 2026-08-01 12:35
---
Added cluster certificate renewal and revocation: POST /api/v1/clusters/renew endpoint with day-20 eligibility, PKI.CertificateRegistry GenServer for serial/identity revocation tracking, serial rotation on renewal, deterministic gateway status lookups. 50 new tests (22 unit + 28 integration); all 561 tests pass.
---
author: oompah
created: 2026-08-01 12:35
---
Run #1 [attempt=1, profile=standard, role=standard -> Claude/sonnet]
- Turns: 0, Tool calls: 93
- Tokens: 136 in / 4.9K out [5.0K total]
- Cost: $0.0000
- Exit: terminated, Duration: 22m 51s
- Log: EXOCOMP-144__20260801T121309Z.jsonl
---
author: oompah
created: 2026-08-03 16:14
---
Integration found a rebase conflict on `epic-EXOCOMP-129--task-EXOCOMP-144`. Resolve it against `epic-EXOCOMP-129`, run the required tests, push the same private branch, and `oompah task submit` it again.
---
author: oompah
created: 2026-08-03 16:15
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-08-03 16:15
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-03 16:15
---
Understanding: I will extend the coordinator PKI flow with authenticated cluster certificate renewal, atomic serial rotation/revocation, admin revocation operations, and gateway status lookup. I will first reconcile the enrollment dependency and existing interfaces, then add focused coverage before running the required gates.
---
<!-- COMMENTS:END -->
