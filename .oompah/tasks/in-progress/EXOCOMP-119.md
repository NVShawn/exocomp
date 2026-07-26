---
id: EXOCOMP-119
type: feature
status: In Progress
priority: 1
title: Start production coordinator PKI and enrollment services
parent: EXOCOMP-117
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
- focus-complete:docs
assignee: null
created_at: '2026-07-26T03:58:31.966643Z'
updated_at: '2026-07-26T04:39:35.323091Z'
work_branch: epic-EXOCOMP-117
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: a74b3314-e256-4c6b-9609-0d7d78ef8764
oompah.work_branch: epic-EXOCOMP-117
oompah.task_costs:
  total_input_tokens: 4403172
  total_output_tokens: 22398
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 4403172
      output_tokens: 22398
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 1610713
    output_tokens: 6197
    cost_usd: 0.0
    recorded_at: '2026-07-26T04:10:57.855997+00:00'
  - profile: standard
    model: unknown
    input_tokens: 2792420
    output_tokens: 14959
    cost_usd: 0.0
    recorded_at: '2026-07-26T04:33:05.816293+00:00'
  - profile: standard
    model: unknown
    input_tokens: 39
    output_tokens: 1242
    cost_usd: 0.0
    recorded_at: '2026-07-26T04:38:45.245791+00:00'
---
## Summary

Context
The v0.1.0-rc.2 production coordinator reports healthy while its listener, PKI state, and enrollment processes are nil. Domain modules and fixture-only integration tests exist, but the shipped service cannot perform token issuance, node enrollment, or renewal.

Implementation
Wire the production coordinator supervision tree and runtime configuration to initialize protected PKI state, start the authenticated listener and enrollment token service, expose the supported enrollment and renewal flow, and fail health when required components are absent. Use installer-created paths and least-privilege ownership. Do not expose secrets in logs or command history. Relevant areas include apps/exocomp_coordinator, production config, systemd and installer assets, and PKI/enrollment operator docs.

Testing
Add release-mode integration coverage that starts coordinator and node from installed artifacts, initializes PKI, issues a short-lived node-bound token, enrolls a node, rejects replay and wrong identity, renews over mTLS, restarts both services, and proves durable state recovery. Run make test, make test-installer, make test-bundle, and the clean-host live scenario.

Acceptance Criteria
- Production startup has live listener, PKI, token, and enrollment components.
- A clean installed node enrolls and renews against the installed coordinator.
- Token replay, identity mismatch, bad trust root, and missing audit fail closed.
- Service health reflects missing required components.
- Focused tests and relevant Make gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-26 04:07
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-26 04:07
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-26 04:07
---
Understanding: Duplicate-detector pass only. I will search existing tasks and project decisions for production coordinator PKI, enrollment, renewal, listener, and health work; inspect the full records of credible candidates; then either archive this issue as a confirmed duplicate or record a no-duplicate handoff for an implementation agent.
---
author: oompah
created: 2026-07-26 04:10
---
Discovery: No confirmed duplicate. Full records reviewed for EXOCOMP-17, EXOCOMP-19, EXOCOMP-20, EXOCOMP-60, EXOCOMP-77, EXOCOMP-107, EXOCOMP-117, and EXOCOMP-123. EXOCOMP-77 starts validated PKI/token services only through a test-oriented isolated tree and explicitly excludes certificate issuance/node enrollment; EXOCOMP-107 supplies node-side client/install/scheduling; EXOCOMP-19 supplies the coordinator listener/A2A modules; EXOCOMP-20 verifies internal/fixture paths; EXOCOMP-123 is later release requalification. Current production Application.start/2 omits Listener, PKI.State, and EnrollmentToken while Health.check/0 only considers inventory/registry/audit, directly confirming EXOCOMP-119 owns the remaining shipped-runtime integration rather than repeating a prior task.
---
author: oompah
created: 2026-07-26 04:10
---
Verification: Duplicate screen completed read-only. Repository/task-history searches and full candidate task views show no task that owns production wiring plus installed-artifact enrollment/renewal recovery. Source inspection confirms the reported gap in Application.start/2 and Health.check/0. No files were changed and no tests were run because this focus forbids implementation. The worktree already contains unrelated modifications in config/config.exs, both systemd units, and scripts/install.sh; they were preserved untouched.
---
author: oompah
created: 2026-07-26 04:10
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no duplicate; EXOCOMP-119 should proceed to implementation.

