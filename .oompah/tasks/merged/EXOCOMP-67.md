---
id: EXOCOMP-67
type: task
status: Merged
priority: 2
title: Inspect and document OTP release runtime dependencies
parent: EXOCOMP-42
children: []
blocked_by:
- EXOCOMP-66
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T21:06:24.819914Z'
updated_at: '2026-07-23T23:37:41.226023Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: e5c2a916-31a5-407f-aeba-838753a38921
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 113
  total_output_tokens: 38438
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 113
      output_tokens: 38438
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 25
    output_tokens: 6275
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:35:05.395763+00:00'
  - profile: standard
    model: unknown
    input_tokens: 88
    output_tokens: 32163
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:46:28.943080+00:00'
---
## Summary

For every node/coordinator amd64/arm64 release produced by EXOCOMP-42, inspect ELF interpreters, shared-library dependencies, NIFs, and bundled ERTS executables using target-architecture tooling in the pinned builders. Fail the build on unresolved or undeclared dynamic dependencies. Define and document the supported glibc Linux runtime baseline and the exact host libraries expected outside each archive, with inspection commands suitable for maintainers and automation. Add fixtures/tests covering a valid release and an injected unresolved or undeclared dependency. Acceptance: dependency reports are attached to artifacts or manifests, docs identify the runtime contract, and focused release/documentation gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:32
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:32
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:34
---
Duplicate screening: No duplicate found. EXOCOMP-67 is a unique child task deliberately created by the EXOCOMP-42 epic planner (see EXOCOMP-42 comment #27).

Key distinctions from closest candidates:
- **EXOCOMP-65** (Done): Pinned multi-arch builder definitions — distinct; covers Docker image selection and arch-select Make targets, not ELF/NIF inspection.
- **EXOCOMP-66** (Done): Deterministic archive packaging and identity manifests — distinct; covers archive normalization and build-identity JSON, not runtime dependency reporting.
- **EXOCOMP-68** (Open): Clean-host qualification, wrong-arch diagnostics, double-build reproducibility — distinct; consumes EXOCOMP-67 artifacts to verify the release starts, but does not produce the dependency inspection tooling or glibc baseline documentation.
- **EXOCOMP-44** (Open): Signed offline bundles, SBOMs, provenance — distinct; covers signing/SBOM generation after artifacts exist, not ELF/NIF inspection.
- **EXOCOMP-42** (parent epic): Mentions 'inspect runtime dynamic dependencies' at the epic level, but EXOCOMP-67 is exactly the child created to fulfill that acceptance criterion.

No other task in the project (reviewed all 70+ tasks across all states) covers ELF interpreter inspection, shared-library dependency enumeration, NIF detection, glibc baseline documentation, build-time failure on unresolved/undeclared dependencies, or the corresponding test fixtures.

EXOCOMP-67 is unique and should proceed to implementation.
---
author: oompah
created: 2026-07-23 21:34
---
Focus handoff: duplicate_detector

1. **Outcome:** No duplicate confirmed. EXOCOMP-67 is a unique, properly-scoped child of EXOCOMP-42, created by the epic planner (EXOCOMP-42 comment #27) to handle ELF/NIF runtime dependency inspection and glibc baseline documentation. All 70+ project tasks reviewed.

2. **Evidence and relevant files/decisions:**
   - `plans/milestone-6-release.md` — confirms the glibc-based Linux (x86_64 and aarch64) supported-target list; M6-CRIT-2 requires releases starting on clean hosts; 'Release qualification verifies that shipped binaries use only documented runtime dependencies'
   - `release/builders.lock` (on origin/EXOCOMP-65 branch) — glibc 2.36 baseline (Debian 12 bookworm), Elixir 1.20.2/OTP 28.5.0.3, separate sha256-pinned amd64 and arm64 builder digests
   - `scripts/build-releases.sh` (EXOCOMP-65 work) — clean-checkout release builds under `_build/release/<arch>/rel/`
   - EXOCOMP-66 (Done) produced four versioned archives and manifests with file inventory and SHA-256; these are the input artifacts EXOCOMP-67 must inspect
   - EXOCOMP-68 (Open, blocked by this task) — qualification test matrix; depends on EXOCOMP-67 dependency reports being in place
   - Work branch for this task is `epic-EXOCOMP-6`

3. **Remaining work and risks:**
   - Add an ELF inspection script that runs `readelf`/`objdump` (cross-arch via target-platform builders) against all ELF binaries in each release archive (ERTS beam.smp, NIFs in priv/, llvm libs etc.)
   - Enumerate all SO_NEEDED entries and identify those expected to be satisfied by the host (outside the archive)
   - Fail build on unresolved or undeclared dynamic dependencies
   - Define and document the glibc ABI baseline (already known: glibc 2.36 from builders.lock)
   - Emit per-archive dependency reports and attach them to manifests or as sidecar files
   - Add docs/runtime-dependencies.md (or similar) identifying the runtime contract with inspection commands
   - Add test fixtures: one valid release + one with an injected unresolved/undeclared dependency
   - Risk: cross-arch inspection (arm64 ELF on amd64 host) requires `aarch64-linux-gnu-readelf` or running inspection inside the arm64 builder container — must use the pinned builder for target-architecture tooling
   - Risk: NIFs in Elixir deps (e.g. telemetry_poller or other native deps) must be enumerated from the release lib/ directory

4. **Recommended next focus:** `devops` — this is a build-pipeline and scripting task (inspection scripts, Makefile targets, report attachment to manifests, CI failure gates). Alternatively `feature` if the implementing agent prefers to frame it as a release infrastructure feature.
---
author: oompah
created: 2026-07-23 21:35
---
Agent completed successfully in 168s (6300 tokens)
---
author: oompah
created: 2026-07-23 21:35
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 52, Tool calls: 33
- Tokens: 25 in / 6.3K out [6.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 48s
- Log: EXOCOMP-67__20260723T213221Z.jsonl
---
author: oompah
created: 2026-07-23 21:35
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:35
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:35
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-07-23 21:37
---
Understanding (DevOps focus): EXOCOMP-67 requires ELF/NIF runtime dependency inspection tooling for amd64/arm64 OTP releases.

Current state:
- Branch: epic-EXOCOMP-42 (the shared epic work branch)
- EXOCOMP-65 work (pinned builders, build-releases.sh, verify-toolchain.sh) is on origin/EXOCOMP-65 but not yet in this branch
- EXOCOMP-66 was closed Done but no code landed — archive packaging scripts do not exist
- This task must work with the EXOCOMP-65 infrastructure as its foundation

Plan:
1. Cherry-pick/merge EXOCOMP-65 work into this branch as foundation
2. Add scripts/inspect-release-deps.sh: ELF interpreter + SO_NEEDED enumeration via readelf (native arch) or cross-arch readelf; detect NIFs in priv/; fail on undeclared host dependencies
3. Add release/runtime-baseline.lock: declarative allowlist of permitted host dependencies (glibc 2.36, libstdc++, libm, libpthread, etc.)
4. Update build-releases.sh to run inspection and attach dep report to build output
5. Add docs/runtime-dependencies.md: glibc baseline, host library contract, inspection commands
6. Add test fixtures: fake release with known-good ELFs + one with injected undeclared dep
7. Add test script scripts/test-runtime-deps.sh covering valid and invalid cases
8. Wire into Makefile (test-deps target) and test-builders gate

Key risk: cross-arch readelf. Strategy: run inside pinned builder container using --platform flag for arm64 inspection on amd64 host.
---
author: oompah
created: 2026-07-23 21:39
---
Discovery: Foundation merged from EXOCOMP-65.

Key files now available:
- release/builders.lock: glibc 2.36 (Debian 12 bookworm), OTP 28.5.0.3/Elixir 1.20.2, sha256-pinned amd64/arm64 digests
- scripts/build-releases.sh: runs inside pinned builder container per arch, outputs to _build/release/<arch>/rel/
- scripts/verify-toolchain.sh: validates Elixir/OTP/glibc inside builder
- scripts/test-release-builders.sh: static validation of builder definitions
- test/fixtures/fake-container-engine.sh: fake docker for test isolation

EXOCOMP-66 produced no code (3 failed agent runs), so archive packaging scripts don't exist. My inspection script will operate on the unpacked release directory (_build/release/<arch>/rel/<release>/) rather than archives.

Implementing:
1. scripts/inspect-release-deps.sh — ELF inspection inside the pinned builder container using native readelf; emits JSON dep report; fails on undeclared host libs
2. release/runtime-baseline.lock — declarative allowlist of permitted host-provided .so files
3. scripts/test-runtime-deps.sh — tests: valid release passes, injected undeclared dep fails
4. test/fixtures/fake-elf/ — minimal ELF test fixtures with controlled NEEDED entries
5. docs/runtime-dependencies.md — runtime contract, glibc baseline, inspection commands
6. Makefile: add inspect-deps and test-deps targets
---
author: oompah
created: 2026-07-23 21:45
---
Implementation complete. Changes:

**New files:**
- scripts/inspect-release-deps.sh: ELF inspection script. Finds all ELF binaries in a release dir, runs readelf -d via pinned builder container (or READELF env override for native use), classifies each NEEDED as bundled/declared host/undeclared, emits dep-report.json, exits 1 on undeclared deps.
- release/runtime-baseline.lock: Declared host-library allowlist (libc.so.6, libm.so.6, libpthread.so.0, libdl.so.2, librt.so.1, libutil.so.1, libgcc_s.so.1, libstdc++.so.6, vdso, ld-linux-{x86-64,aarch64}).
- scripts/test-runtime-deps.sh: 8 test cases covering valid release, undeclared dep rejection, missing ERTS, unsupported arch, missing baseline, dep-report.json production.
- test/fixtures/fake-readelf.sh: Fake readelf reading .readelf-d sidecar files; no real ELF or container needed.
- test/fixtures/fake-release-valid/: ELF fixtures with correct NEEDED entries (all in baseline).
- test/fixtures/fake-release-undeclared/: ELF fixtures with libsomething_undeclared.so.99 injection.
- docs/runtime-dependencies.md: Runtime contract docs with glibc 2.36 baseline table, host library table, dep-report.json schema, inspection commands, and Mermaid build pipeline diagram.

**Modified:**
- scripts/build-releases.sh: Adds inspection loop (exocomp_node, exocomp_coordinator) after smoke check; runs inside pinned builder with READELF=readelf.
- scripts/test-release-builders.sh: Adds validation that baseline file exists, inspect script is executable, test-runtime-deps.sh passes, and docs/runtime-dependencies.md exists with required content.
- Makefile: Adds test-deps, inspect-deps-amd64, inspect-deps-arm64 targets.

All 8 tests pass. make test-builders passes.
---
author: oompah
created: 2026-07-23 21:45
---
Verification: All 8 runtime dependency inspection tests pass.

make test-builders output:
- 8/8 tests passed including:
  * valid amd64/arm64 release accepted
  * release with injected undeclared dep (libsomething_undeclared.so.99) correctly rejected
  * missing ERTS directory rejected with exit code 2
  * unsupported architecture (riscv64) rejected
  * missing baseline file rejected
  * dep-report.json produced on both pass and fail
- static validation: baseline file has libc.so.6 and libm.so.6
- inspection script present and executable
- docs/runtime-dependencies.md present with glibc and inspect-release-deps.sh references

make test-deps: 8/8 pass

Committed on epic-EXOCOMP-42 and pushed to origin.
---
author: oompah
created: 2026-07-23 21:46
---
Completion: EXOCOMP-67 delivered.

Deliverables:
1. scripts/inspect-release-deps.sh — ELF/NIF runtime dependency inspector. Scans all ELF binaries in a release directory, runs readelf -d inside the pinned builder container (target-platform flag ensures arm64-correct inspection on amd64 host), classifies NEEDED entries as bundled/declared-host/undeclared, emits dep-report.json, exits non-zero on undeclared deps.

2. release/runtime-baseline.lock — Authoritative declarative allowlist for glibc 2.36 host library contract (11 SONAMEs).

3. docs/runtime-dependencies.md — Runtime contract documentation: supported targets, glibc 2.36 baseline table, host library table, dep-report.json schema, maintainer inspection commands for amd64 and arm64, READELF=readelf shortcut for native use inside builder, cross-arch dev notes, and Mermaid build pipeline diagram.

4. Test fixtures (test/fixtures/fake-release-valid/, test/fixtures/fake-release-undeclared/, test/fixtures/fake-readelf.sh) — Zero-container, zero-ELF fixture system using .readelf-d sidecar files.

5. scripts/test-runtime-deps.sh — 8-case test script: valid/invalid releases, missing ERTS, unsupported arch, missing baseline, dep-report.json production.

6. Build integration — build-releases.sh runs inspection after smoke-check; test-release-builders.sh gate validates all new components; Makefile adds test-deps, inspect-deps-amd64, inspect-deps-arm64 targets.

Acceptance criteria satisfied:
- Dependency reports (dep-report.json) written to each release dir
- docs/runtime-dependencies.md identifies runtime contract with inspection commands
- make test-builders (focused release/doc gate) passes with 8/8 tests
---
author: oompah
created: 2026-07-23 21:46
---
ELF/NIF dependency inspection tooling, glibc 2.36 runtime baseline, dep-report.json, docs/runtime-dependencies.md, and 8 test fixtures delivered. make test-builders passes. Pushed on epic-EXOCOMP-42.
---
author: oompah
created: 2026-07-23 21:46
---
Agent completed successfully in 666s (32251 tokens)
---
author: oompah
created: 2026-07-23 21:46
---
Run #1 [attempt=1, profile=standard, role=standard -> Claude/default]
- Turns: 158, Tool calls: 111
- Tokens: 88 in / 32.2K out [32.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 11m 6s
- Log: EXOCOMP-67__20260723T213525Z.jsonl
---
<!-- COMMENTS:END -->
