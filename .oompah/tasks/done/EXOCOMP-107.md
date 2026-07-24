---
id: EXOCOMP-107
type: task
status: Done
priority: null
title: Implement node-agent enrollment client, credential installer, and renewal scheduler
  (EXOCOMP-17 gap)
parent: null
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
- focus-complete:security
assignee: null
created_at: '2026-07-24T19:29:40.430811Z'
updated_at: '2026-07-24T23:07:59.617792Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: b8cf9847-e28b-4cdf-84a1-ede0133d231d
oompah.task_costs:
  total_input_tokens: 1393782
  total_output_tokens: 107466
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1393782
      output_tokens: 107466
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 799526
    output_tokens: 3354
    cost_usd: 0.0
    recorded_at: '2026-07-24T22:22:04.561964+00:00'
  - profile: standard
    model: unknown
    input_tokens: 594052
    output_tokens: 5950
    cost_usd: 0.0
    recorded_at: '2026-07-24T22:24:46.513364+00:00'
  - profile: standard
    model: unknown
    input_tokens: 204
    output_tokens: 98162
    cost_usd: 0.0
    recorded_at: '2026-07-24T22:57:19.121742+00:00'
---
## Summary

EXOCOMP-17 was marked Done but the node-side enrollment implementation was never delivered. M2-CRIT-3 and M2-CRIT-4 can only verify the coordinator-side path (token issuance, one-time consumption, replay rejection, PKI leaf cert from CSR). The following node-agent components are missing:\n\n- Enrollment client: node calls coordinator enrollment endpoint with node ID and CSR\n- Atomic credential installer: atomically writes received chain PEM + private key\n- Renewal scheduler: monitors cert expiry and triggers renewal before deadline\n\nEnd-to-end enrollment handshake tests (node calling coordinator enrollment endpoint) cannot run until this lands.\n\nSee gap note in apps/exocomp_coordinator/test/integration/m2_acceptance_test.exs moduledoc.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 22:20
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 22:20
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 22:20
---
Understanding: Screening EXOCOMP-107 for duplication before any implementation. I will search existing enrollment, node-agent, credential-installation, renewal, CSR, and EXOCOMP-17 tasks, then inspect the full descriptions/comments of plausible candidates. If no task already owns all of this node-side gap, I will record evidence and hand off to an implementation focus without modifying code.
---
author: oompah
created: 2026-07-24 22:21
---
Discovery: Duplicate screening found no confirmed duplicate. The closest task is EXOCOMP-17, whose stated umbrella scope included node enrollment/renewal, but its full history shows the planner only created/delivered EXOCOMP-87 (coordinator-only CSR validation/leaf issuance) before EXOCOMP-17 was marked Merged. EXOCOMP-20 subsequently verified and documented the exact gap and created EXOCOMP-107 as corrective follow-up. Full histories reviewed for EXOCOMP-17, EXOCOMP-20, EXOCOMP-76, EXOCOMP-77, and EXOCOMP-87: EXOCOMP-76/77 supply coordinator token/PKI boundaries and explicitly exclude node-side enrollment; EXOCOMP-87 contains no HTTP/network/node client code. Tracker-state and source searches found no separate enrollment client, atomic credential installer, or renewal scheduler. Therefore archiving EXOCOMP-107 as duplicate-of:EXOCOMP-17 would leave known missing implementation unowned.
---
author: oompah
created: 2026-07-24 22:21
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed. EXOCOMP-107 is a necessary gap-remediation task and should proceed to feature implementation.

Evidence and decisions: Searched the git-backed tracker branch oompah/state/proj-c260b117 plus plans/docs for enrollment, renewal, CSR, node-agent, credential installation, and scheduler terms. Full tracker histories reviewed: EXOCOMP-17 (intended umbrella but prematurely merged after delivering only child EXOCOMP-87), EXOCOMP-20 (acceptance work that explicitly found and filed this gap), EXOCOMP-76 (coordinator durable token service), EXOCOMP-77 (coordinator PKI/token integration expressly excluding node-side enrollment), and EXOCOMP-87 (pure coordinator CSR/leaf issuer with no HTTP/network code). Current source search under apps/exocomp_node and apps/exocomp_coordinator finds no enrollment client, credential installer, or renewal scheduler. The referenced M2 acceptance file is absent from this branch because EXOCOMP-107 currently tracks origin/main, but EXOCOMP-20's tracker history records that file and its gap note on the integrated epic branch.