Evidence/decisions: Reviewed full histories for EXOCOMP-17/19/20/60/77/107/117/123 and searched plans/docs/source for coordinator PKI, listener, enrollment, renewal, replay, health, and release qualification. The closest completed work is split across EXOCOMP-77 (validated PKI and durable token domain services), EXOCOMP-19 (coordinator listener/A2A surface), and EXOCOMP-107 (node enrollment client, credential installer, renewal scheduler). None wires those pieces into the shipped production services or proves an installed-artifact end-to-end flow. apps/exocomp_coordinator/lib/exocomp/coordinator/application.ex starts only the general M2 tree in start/2; PKI.State and EnrollmentToken occur only in start_supervised_tree/1, documented as integration-test-oriented, and Listener is absent. apps/exocomp_coordinator/lib/exocomp/coordinator/health.ex checks only Inventory, Registry, and Audit. apps/exocomp_coordinator/test/integration/m2_acceptance_test.exs calls domain services directly. docs/release-evidence/v0.1.0-rc.2/README.md records this exact production failure.

Relevant files: coordinator application/listener/health/config and enrollment router/API; config/config.exs; release coordinator/node systemd units; scripts/install.sh; release templates; docs/pki-operations.md, docs/installation.md, docs/clean-host-qualification.md; installer/bundle/live integration tests. Preserve the existing unrelated dirty changes in config/config.exs, release/coordinator/exocomp-coordinator.service, release/node/exocomp-node.service, and scripts/install.sh.

