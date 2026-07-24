---
id: EXOCOMP-77
type: task
status: Open
priority: 1
title: Integrate coordinator PKI initialization and enrollment operations
parent: EXOCOMP-16
children: []
blocked_by:
- EXOCOMP-75
- EXOCOMP-76
labels:
- focus-complete:duplicate_detector
- focus-complete:security
- focus-complete:chore
- needs:feature
assignee: null
created_at: '2026-07-23T23:01:30.250567Z'
updated_at: '2026-07-24T01:49:13.031841Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 5dd87f08-0370-4d33-9296-4711399ab211
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 271368
  total_output_tokens: 31579
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 271368
      output_tokens: 31579
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 271298
    output_tokens: 2037
    cost_usd: 0.0
    recorded_at: '2026-07-24T01:34:41.597005+00:00'
  - profile: default
    model: unknown
    input_tokens: 70
    output_tokens: 29542
    cost_usd: 0.0
    recorded_at: '2026-07-24T01:47:44.703541+00:00'
---
## Summary

Integrate EXOCOMP-75 PKI bootstrap and EXOCOMP-76 enrollment tokens into the coordinator application and operator workflow. Extend the EXOCOMP-14 supervision tree so runtime services start only from validated protected state and expose health/errors without secrets. Add configuration for explicit online-state and offline-root-backup paths and an operator-facing initialization entry point using the repository convention (prefer a Mix task if no CLI exists). Initialization output must clearly identify the offline backup path and root fingerprint, must never print private keys or protection inputs, and must distinguish newly initialized, already initialized, and invalid-state outcomes with stable exit behavior. Wire the enrollment issue/consume boundary needed by EXOCOMP-17 without implementing CSR issuance or node-side enrollment. Add integration tests covering clean initialization followed by application start, idempotent rerun, missing/corrupt/insecure material startup failure, explicit backup output, token issue/consume through the supervised service, restart replay rejection, audit outage fail-closed behavior, and captured log/output redaction. Verify private paths/modes and assert no root private key is retained online. Run all affected Make targets: make fmt-check, make build, make test, and make lint. Acceptance: coordinator startup uses validated PKI state, operator initialization is explicit and safe, token operations are supervised/audited/fail-closed, cross-cutting security tests pass, and the EXOCOMP-17 interface is documented in module contracts.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 01:33
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 01:33
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 01:33
---
Understanding: Screening EXOCOMP-77 for duplication only. I will search existing tasks and project docs for coordinator PKI initialization, protected-state startup, and enrollment issue/consume integration; inspect full candidate task descriptions/comments; then either archive as a confirmed duplicate or document no duplicate and hand off to implementation.
---
author: oompah
created: 2026-07-24 01:34
---
Discovery: No duplicate confirmed. EXOCOMP-16 comments #19-23 explicitly created EXOCOMP-77 as the distinct integration child after separating PKI bootstrap into EXOCOMP-75 and durable enrollment tokens into EXOCOMP-76. EXOCOMP-14 supplies the supervision/inventory/audit foundation, while EXOCOMP-17 is the node-side consumer. None covers EXOCOMP-77's operator Mix task, protected-state startup validation, supervised issue/consume boundary, or cross-cutting integration/security verification.
---
author: oompah
created: 2026-07-24 01:34
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no duplicate; EXOCOMP-77 should proceed to implementation.

Evidence: Local search reviewed plans/milestone-2-coordinator.md and related docs; the worktree has no .oompah/tasks mirror. Full tracker histories were reviewed for EXOCOMP-14, EXOCOMP-16, EXOCOMP-17, EXOCOMP-75, and EXOCOMP-76. EXOCOMP-16 explicitly decomposed its scope into EXOCOMP-75 (bootstrap/state validation), EXOCOMP-76 (durable token service), and EXOCOMP-77 (supervision/operator/API integration). EXOCOMP-14 is foundational infrastructure and EXOCOMP-17 is the downstream node-side consumer.

Relevant areas: apps/exocomp_coordinator/lib/exocomp/coordinator/application.ex; PKI bootstrap and enrollment-token modules delivered by EXOCOMP-75/76; coordinator config and tests; plans/milestone-2-coordinator.md.

