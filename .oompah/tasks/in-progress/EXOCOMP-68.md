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
updated_at: '2026-07-23T21:57:27.197664Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: d3370445-88dd-4a54-bbef-24d5fe69c7b3
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 403291
  total_output_tokens: 8969
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 403291
      output_tokens: 8969
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
<!-- COMMENTS:END -->
