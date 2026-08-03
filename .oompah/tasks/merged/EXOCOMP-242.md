---
id: EXOCOMP-242
type: bug
status: Merged
priority: 1
title: Repair M7B invitation and SPIFFE certificate regressions
parent: null
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T17:14:37.656789Z'
updated_at: '2026-08-03T19:22:39.238927Z'
work_branch: EXOCOMP-242
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/25
review_number: '25'
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
oompah.agent_run_id: null
oompah.task_costs:
  total_input_tokens: 1590
  total_output_tokens: 11124
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 1528
      output_tokens: 2043
      cost_usd: 0.0
    unknown:
      input_tokens: 62
      output_tokens: 9081
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
  - profile: auditor
    model: unknown
    input_tokens: 38
    output_tokens: 1315
    cost_usd: 0.0
    recorded_at: '2026-08-03T18:52:30.725907+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 24
    output_tokens: 7766
    cost_usd: 0.0
    recorded_at: '2026-08-03T19:12:13.279309+00:00'
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
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: EXOCOMP-242
  head_sha: 8e19679a414b0f22b6d837976486f1e4b2955f41
  submitted_at: '2026-08-03T18:39:39.660373+00:00'
  updated_at: '2026-08-03T18:39:39.660373+00:00'
oompah.review_url: https://github.com/NVShawn/exocomp/pull/25
oompah.review_number: '25'
oompah.work_branch: EXOCOMP-242
oompah.target_branch: main
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-61d980e1f759: '2026-08-03T19:11:41.560078+00:00'
    attempt-a15d3ab91c76: '2026-08-03T19:22:31.768592+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-242
    target_state: Done
    evidence_fingerprint: 20da3924a8bae1f5b64cca831ebd3463e8a8ee8f65a46375df8d022af4cf6118
    audit_ids:
    - audit-8b68063b9d88
    kind: result
    applied: true
    retired_at: '2026-08-03T19:11:41.560089+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-242
    target_state: Merged
    evidence_fingerprint: 20da3924a8bae1f5b64cca831ebd3463e8a8ee8f65a46375df8d022af4cf6118
    audit_ids:
    - audit-abb6b25c4ecf
    kind: result
    applied: true
    retired_at: '2026-08-03T19:22:31.768610+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-242
    audit_id: audit-8b68063b9d88
    attempt_id: attempt-61d980e1f759
    target_state: Done
    evidence_fingerprint: 20da3924a8bae1f5b64cca831ebd3463e8a8ee8f65a46375df8d022af4cf6118
    status: In Validation
    audit_ids:
    - audit-8b68063b9d88
    applied: true
    created_at: '2026-08-03T19:11:41.560105+00:00'
    applied_at: '2026-08-03T19:11:46.503724+00:00'
  - project_id: proj-c260b117
    task_id: EXOCOMP-242
    audit_id: audit-abb6b25c4ecf
    attempt_id: attempt-a15d3ab91c76
    target_state: Merged
    evidence_fingerprint: 20da3924a8bae1f5b64cca831ebd3463e8a8ee8f65a46375df8d022af4cf6118
    status: Merged
    audit_ids:
    - audit-abb6b25c4ecf
    applied: true
    created_at: '2026-08-03T19:22:31.768630+00:00'
    applied_at: '2026-08-03T19:22:38.346255+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-8b68063b9d88
    project_id: proj-c260b117
    task_id: EXOCOMP-242
    target_state: Done
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 20da3924a8bae1f5b64cca831ebd3463e8a8ee8f65a46375df8d022af4cf6118
    attempts:
    - version: 1
      attempt_id: attempt-1c2a25169f25
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 20da3924a8bae1f5b64cca831ebd3463e8a8ee8f65a46375df8d022af4cf6118
      created_at: '2026-08-03T18:45:09.181260+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-03T18:45:09.181260+00:00'
      branch_key: EXOCOMP-242
      failure_classification: policy_incompatibility
      ended_at: '2026-08-03T18:52:35.896904+00:00'
      failure_reason: 'read-only auditor exceeded the policy-denial limit (3): Error:
        auditor capability policy permits only read-only repository inspection and
        configured test commands; command denied'
      next_retry_at: '2026-08-03T18:52:45.896869+00:00'
    - version: 1
      attempt_id: attempt-61d980e1f759
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 20da3924a8bae1f5b64cca831ebd3463e8a8ee8f65a46375df8d022af4cf6118
      created_at: '2026-08-03T18:53:20.274838+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-08-03T18:53:20.274838+00:00'
      branch_key: EXOCOMP-242
      candidate_rotation_count: 1
      verdict: pass
      completed_at: '2026-08-03T19:11:41.559892+00:00'
      ended_at: '2026-08-03T19:11:41.559892+00:00'
    requested_by:
      version: 1
      identity: NVShawn
      source: forge
    previous_state: In Review
    created_at: '2026-08-03T18:43:24.846732+00:00'
    updated_at: '2026-08-03T19:11:41.559892+00:00'
  - version: 1
    audit_id: audit-abb6b25c4ecf
    project_id: proj-c260b117
    task_id: EXOCOMP-242
    target_state: Merged
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 20da3924a8bae1f5b64cca831ebd3463e8a8ee8f65a46375df8d022af4cf6118
    attempts:
    - version: 1
      attempt_id: attempt-a15d3ab91c76
      target_state: Merged
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 20da3924a8bae1f5b64cca831ebd3463e8a8ee8f65a46375df8d022af4cf6118
      created_at: '2026-08-03T19:13:02.047894+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-03T19:13:02.047894+00:00'
      branch_key: EXOCOMP-242
      verdict: pass
      completed_at: '2026-08-03T19:22:31.768382+00:00'
      ended_at: '2026-08-03T19:22:31.768382+00:00'
    requested_by:
      version: 1
      identity: NVShawn
      source: forge
    previous_state: In Review
    created_at: '2026-08-03T18:43:24.846732+00:00'
    updated_at: '2026-08-03T19:22:31.768382+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-1c2a25169f25
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 20da3924a8bae1f5b64cca831ebd3463e8a8ee8f65a46375df8d022af4cf6118
    created_at: '2026-08-03T18:45:09.181260+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-03T18:45:09.181260+00:00'
    branch_key: EXOCOMP-242
    failure_classification: policy_incompatibility
    ended_at: '2026-08-03T18:52:35.896904+00:00'
    failure_reason: 'read-only auditor exceeded the policy-denial limit (3): Error:
      auditor capability policy permits only read-only repository inspection and configured
      test commands; command denied'
    next_retry_at: '2026-08-03T18:52:45.896869+00:00'
  - version: 1
    attempt_id: attempt-61d980e1f759
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 20da3924a8bae1f5b64cca831ebd3463e8a8ee8f65a46375df8d022af4cf6118
    created_at: '2026-08-03T18:53:20.274838+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-08-03T18:53:20.274838+00:00'
    branch_key: EXOCOMP-242
    candidate_rotation_count: 1
  - version: 1
    attempt_id: attempt-a15d3ab91c76
    target_state: Merged
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 20da3924a8bae1f5b64cca831ebd3463e8a8ee8f65a46375df8d022af4cf6118
    created_at: '2026-08-03T19:13:02.047894+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-03T19:13:02.047894+00:00'
    branch_key: EXOCOMP-242
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
author: oompah
created: 2026-08-03 18:30
---
Understanding: Resuming the preserved EXOCOMP-242 branch state. I will inspect the current invitation-auth and CSR fixture edits, reconcile them with the pinned OTP/X509 GeneralName requirements and lifecycle-safe invitation fixtures, run focused regressions plus make fmt-check, make test, and make lint, then commit, push, and submit the exact repaired head.
---
author: oompah
created: 2026-08-03 18:34
---
Discovery: The pinned OTP 28/X509 GeneralName encoder requires SPIFFE URI SAN values as Erlang charlists. Current CSR fixtures and production leaf issuance pass binaries, causing valid enrollment requests to fail CSR validation with 422. Decoded SANs also require binary/charlist normalization. The invitation helper needs Map.new(attrs), the clock fixtures are already supervised, and auth fallback must not synthesize an alternate string key while a nil role must map to unauthenticated.
---
author: oompah
created: 2026-08-03 18:34
---
Implementation: Updated CSR fixtures and production certificate issuance to encode SPIFFE URI GeneralNames as charlists; normalized decoded binary/charlist URI values before exact single-identity validation; corrected invitation-test attrs via Map.new/1; retained supervised clock fixtures; and hardened auth lookup so missing org/role deterministically returns 401. Ran the pinned Makefile formatter through the existing remote Podman service; it also normalized pre-existing formatting in coordinator_router.ex.
---
author: oompah
created: 2026-08-03 18:38
---
Verification: Final pinned Elixir 1.20.2/OTP 28.5.0.3 gates all pass. make test passed every umbrella ExUnit suite (including 530 coordinator tests), assembled both releases, and passed exocomp_node/exocomp_coordinator bundled-ERTS smoke tests. make fmt-check passed. make lint passed release-builder checks, warnings-as-errors compilation, Python syntax checks, and compliance checks.
---
author: oompah
created: 2026-08-03 18:39
---
Completion: Delivered commit 8e19679a414b0f22b6d837976486f1e4b2955f41 on origin/EXOCOMP-242. The repair uses pinned-runtime-compatible SPIFFE GeneralNames in CSR fixtures and issued certificates, normalizes URI decoding, hardens missing-auth handling, fixes invitation attrs/clock fixtures, and explicitly covers valid, wrong, and multiple SPIFFE identities plus invitation expiry/replay, plaintext non-persistence, and missing authentication. All required gates and release smoke tests pass; branch is clean and matches origin.
---
author: oompah
created: 2026-08-03 18:39
---
Repaired M7B invitation and SPIFFE certificate regressions with OTP-compatible URI GeneralNames, deterministic missing-auth rejection, lifecycle-safe invitation fixtures, and explicit identity regression coverage. Pinned make fmt-check, make test including both release smoke tests, and make lint all pass at 8e19679a414b0f22b6d837976486f1e4b2955f41.
---
author: oompah
created: 2026-08-03 18:40
---
Run #2 [attempt=2, profile=deep, role=deep -> Codex/gpt-5.6-sol]
- Turns: 0, Tool calls: 74
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 10m 14s
- Log: EXOCOMP-242__20260803T183023Z.jsonl
---
author: oompah
created: 2026-08-03 18:43
---
Queued for terminal transition to Merged. An auditor will review and apply the terminal status.
---
author: oompah
created: 2026-08-03 18:43
---
YOLO: merged PR #25.
---
author: oompah
created: 2026-08-03 18:45
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-03 18:45
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-03 18:52
---
Run #1 [attempt=1, profile=auditor, role=auditor -> Claude/opus]
- Turns: 0, Tool calls: 21
- Tokens: 38 in / 1.3K out [1.4K total]
- Cost: $0.0000
- Exit: terminated, Duration: 7m 8s
- Log: EXOCOMP-242__20260803T184529Z.jsonl
---
author: oompah
created: 2026-08-03 18:52
---
Auditor attempt was stopped after repeated policy denials; a different independent candidate will be tried.
---
author: oompah
created: 2026-08-03 18:53
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-08-03 18:53
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-03 19:11
---
Audit PASS — Done

