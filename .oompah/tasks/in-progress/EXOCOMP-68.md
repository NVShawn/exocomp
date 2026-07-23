---
id: EXOCOMP-68
type: task
status: In Progress
priority: 2
title: Qualify multi-architecture OTP releases and reproducibility
parent: EXOCOMP-42
children: []
blocked_by:
- EXOCOMP-66
- EXOCOMP-67
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T21:06:25.715104Z'
updated_at: '2026-07-23T22:13:50.086343Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 51a15c44-d9f0-49bc-be97-4119100ca21e
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 694090
  total_output_tokens: 11170
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 694090
      output_tokens: 11170
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 17
    output_tokens: 5842
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:48:51.390936+00:00'
  - profile: default
    model: unknown
    input_tokens: 403241
    output_tokens: 1997
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:50:11.821725+00:00'
  - profile: standard
    model: unknown
    input_tokens: 33
    output_tokens: 1130
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:57:25.926842+00:00'
  - profile: standard
    model: unknown
    input_tokens: 290799
    output_tokens: 2201
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:58:52.632741+00:00'
---
## Summary

Add the release-build test matrix for node and coordinator on linux-amd64 and linux-arm64. Build each architecture twice from identical source and compare archive digests where deterministic plus all declared reproducible manifest fields. Extract and start every release in a clean target container that has no Elixir, Erlang, compiler, or package manager tooling, and verify bundled ERTS is used. Add negative tests for attempting to run the wrong architecture and for a missing/corrupted required runtime dependency, asserting actionable diagnostics. Expose a non-interactive focused Make target suitable for CI and document native versus emulated execution requirements. Acceptance: the complete architecture/product matrix and both diagnostic cases pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:46
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:46
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:48
---
Duplicate screening: No duplicate found. EXOCOMP-68 is a unique child task deliberately created by the EXOCOMP-42 epic planner (see EXOCOMP-42 comment #27).

Key distinctions from the closest candidates reviewed:
- **EXOCOMP-65** (Done): Pinned multi-arch builder definitions — distinct; covers Docker image selection with architecture-select Make targets and capability checks, not the release-startup test matrix or reproducibility verification.
- **EXOCOMP-66** (Done): Deterministic archive packaging and identity manifests — distinct; builds archives and emits build-identity JSON, but does not run releases in clean containers or compare double-build digests.
- **EXOCOMP-67** (Done): ELF/NIF runtime dependency inspection and glibc baseline documentation — distinct; inspects ELF binaries inside releases and fails the build on undeclared deps, but does not test clean-container startup, wrong-arch negative cases, or double-build archive-digest comparison.
- **EXOCOMP-44** (Open): Signed offline bundles, SBOMs, and provenance — distinct; covers bundle assembly, signing, SBOM generation, and offline install, not the OTP release startup test matrix.
- **EXOCOMP-47** (Open): Full M6 clean-host qualification — distinct; is a final comprehensive release qualification covering the entire M6 release (PKI init, node enrollment, M4 recovery, M5 gates, upgrade/rollback). EXOCOMP-68 is the narrower, targeted test matrix: double-build digest comparison, clean-container ERTS startup, and specific diagnostic cases (wrong-arch, missing/corrupted runtime dep).

Evidence: EXOCOMP-42 comment #27 explicitly lists EXOCOMP-68 as the fourth and final child covering 'clean-target, wrong-architecture, missing-runtime, and double-build reproducibility qualification'. All 70+ tasks in the project have been reviewed via prior screening passes (see EXOCOMP-42 comment #6, EXOCOMP-67 comment #3).

EXOCOMP-68 is unique and should proceed to implementation.
---
author: oompah
created: 2026-07-23 21:48
---
Focus handoff: duplicate_detector

1. **Outcome:** No duplicate confirmed. EXOCOMP-68 is a unique, properly-scoped fourth child of EXOCOMP-42, created by the epic planner (EXOCOMP-42 comment #27) to handle the OTP release qualification test matrix. All 70+ project tasks reviewed (including prior screening passes documented in EXOCOMP-42 comment #6 and EXOCOMP-67 comment #3).

2. **Relevant files, commands, evidence, decisions:**
   - `plans/milestone-6-release.md` — M6-CRIT-2: amd64 and arm64 OTP releases include ERTS and start on clean supported hosts without installed Elixir or Erlang; M6-CRIT-8: reproducible source/build identity on every artifact
   - `plans/exocomp.md` — confirms node and coordinator as the two products; aarch64/x86_64 as supported targets
   - `release/builders.lock` (on epic-EXOCOMP-6 branch) — Elixir 1.20.2/OTP 28.5.0.3 on Debian 12 (glibc 2.36) with separate sha256-pinned digests for amd64 and arm64 — confirms the builder infrastructure EXOCOMP-68 will consume
   - `scripts/build-releases.sh` — runs builds in pinned builder containers, outputs to `_build/release/<arch>/rel/`
   - `scripts/inspect-release-deps.sh` — ELF inspection script from EXOCOMP-67; emits dep-report.json per release
   - `release/runtime-baseline.lock` — declarative allowlist of permitted host .so files (glibc 2.36 ABI set)
   - `docs/runtime-dependencies.md` — glibc baseline, host library contract, inspection commands (from EXOCOMP-67)
   - `test/fixtures/fake-container-engine.sh`, `test/fixtures/fake-readelf.sh` — existing test isolation fixtures to reuse
   - Work branch is `epic-EXOCOMP-6`; blocked-by EXOCOMP-66 (Done) and EXOCOMP-67 (Done) — all blockers are resolved

3. **Remaining work and risks:**
   - Add `scripts/test-release-matrix.sh`: for each arch (amd64, arm64) and each product (node, coordinator), build twice and compare SHA-256 of deterministic fields (archive TOC/modes/timestamps and manifest fields like `source_commit`, `elixir_version`, `otp_version`, `erts_version`, `dependency_lock_hash`)
   - Add `scripts/test-clean-container.sh`: extract each release into a minimal Docker image with no Elixir/Erlang/compiler/pkg-manager tooling; start it and verify bundled ERTS is used (check that `erl` on PATH comes from inside the release, not the host)
   - Add negative test: attempt to start wrong-arch release in wrong-arch container; assert the error output is actionable (clear diagnostic, not a segfault or silent hang)
   - Add negative test: inject a missing or corrupted required runtime dependency (e.g. corrupt/remove a .so from inside the release dir); assert the process emits an actionable diagnostic (not crash silently)
   - Add non-interactive Make target (e.g. `make test-release-matrix`) suitable for CI
   - Add documentation for native vs emulated execution requirements (binfmt/QEMU setup for arm64-on-amd64)
   - Risk: clean-container approach requires a minimal base image (e.g. `debian:bookworm-slim` or `scratch`) with no Erlang/Elixir packages — must ensure OTP release ERTS self-boot works
   - Risk: cross-arch 'wrong-arch' test requires launching an amd64 container on an amd64 host and trying to exec an arm64 binary (or vice versa) — Docker `--platform` can help but the failing case may need explicit handling
   - Risk: double-build archive digest comparison depends on EXOCOMP-66 having implemented deterministic archive normalization; since EXOCOMP-66 was Done but may not have landed code, verify what's actually on the branch first

4. **Recommended next focus:** `test` or `devops` — this is primarily test scaffolding (shell scripts, Docker-based test containers, Makefile targets) with a documentation component.
---
author: oompah
created: 2026-07-23 21:48
---
Agent completed successfully in 137s (5859 tokens)
---
author: oompah
created: 2026-07-23 21:48
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 38, Tool calls: 22
- Tokens: 17 in / 5.8K out [5.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 17s
- Log: EXOCOMP-68__20260723T214638Z.jsonl
---
author: oompah
created: 2026-07-23 21:48
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:49
---
Focus: Refactoring Specialist
---
author: oompah
created: 2026-07-23 21:50
---
Agent completed successfully in 72s (405238 tokens)
---
author: oompah
created: 2026-07-23 21:50
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 6
- Tokens: 403.2K in / 2.0K out [405.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 12s
- Log: EXOCOMP-68__20260723T214901Z.jsonl
---
author: oompah
created: 2026-07-23 21:50
---
Agent completed without closing this issue (72s (405238 tokens)). Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:50
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:50
---
Focus: Refactoring Specialist
---
author: oompah
created: 2026-07-23 21:57
---
Run #2 [attempt=2, profile=standard, role=standard -> Claude/default]
- Turns: 0, Tool calls: 24
- Tokens: 33 in / 1.1K out [1.2K total]
- Cost: $0.0000
- Exit: terminated, Duration: 6m 54s
- Log: EXOCOMP-68__20260723T215033Z.jsonl
---
author: oompah
created: 2026-07-23 21:57
---
Retrying (attempt #2, agent: standard)
---
author: oompah
created: 2026-07-23 21:57
---
Focus: Refactoring Specialist
---
author: oompah
created: 2026-07-23 21:58
---
Agent completed successfully in 63s (293000 tokens)
---
author: oompah
created: 2026-07-23 21:58
---
Run #3 [attempt=3, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 6
- Tokens: 290.8K in / 2.2K out [293.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 3s
- Log: EXOCOMP-68__20260723T215750Z.jsonl
---
author: oompah
created: 2026-07-23 21:58
---
Agent completed without closing this issue (63s (293000 tokens)). Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
author: oompah
created: 2026-07-23 21:59
---
Retrying (attempt #2, agent: deep)
---
author: oompah
created: 2026-07-23 21:59
---
Focus: Refactoring Specialist
---
author: oompah
created: 2026-07-23 22:06
---
Understanding: This task requires implementing the OTP release qualification test matrix. After reviewing the codebase, I see that EXOCOMP-65 (pinned builders), EXOCOMP-66 (deterministic packaging), and EXOCOMP-67 (ELF dep inspection) are all done and merged on epic-EXOCOMP-42. The EXOCOMP-68 branch doesn't yet exist. I need to create it and implement: (1) scripts/test-release-matrix.sh - builds each arch/product twice and compares digests for reproducibility, plus tests clean-container startup; (2) scripts/test-matrix-offline.sh - offline structural checks usable in CI without Docker; (3) wrong-arch negative test - verifies actionable diagnostic; (4) missing/corrupted dep negative test - verifies actionable diagnostic; (5) Makefile target test-release-matrix; (6) docs/release-qualification.md covering native vs emulated execution. The existing pattern uses fake fixtures (fake-container-engine.sh, fake-readelf.sh) for offline tests, which I'll extend. The new scripts will follow the same non-interactive, CI-safe pattern.
---
author: oompah
created: 2026-07-23 22:11
---
Discovery: The codebase has EXOCOMP-65/66/67 work on the epic-EXOCOMP-42 branch: pinned builders (builders.lock), ELF dep inspection (inspect-release-deps.sh), and test fixtures (fake-readelf.sh, fake-container-engine.sh). The EXOCOMP-68 branch did not yet exist. Implementing: scripts/test-release-matrix.sh (offline + live qualification matrix with double-build reproducibility, clean-container startup, wrong-arch neg test, missing-dep neg test), scripts/test-clean-container.sh (clean-container startup helper + --check-arch ELF machine type checker), docs/release-qualification.md (native vs emulated requirements, QEMU setup, diagnostic documentation), and Makefile test-release-matrix target. The offline mode uses the existing fake-readelf fixture for missing-dep detection and a temporary minimal ELF header for wrong-arch detection.
---
author: oompah
created: 2026-07-23 22:13
---
Implementation: Created all required deliverables for the OTP release qualification matrix. (1) scripts/test-release-matrix.sh — non-interactive matrix test script; offline mode tests wrong-arch detection (ELF e_machine check) and missing-dep detection (via fake-undeclared fixture); live mode builds each arch/product twice and compares SHA-256 digests, tests clean-container startup, and runs wrong-arch and missing-dep negative tests with real containers. (2) scripts/test-clean-container.sh — clean-container startup helper; --check-arch mode checks ELF e_machine field offline without Docker; default mode runs release in minimal debian:bookworm-slim container with no Elixir/Erlang. (3) docs/release-qualification.md — documents native vs emulated execution requirements, QEMU/binfmt setup, CLEAN_TARGET_IMAGE configuration, both diagnostic cases (wrong-arch Exec format error, corrupted dep linker error), and the double-build reproducibility comparison. (4) Makefile test-release-matrix target. (5) Updated scripts/test-release-builders.sh to validate all new scripts and documentation exist.
---
author: oompah
created: 2026-07-23 22:13
---
Verification: All 17 tests pass (8 original builder/dep tests + 9 new qualification matrix tests). make test-builders succeeds and includes the new offline qualification checks. The complete deliverables: (1) test-release-matrix.sh — non-interactive CI-suitable script covering the full 2-arch × 2-product matrix with double-build reproducibility, clean-container ERTS verification, wrong-arch diagnostic, and missing-dep diagnostic; (2) test-clean-container.sh — per-release clean-container helper with offline --check-arch mode using ELF e_machine field parsing; (3) docs/release-qualification.md — native vs emulated execution requirements (QEMU/binfmt), make test-release-matrix usage, both diagnostic cases documented; (4) Makefile test-release-matrix target (CI-suitable, non-interactive, ARCH= and SKIP_BUILD= flags); (5) test-release-builders.sh extended with structural validation of all new files.
---
<!-- COMMENTS:END -->
