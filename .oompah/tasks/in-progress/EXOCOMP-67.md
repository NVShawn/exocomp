---
id: EXOCOMP-67
type: task
status: In Progress
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
updated_at: '2026-07-23T21:37:44.891231Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: e5c2a916-31a5-407f-aeba-838753a38921
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 25
  total_output_tokens: 6275
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 25
      output_tokens: 6275
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 25
    output_tokens: 6275
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:35:05.395763+00:00'
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
<!-- COMMENTS:END -->