[REDACTED]

Safe evidence:
- merge_commit: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
- repair_commit: 8e19679a414b0f22b6d837976486f1e4b2955f41
- pr: 25
- branch: EXOCOMP-242
- merged_to: main
- spiffe_charlist_production: cluster_issuer.ex:311 String.to_charlist(spiffe_uri)
- normalize_uri: cluster_issuer.ex:327-329
- missing_auth_401: cluster_invitation_handler.ex:143 role == nil -> {:error, :unauthenticated}
- test_missing_auth: cluster_invitation_test.exs:197 'missing authentication is rejected' asserts 401
- test_wrong_spiffe: cluster_enrollment_test.exs:295 'rejects a CSR with the wrong SPIFFE identity'
- test_multiple_uris: cluster_enrollment_test.exs: 'rejects a CSR with multiple URI identities'
- test_expiry_replay: cluster_enrollment_test.exs: 'rejects expired and replayed invitations'
- test_plaintext: cluster_invitation_test.exs: 'creates an organization-scoped invitation and never persists its plaintext'
---
author: oompah
created: 2026-08-03 19:12
---
Run #2 [attempt=2, profile=auditor, role=auditor -> Claude/sonnet]
- Turns: 40, Tool calls: 30
- Tokens: 24 in / 7.8K out [7.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 18m 49s
- Log: EXOCOMP-242__20260803T185335Z.jsonl
---
author: oompah
created: 2026-08-03 19:13
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-03 19:13
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-03 19:22
---
Audit PASS — Merged

[REDACTED]

Safe evidence:
- merge_commit: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
- repair_commit: 8e19679a414b0f22b6d837976486f1e4b2955f41
- pr: 25
- branch: EXOCOMP-242
- merged_to: main
- origin_main_head: 58f3cec5010be13ebe3bdd572bcbed4aa459e107
- spiffe_charlist_production: cluster_issuer.ex:311 String.to_charlist(spiffe_uri)
- normalize_uri: cluster_issuer.ex:327-329 binary/charlist -> string
- missing_auth_401: cluster_invitation_handler.ex:142-143 role == nil and invalid org -> unauthenticated
- attrs_normalization: cluster_invitation_test.exs:33 Map.new(attrs)
- clock_supervised: cluster_invitation_test.exs:20 start_supervised!({Agent, ...})
- test_missing_auth: cluster_invitation_test.exs:197 asserts 401
- test_wrong_spiffe: cluster_enrollment_test.exs:295
- test_multiple_uris: cluster_enrollment_test.exs:304 (charlist SANs)
- test_expiry_replay: cluster_enrollment_test.exs:228
- test_plaintext: cluster_invitation_test.exs:46
- working_tree: clean
---
<!-- COMMENTS:END -->