Remaining work/risks: Integrate validated PKI state into startup; add the safe operator initialization entry point and stable outcomes; expose supervised issue/consume contracts without CSR issuance; add end-to-end startup, replay, audit-outage, permission, root-absence, and redaction tests; run fmt-check/build/test/lint. Ensure the implementation checkout contains the completed EXOCOMP-75 and EXOCOMP-76 commits. No code was changed during screening.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 01:34
---
Agent completed successfully in 91s (273335 tokens)
---
author: oompah
created: 2026-07-24 01:34
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 11
- Tokens: 271.3K in / 2.0K out [273.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 31s
- Log: EXOCOMP-77__20260724T013313Z.jsonl
---
author: oompah
created: 2026-07-24 01:34
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 01:34
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 01:34
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-24 01:35
---
Understanding: Security Auditor focus for EXOCOMP-77. I will conduct a thorough security review of the PKI initialization and enrollment operations integration. Key security concerns to audit: (1) secret/key material exposure in logs or output, (2) file permission enforcement for private keys, (3) replay attack prevention in enrollment tokens, (4) audit-log fail-closed behavior, (5) root CA key absence verification online, (6) input validation for enrollment tokens, (7) OWASP Top 10 in coordinator paths, (8) supervision tree startup validation. I will explore the codebase to understand what EXOCOMP-75/76 delivered, then review for vulnerabilities before handing off to the feature agent.
---
author: oompah
created: 2026-07-24 01:42
---
Discovery: Security audit of EXOCOMP-75 (PKI Bootstrap) and EXOCOMP-76 (EnrollmentToken) deliverables complete. The implemented modules have strong security foundations: constant-time digest comparison, sha-256-only storage, ECDSA P-384/P-256 + Ed25519, staged atomic writes, strict file mode enforcement (0700 dir / 0600 files), passphrase-wrapped root key, and lstat-based symlink resistance. Four security gaps require fixes before feature integration:

FINDING 1 (Low): parse_token in enrollment_token.ex validates secret_bytes length (32) but not key_bytes length (16) — inconsistent validation, allows malformed token key components to reach the map lookup.

FINDING 2 (Low): audit.ex @sensitive_keys list is missing 'passphrase' and 'digest' — any future audit event with these fields would not be redacted.

FINDING 3 (Medium): json_lines.ex creates audit log files with default OS permissions (0644) — audit events include node IDs and enrollment patterns that should be owner-readable only (0600). The rotate path has the same issue.

FINDING 4 (Medium): ensure_store_dir in enrollment_token.ex uses File.stat (follows symlinks) instead of File.lstat, and does not verify permissions on already-existing directories — a directory that was previously world-readable would not be flagged.

FINDING 5 (Critical - for feature agent): application.ex starts EnrollmentToken without validating PKI state. No operator Mix task exists for PKI initialization. No integration tests cover clean init + startup, idempotent rerun, PKI failure modes, audit fail-closed, or redaction. These are the core deliverables of EXOCOMP-77.
---
author: oompah
created: 2026-07-24 01:47
---
Implementation: Applied four security fixes to EXOCOMP-75/76 deliverables.

1. enrollment_token.ex — parse_token now validates both key component (16 bytes) AND secret component (32 bytes). Previously only the secret was validated, allowing non-canonical key component lengths.

2. enrollment_token.ex — ensure_store_dir now uses File.lstat (rejects symlinks) and explicitly checks that existing directories have exactly 0o700 permissions. An inherited world-readable token store directory is now a hard error rather than a silent write path.

3. audit/json_lines.ex — audit log files are now set to mode 0600 immediately after creation in both init/1 and rotate/1. The rotate path closes the new file handle on chmod failure to avoid fd leakage.

4. audit.ex — added 'passphrase', 'digest', and 'pin' to @sensitive_keys redaction list; 'root_fingerprint' is explicitly verified to NOT be redacted (it is a public value distributed out-of-band to nodes).

Added 8 new tests: wrong key-length token rejection, extended key-length token rejection, truncated secret rejection, insecure-directory startup behavior (two tests), audit log 0600 on init, audit log 0600 after rotation, redaction of new sensitive-key terms.
---
author: oompah
created: 2026-07-24 01:47
---
Verification: make fmt-check PASSED, make lint PASSED (no warnings), make test: 69/69 coordinator tests pass (up from 61). The 2 pre-existing LlamaServer test failures in exocomp_node are unrelated to this work (require /usr/bin/kill on a process that doesn't exist in the CI environment).
---
author: oompah
created: 2026-07-24 01:47
---
Focus handoff: security

Outcome: Security audit of EXOCOMP-75/76 deliverables is complete. Four vulnerabilities were identified and fixed; all changes are committed, pushed, and covered by 8 new tests (69/69 coordinator tests pass).

Relevant files modified:
- apps/exocomp_coordinator/lib/exocomp/coordinator/enrollment_token.ex (parse_token key-length check, lstat + permission check in ensure_store_dir)
- apps/exocomp_coordinator/lib/exocomp/coordinator/audit/json_lines.ex (0600 file permissions on init and rotate)
- apps/exocomp_coordinator/lib/exocomp/coordinator/audit.ex (passphrase/digest/pin added to @sensitive_keys)
- apps/exocomp_coordinator/test/exocomp/coordinator/enrollment_token_test.exs (8 new security tests)
- apps/exocomp_coordinator/test/exocomp/coordinator/audit_test.exs (permission and redaction tests)

Remaining work (for the feature agent):
1. Extend application.ex supervision tree to validate PKI state via Bootstrap.initialize before starting EnrollmentToken — services must not start from unvalidated state.
2. Create a Mix task (e.g., mix exocomp.coordinator.init) with the stable output and exit-code requirements from the task description (offline backup path, root fingerprint, no private-key printing, distinct initialized/already-initialized/invalid-state outcomes).
3. Wire the EXOCOMP-17 enrollment issue/consume boundary and document it in module contracts.
4. Add integration tests: clean init + startup, idempotent rerun, missing/corrupt/insecure material startup failure, token issue/consume through supervised service, restart replay rejection, audit outage fail-closed, log/output redaction.
5. Assert no root private key is retained online at test time.

Risks: EXOCOMP-77 depends on EXOCOMP-75 and EXOCOMP-76 being merged. The EXOCOMP-75/76 implementations are present in this worktree and fully tested; the dependency is structural/tracking only.

Recommended next focus: feature
---
author: oompah
created: 2026-07-24 01:47
---
Agent completed successfully in 776s (29612 tokens)
---
author: oompah
created: 2026-07-24 01:47
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 98, Tool calls: 71
- Tokens: 70 in / 29.5K out [29.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 12m 56s
- Log: EXOCOMP-77__20260724T013450Z.jsonl
---
author: oompah
created: 2026-07-24 01:47
---
Focus handoff from `security` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 01:47
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 01:47
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-24 01:48
---
Understanding: The prior security focus completed and pushed four hardening fixes. The remaining scope is substantive feature integration (validated-PKI supervision, operator Mix task, enrollment boundary, documentation, and cross-cutting integration tests), which is outside this maintenance-focus phase. I will verify the checkout and existing changes, then provide a chore handoff and route the task to needs:feature without changing code.
---
author: oompah
created: 2026-07-24 01:48
---
Discovery: The worktree is clean and synchronized at commit 867836d (EXOCOMP-77 security hardening), with EXOCOMP-75 and EXOCOMP-76 commits present. application.ex and enrollment_token.ex are the integration points; no operator Mix task is present. make help confirms fmt-check, build, test, and lint are the required project gates. The checkout reports branch epic-EXOCOMP-16 rather than the prompt's stated EXOCOMP-77; this should be preserved and checked by the feature agent before committing further work.
---
author: oompah
created: 2026-07-24 01:48
---
Focus handoff: chore

Outcome: Maintenance triage is complete. No code changes were appropriate in this focus; the remaining work is the core feature implementation already identified by the security handoff.

Evidence: git status is clean and up to date with origin/epic-EXOCOMP-16 at 867836d; EXOCOMP-75/76 and the EXOCOMP-77 security hardening commit are present. make help exposes the required fmt-check/build/test/lint gates. Relevant files are apps/exocomp_coordinator/lib/exocomp/coordinator/application.ex, bootstrap.ex, enrollment_token.ex, coordinator config/tests, and a new Mix task path.

Remaining work/risks: Implement protected-state startup validation, explicit safe initialization with stable outcomes, the supervised/audited issue-consume contract for EXOCOMP-17, module documentation, and all requested integration/security tests. Run all four gates. The actual checkout branch is epic-EXOCOMP-16 despite the task prompt saying EXOCOMP-77, so confirm intended branch handling before the next commit.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 01:49
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 0, Tool calls: 8
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 15s
- Log: EXOCOMP-77__20260724T014800Z.jsonl
---
<!-- COMMENTS:END -->