Remaining work/risks: Compose validated PKI, token, issuer, authenticated enrollment/renewal endpoints, and listener under production supervision; wire node enrollment/renewal into installed runtime; require audit and all mandatory components in health; align installer ownership/paths; add release-mode replay/identity/root/audit/restart durability coverage; run the required Make and clean-host gates. The main risk is correctly composing prior modules without weakening fail-closed behavior or exposing tokens/passphrases.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-26 04:11
---
Agent completed successfully in 202s (1616910 tokens)
---
author: oompah
created: 2026-07-26 04:11
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 28
- Tokens: 1.6M in / 6.2K out [1.6M total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 22s
- Log: EXOCOMP-119__20260726T040739Z.jsonl
---
author: oompah
created: 2026-07-26 04:11
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-26 04:25
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-26 04:25
---
Focus: Technical Writer
---
author: oompah
created: 2026-07-26 04:26
---
Understanding: Documentation-focus pass only. I will verify the existing coordinator PKI, enrollment, renewal, installer-path, and clean-host interfaces against source; update concise operator documentation only where examples can be proven accurate; run the relevant documentation checks; then leave a docs handoff identifying implementation-dependent gaps for the feature specialist.
---
author: oompah
created: 2026-07-26 04:29
---
Discovery: The docs/source comparison found three stable operator issues: the first coordinator install example starts the service before its PKI ceremony; docs/pki-operations.md uses a source-checkout backup path instead of the installed exocomp-state-backup utility; and no single safe readiness command proves Listener, PKI.State, EnrollmentToken, and health together. Bootstrap also atomically creates final online/offline directories, so pre-creating empty targets is an operator-visible failure mode worth documenting. The production enrollment/token endpoint remains absent and cannot yet be documented accurately.
---
author: oompah
created: 2026-07-26 04:29
---
Implementation (docs): Updated docs/installation.md to stage first coordinator installs with --no-start; expanded docs/pki-operations.md with installer-created state-parent guidance, atomic-target precautions, a redacted PKI initialization result, protected-cookie readiness inspection, installed backup/restore commands, and mandatory degraded health semantics; expanded docs/clean-host-qualification.md with the no-secret enrollment/replay/identity/trust-root/audit/restart evidence sequence. No runtime behavior or source code was changed.
---
author: oompah
created: 2026-07-26 04:31
---
Verification (docs): PASS: python3 tests/test_operator_docs.py (6 tests), make check-links, git diff --check, and Elixir syntax parsing for both embedded release-eval/RPC expressions. make test reached and passed the release-builder/offline checks, package tests, release-input normalizer tests, and operator-doc tests, then could not launch the pinned Elixir builder because the host's docker/podman shim cannot chmod /run/user/1000/libpod on this read-only environment. Direct host Mix checks are unavailable because the host has Elixir 1.18.3 while the project requires 1.20.2; this is an environment limitation, not a documentation failure.
---
author: oompah
created: 2026-07-26 04:32
---
Focus handoff: docs

Outcome: Completed and pushed the documentation phase in commit 6af78a7. First coordinator installation now stages with --no-start; the PKI ceremony uses a service-owned temporary passphrase file and redacted output; readiness checks Listener, PKI.State, EnrollmentToken, and Health together; backup examples use the installed utility; clean-host evidence now covers replay, identity mismatch, bad root, missing audit, mTLS renewal, and restart durability without recording tokens.

Evidence/decisions: Changed docs/installation.md, docs/pki-operations.md, and docs/clean-host-qualification.md. PASS: tests/test_operator_docs.py (6), make check-links, git diff --check, and Elixir syntax parsing of embedded eval/RPC expressions. make test passed all pre-container checks but the pinned builder could not start because the host docker/podman shim cannot chmod the read-only /run/user/1000/libpod. Branch is pushed at 6af78a7.

Remaining work/risks: Production behavior is still absent. Application.start/2 must supervise Listener, PKI.State, EnrollmentToken, enrollment/renewal handlers, and node runtime clients; Health.check/0 must fail degraded for every required component. Bootstrap filenames/state location currently disagree with release/templates/coordinator.json, and start_supervised_tree/1 requires the offline root and passphrase on every validation while the operator security contract unmounts the offline root after the ceremony. Resolve that boundary without keeping root material online. A2ARouter globally requires mTLS and has no bootstrap enrollment route; EnrollmentClient expects an HTTPS enrollment response, and renewal needs a distinct authenticated mTLS path. Once the supported token issuance/enrollment interface lands, replace the current installation-guide warning that no standalone issuance command exists with the exact verified operator command. Required release-mode tests and make test/test-installer/test-bundle/clean-host gates remain.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-26 04:33
---
Agent completed successfully in 430s (2807379 tokens)
---
author: oompah
created: 2026-07-26 04:33
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 78
- Tokens: 2.8M in / 15.0K out [2.8M total]
- Cost: $0.0000
- Exit: normal, Duration: 7m 10s
- Log: EXOCOMP-119__20260726T042557Z.jsonl
---
author: oompah
created: 2026-07-26 04:33
---
Focus handoff from `docs` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-26 04:33
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-26 04:33
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-26 04:33
---
Understanding: I am the Software Engineer focus for EXOCOMP-119. Based on previous focus handoffs, the gap is clear: apps/exocomp_coordinator/lib/exocomp/coordinator/application.ex starts only the general M2 supervision tree (no Listener, PKI.State, EnrollmentToken); health.ex only checks Inventory/Registry/Audit; enrollment/renewal endpoints are missing from the production A2A router. My plan: (1) read all relevant source files to understand current module APIs; (2) wire PKI.State, EnrollmentToken, Listener, and enrollment/renewal handlers into Application.start/2 production tree; (3) update Health.check/0 to require all live components; (4) add release-mode integration tests; (5) run make test and available gates; (6) commit and push.
---
author: oompah
created: 2026-07-26 04:38
---
Run #1 [attempt=1, profile=standard, role=standard -> Claude/default]
- Turns: 0, Tool calls: 26
- Tokens: 39 in / 1.2K out [1.3K total]
- Cost: $0.0000
- Exit: terminated, Duration: 5m 31s
- Log: EXOCOMP-119__20260726T043317Z.jsonl
---
author: oompah
created: 2026-07-26 04:39
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-26 04:39
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-26 04:39
---
Understanding: I am the Software Engineer focus for EXOCOMP-119. The previous focus handoffs confirm the gap: apps/exocomp_coordinator/lib/exocomp/coordinator/application.ex starts only the general M2 supervision tree with no Listener, PKI.State, or EnrollmentToken; health.ex only checks Inventory/Registry/Audit; enrollment/renewal endpoints are absent from the production A2A router. My plan: (1) read all relevant source files to understand current module APIs; (2) wire PKI.State, EnrollmentToken, Listener, and enrollment/renewal handlers into Application.start/2 production tree; (3) update Health.check/0 to require all live components; (4) add release-mode integration tests; (5) run make test and available gates; (6) commit and push.
---
<!-- COMMENTS:END -->