Relevant files/areas: plans/milestone-2-coordinator.md; apps/exocomp_node/lib/exocomp/node/ identity/config/application code; coordinator EnrollmentToken and PKI.Issuer contracts from EXOCOMP-76/87; apps/exocomp_coordinator/test/integration/m2_acceptance_test.exs once prerequisite M2 commits are integrated.

Remaining work/risks: Feature implementation must first ensure this branch contains the merged coordinator token/PKI/issuer work, then add the node-local key/CSR enrollment client, crash-safe atomic chain+key installation preserving old valid credentials, expiry-driven authenticated renewal scheduling, coordinator enrollment/renewal HTTP boundaries if still absent, and focused/end-to-end tests. Preserve private-key locality, strict permissions, pinned-root bootstrap, replay rejection, and old-credential fallback on every failure.

Recommended next focus: feature. No repository files were changed; git status is clean.
---
author: oompah
created: 2026-07-24 22:22
---
Agent completed successfully in 104s (802880 tokens)
---
author: oompah
created: 2026-07-24 22:22
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 17
- Tokens: 799.5K in / 3.4K out [802.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 44s
- Log: EXOCOMP-107__20260724T222022Z.jsonl
---
author: oompah
created: 2026-07-24 22:22
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 22:22
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 22:22
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-24 22:22
---
Understanding: Security review will map the node enrollment, credential installation, and renewal trust boundaries against OWASP-style risks: bootstrap authentication/token replay, TLS server verification, CSR/node-ID binding, malicious or malformed certificate responses, private-key exposure, filesystem races/symlink attacks, crash consistency, renewal authentication, retry amplification, and secret logging. I will inspect the current branch and relevant plans/contracts, record actionable security acceptance criteria, and hand off to feature implementation because the node-side components are currently absent.
---
author: oompah
created: 2026-07-24 22:23
---
Discovery: The current branch is origin/main and contains none of the prerequisite coordinator enrollment/PKI modules; those exist only on origin/epic-EXOCOMP-2. That integrated branch exposes EnrollmentToken and PKI.Issuer as internal services but has no HTTP enrollment or renewal route, so a node client currently has no callable boundary. Existing apps/exocomp_node/lib/exocomp/node/identity.ex validates key mode, leaf-to-root path, and DNS SAN, but does not prove the private key matches the leaf certificate, rejects neither symlinks/non-regular key files nor ownership surprises, and reads only one leaf certificate (not a returned intermediate chain). These are security-critical requirements for the new installer rather than evidence that the requested components already exist.
---
author: oompah
created: 2026-07-24 22:23
---
Implementation: Security phase made no repository changes because the enrollment client, installer, scheduler, and server HTTP boundary do not exist on this branch. Defined the required secure design for the feature handoff: local-only key generation; pinned-root plus hostname verification; no redirects or token logging; bounded request/response parsing; coordinator-side token/node/CSR binding; renewal identity derived from mTLS; staged full-chain and leaf/key validation; same-filesystem generation activation with strict ownership/modes and crash-safe rollback; and expiry-based jittered/backoff scheduling that fails closed.
---
author: oompah
created: 2026-07-24 22:23
---
Verification: Static review covered plans/milestone-2-coordinator.md, node Config/Application/Identity and tests, and the coordinator EnrollmentToken/PKI.Issuer/M2 acceptance sources on origin/epic-EXOCOMP-2. git grep confirms no enrollment/renewal network boundary exists. make test could not start because the managed environment's Podman configuration path /run/user/1000/libpod is read-only; no test executed. The worktree remains unchanged.
---
author: oompah
created: 2026-07-24 22:24
---
Focus handoff: security\n\nOutcome: Security review is complete. No code was changed because this branch has no enrollment client, credential installer, renewal scheduler, or coordinator HTTP enrollment/renewal boundary. EXOCOMP-107 must proceed to feature implementation and must first incorporate the coordinator PKI/token work currently present on origin/epic-EXOCOMP-2 but absent from origin/main.\n\nEvidence and decisions: plans/milestone-2-coordinator.md requires one-use node-bound bootstrap tokens, pinned trust, local keys, mTLS renewal, atomic installation, fallback, and fail-closed audit. Static review covered apps/exocomp_node/lib/exocomp/node/{config,application,identity}.ex and the EnrollmentToken/PKI.Issuer/M2 acceptance sources on origin/epic-EXOCOMP-2. There is no HTTP route to call. Existing Identity validates mode, one leaf-to-root path, and SAN, but does not verify leaf/private-key correspondence, a full returned chain, regular-file/ownership constraints, or a pinned root fingerprint.\n\nSecurity acceptance criteria / attack vectors:\n1. Bootstrap authentication: accept the token only in an authorization header or protected body, never URL/query/log/error metadata; impose request/body/PEM/JSON limits and timeouts. Validate inventory membership, token binding, CSR signature/algorithm/extensions/SAN, and audit availability before atomically consuming the one-use token and issuing. Never accept a private key over the API.\n2. Transport / SSRF: require HTTPS, validate coordinator hostname and chain against the configured trust root, independently verify the out-of-band root fingerprint using constant-time comparison, reject insecure TLS versions and all redirects (redirects can exfiltrate tokens), and bound DNS/connect/read timeouts.\n3. Renewal authorization: require verified mTLS; derive node identity from the authenticated peer certificate rather than headers/body; require it to match inventory and CSR SAN. Expired/revoked identities fail closed. Avoid user-controlled identity substitution.\n4. Credential integrity: generate a fresh approved key locally with secure randomness. Before activation, validate response syntax/size, leaf SAN, validity window, KU/EKU/basic constraints, full chain to the pinned root, and that the leaf public key equals the staged private key. Reject extra/unexpected PEM objects.\n5. Filesystem safety: a pair of sequential renames is not atomic. Stage a versioned credential generation on the same filesystem, write with exclusive/random names, key mode 0600 and root/service ownership in a 0700 trusted directory, fsync files and directory, validate while staged, then activate through one atomic generation pointer/manifest and reload only after activation. Defend against symlink/hardlink/path traversal and non-regular targets. Preserve the prior generation until the new listener identity is proven usable; clean abandoned staging safely.\n6. Scheduler / availability: calculate renewal from the validated certificate not server-provided dates; use monotonic timers, bounded jitter, exponential backoff, one in-flight renewal, and retry deadlines that cannot tight-loop or create a fleet thundering herd. Never replace a still-valid credential on any network/parse/validation/write failure. Surface a terminal degraded state before expiry.\n7. Secrets/observability: redact token, CSR, PEM, keys, paths, and HTTP authorization from logs/crash reports/telemetry; audit only node ID, correlation ID, outcome, and safe reason codes. Enrollment and renewal endpoints need rate limiting and uniform invalid-token handling to reduce guessing/oracle and resource-exhaustion attacks.\n8. Tests: cover wrong root/hostname, redirect refusal, replay/wrong-node/expired token, unauthenticated and cross-node renewal, oversized/malformed JSON and PEM, rogue/expired/not-yet-valid/wrong-SAN/wrong-EKU/mismatched-key chains, symlink/permission attacks, failure at every write/fsync/rename/reload point, concurrent renewals, clock shifts, backoff, restart recovery, and confirmation that old credentials remain usable.\n\nOWASP mapping reviewed: broken access control/authentication (bootstrap and renewal identity binding), cryptographic failures (key locality, TLS/pinning, key/cert match), injection/SSRF (URL/redirect and bounded parsing), insecure design/security misconfiguration (atomic generation and permissions), software/data integrity failures (untrusted certificate response), logging/monitoring failures (secret redaction and audit), and denial of service (limits, rate limiting, retry control). No vulnerable-component conclusion is possible until the feature selects an HTTP client/dependencies; use existing pinned dependency policy and audit additions.\n\nRemaining risks: coordinator prerequisite commits are not on this branch; endpoint transaction semantics and credential-generation activation need implementation; the current Identity validator must be extended or replaced so it cannot bless a mismatched key/certificate pair. make test was attempted but Podman could not initialize because /run/user/1000/libpod is read-only.\n\nRecommended next focus: feature.
---
author: oompah
created: 2026-07-24 22:24
---
Agent completed successfully in 150s (600002 tokens)
---
author: oompah
created: 2026-07-24 22:24
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 23
- Tokens: 594.1K in / 6.0K out [600.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 30s
- Log: EXOCOMP-107__20260724T222218Z.jsonl
---
author: oompah
created: 2026-07-24 22:24
---
Focus handoff from `security` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 22:25
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 22:25
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-24 22:25
---
Understanding: Implementing the three missing node-agent components from the EXOCOMP-17 gap: (1) Enrollment client that calls coordinator enrollment endpoint with node ID and CSR, (2) Atomic credential installer that safely writes chain PEM + private key, (3) Renewal scheduler that monitors cert expiry and triggers renewal. Plan: First explore the codebase to understand existing node/coordinator code, then implement the three components with full test coverage following security requirements from previous security review (pinned root, no token logging, atomic staged writes with rollback, mTLS renewal, jittered backoff scheduler).
---
author: oompah
created: 2026-07-24 22:29
---
Discovery: Current branch (EXOCOMP-107) is at origin/main which has coordinator A2A service but NOT the PKI/enrollment modules (those are on origin/epic-EXOCOMP-2). A no-conflict merge of epic-EXOCOMP-2 brings in: EnrollmentToken, PKI.Issuer, PKI.Bootstrap, Audit, Error, Inventory, and full test suite. On the node side, the existing code has: Config, Identity (validates key perms/chain/SAN), Listener, Application, ProposalClient. Missing: (1) Coordinator HTTP enrollment endpoint (coordinator has EnrollmentToken+PKI.Issuer as internal GenServers but no HTTP route), (2) Node enrollment client (generate EC key + CSR, POST to coordinator), (3) Atomic credential installer (staged-rename write with mode 0600 key), (4) Renewal scheduler (expiry monitoring with jittered backoff). Also need to extend node Config with enrollment fields (coordinator_url, enrollment_token path). Plan: merge epic-EXOCOMP-2, add coordinator enrollment HTTP handler, implement 3 node-side modules, write tests.
---
author: oompah
created: 2026-07-24 22:57
---
Agent failed: Reached maximum number of turns (200). Retrying in 10s (attempt #1)
---
author: oompah
created: 2026-07-24 22:57
---
Run #1 [attempt=1, profile=standard, role=standard -> Claude/default]
- Turns: 293, Tool calls: 208
- Tokens: 204 in / 98.2K out [98.4K total]
- Cost: $0.0000
- Exit: error, Duration: 32m 19s
- Log: EXOCOMP-107__20260724T222502Z.jsonl
---
author: oompah
created: 2026-07-24 22:57
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 22:57
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-24 22:57
---
Understanding: Resuming the interrupted software-engineering run. I will audit the current worktree and prior partial implementation, preserve sound changes, finish the node enrollment client, atomic credential installer, and expiry-driven renewal scheduler with focused tests, then run Makefile quality gates, commit, push, and close the task.
---
author: oompah
created: 2026-07-24 22:58
---
Discovery: The worktree is clean except for commit 021ed42, which merged the coordinator PKI/token prerequisite. The node app still has only Config/Identity/Listener and no enrollment, installation, or renewal code. Existing coordinator PKI.Issuer expects a locally generated P-256 CSR with SAN, digitalSignature, clientAuth, and serverAuth extensions and returns leaf+intermediate PEM. I will add a direct x509 dependency, an injectable HTTPS enrollment client, a generation-based atomic installer, and a GenServer renewal scheduler with deterministic timing seams.
---
author: oompah
created: 2026-07-24 23:06
---
Implementation: Added Exocomp.Node.EnrollmentClient, CredentialInstaller, and RenewalScheduler plus direct x509 dependency and focused tests. Enrollment generates a constrained P-256 key/CSR locally, submits only node ID+CSR with a bearer token through an injectable HTTPS transport, verifies pinned CA/hostname with redirects disabled, bounds responses, and rejects a mismatched leaf key. Installation validates key/SAN/chain, writes 0600 material in 0700 versioned generations, fsyncs files, and atomically swaps a current symlink while preserving the old generation. Renewal derives timing from leaf expiry, permits one in-flight renewal, reloads expiry after success, and uses bounded full-jitter exponential retry without replacing credentials on failure.
---
author: oompah
created: 2026-07-24 23:07
---
Verification: Added 11 focused ExUnit tests covering CSR constraints/private-key locality, successful enrollment/install, HTTPS refusal, mismatched key rejection, chain/SAN/mode validation, atomic old-generation fallback, symlink refusal, certificate expiry parsing, threshold scheduling, and bounded retry state. Local formatter check, AST parsing, git diff --check, and in-memory compilation of all three modules against typed dependency stubs pass. The canonical make test/fmt-check/lint/build gates were each attempted but could not start because Podman cannot chmod/read /run/user/1000/libpod in this managed environment; no containerized ExUnit test executed.
---
author: oompah
created: 2026-07-24 23:07
---
Completion: Delivered and pushed commit ed8b906 on origin/EXOCOMP-107. The node now has a local-key enrollment client with constrained CSR and pinned HTTPS transport, a validated generation-based atomic credential installer that preserves prior credentials, and an expiry-driven single-flight renewal scheduler with jittered exponential retry. Added 11 focused tests and updated the M2 acceptance gap note. Branch is clean and exactly synchronized with origin/EXOCOMP-107. Canonical Makefile gates remain environment-blocked before execution by the managed Podman /run/user/1000/libpod read-only error; local format/static checks pass.
---
<!-- COMMENTS:END -->
