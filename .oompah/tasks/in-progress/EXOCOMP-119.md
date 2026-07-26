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
assignee: null
created_at: '2026-07-26T03:58:31.966643Z'
updated_at: '2026-07-26T04:31:57.405894Z'
work_branch: epic-EXOCOMP-117
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 597429dd-5b2c-44ec-98c4-09d3de006c56
oompah.work_branch: epic-EXOCOMP-117
oompah.task_costs:
  total_input_tokens: 1610713
  total_output_tokens: 6197
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1610713
      output_tokens: 6197
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 1610713
    output_tokens: 6197
    cost_usd: 0.0
    recorded_at: '2026-07-26T04:10:57.855997+00:00'
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
<!-- COMMENTS:END -->
