---
id: EXOCOMP-44
type: chore
status: Merged
priority: 2
title: Assemble signed offline bundles, SBOMs, and provenance
parent: EXOCOMP-6
children: []
blocked_by:
- EXOCOMP-40
- EXOCOMP-42
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:12:03.621738Z'
updated_at: '2026-07-23T23:44:46.631358Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 49f3ddf7-15bb-4d41-bb7c-552f65366798
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 642905
  total_output_tokens: 7187
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 642905
      output_tokens: 7187
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 642797
    output_tokens: 3379
    cost_usd: 0.0
    recorded_at: '2026-07-23T23:32:50.547161+00:00'
  - profile: quick
    model: unknown
    input_tokens: 108
    output_tokens: 3808
    cost_usd: 0.0
    recorded_at: '2026-07-23T23:44:45.361268+00:00'
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Assemble signed offline bundles, SBOMs, and provenance.

Implementation
Bundle architecture-matched OTP releases, llama-server, verified Qwen GGUF model, systemd/install assets, licenses, manifests, SHA-256 checksums, signatures, SBOM, and provenance; also define optional runtime-only bundle; pin every nested artifact.

Testing
Build and verify with network disabled; tamper with nested files to test failure; validate signatures/SBOM/provenance references; install on both target architectures.

Acceptance Criteria
- [ ] Complete bundles install fully offline.
- [ ] Every nested file is covered by manifest/checksum and relevant license.
- [ ] Tampering fails before installation.
- [ ] SBOM and provenance identify source, builder, toolchain, and dependencies.
- [ ] Both architectures pass.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 23:31
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 23:31
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 23:31
---
Understanding: This run is duplicate screening only. I will compare EXOCOMP-44's offline-bundle/SBOM/provenance scope against existing task records and Milestone 6 planning, inspect plausible candidates in full, then archive only if the same underlying deliverable is already tracked; otherwise I will hand off for implementation.
---
author: oompah
created: 2026-07-23 23:32
---
Discovery: No duplicate is evident. The closest tasks have explicit non-overlapping boundaries: EXOCOMP-41 supplies license/governance inputs; EXOCOMP-42/66 build deterministic OTP archives and reserve signing, SBOMs, and bundle assembly for EXOCOMP-44; EXOCOMP-43 supplies installer/systemd assets; EXOCOMP-68 qualifies OTP archives only; EXOCOMP-47 is downstream full-release clean-host qualification. Milestone 6 independently assigns complete/runtime-only bundle composition and supply-chain metadata to M6-CRIT-3 and M6-CRIT-8.
---
author: oompah
created: 2026-07-23 23:32
---
Focus handoff: duplicate_detector

1. Outcome: Duplicate screening found no duplicate; EXOCOMP-44 is the unique M6 task for signed complete/runtime-only offline bundles, nested integrity coverage, SBOMs, and provenance.
2. Evidence/decisions: Searched the tracker state for offline bundle, SBOM, provenance, llama-server, GGUF, and runtime-only terms; reviewed EXOCOMP-6, 41, 42, 43, 47, 66, and 68 in full. plans/milestone-6-release.md sections Artifact Architecture and Supply Chain map this scope to M6-CRIT-3 and M6-CRIT-8. EXOCOMP-66 explicitly says signing, SBOM generation, and offline-bundle assembly remain in EXOCOMP-44.
3. Remaining work/risks: Assemble amd64/arm64 complete bundles and optional runtime-only variants from the pinned OTP, llama-server, verified model, installer/systemd, notice/license, and manifest inputs; cover every nested file; verify before mutation; add signatures, SBOM, provenance, network-disabled and tamper tests. Confirm the actual merged availability/pins of all EXOCOMP-40/42/43 inputs before building.
4. Recommended next focus: devops, for reproducible supply-chain packaging/signing and offline architecture-matrix verification. No repository files were changed and implementation/test gates are not applicable to this screening-only run.
---
author: oompah
created: 2026-07-23 23:32
---
Agent completed successfully in 108s (646176 tokens)
---
author: oompah
created: 2026-07-23 23:32
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 19
- Tokens: 642.8K in / 3.4K out [646.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 48s
- Log: EXOCOMP-44__20260723T233105Z.jsonl
---
author: oompah
created: 2026-07-23 23:32
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 23:32
---
Agent dispatched (profile: quick)
---
author: oompah
created: 2026-07-23 23:32
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-07-23 23:33
---
Understanding: DevOps focus for EXOCOMP-44 - Assemble signed offline bundles, SBOMs, and provenance.

Plan:
1. Explore existing codebase structure - especially release/, scripts/, plans/milestone-6-release.md
2. Understand what EXOCOMP-40 (llama-server/model) and EXOCOMP-42 (OTP deterministic builds) have produced
3. Implement bundle assembly scripts for amd64/arm64 complete and runtime-only variants
4. Add SHA-256 manifest generation covering every nested file
5. Add SBOM generation (CycloneDX or SPDX format)
6. Add provenance metadata (SLSA-style: source, builder, toolchain, deps)
7. Add GPG/minisign signature step
8. Write tamper-detection verification scripts
9. Add Makefile targets and focused tests
10. Verify network-disabled install path

Key inputs from upstream tasks: OTP archives (EXOCOMP-42/66), llama-server binary (EXOCOMP-40), Qwen GGUF model, systemd/install assets (EXOCOMP-43), licenses (EXOCOMP-41).
---
author: oompah
created: 2026-07-23 23:35
---
Discovery: Explored full codebase and upstream branch outputs.

Key findings:
- Current HEAD is epic-EXOCOMP-6 (main branch). EXOCOMP-44 branch created fresh from here.
- EXOCOMP-41 branch: provides licenses/components.toml and scripts/check_compliance.py (governance gate)
- EXOCOMP-42 branch: provides release/builders.lock (pinned digests), scripts/build-releases.sh, release/runtime-baseline.lock. OTP releases built to _build/release/{arch}/rel/{release}.
- EXOCOMP-43 (merged to main): scripts/install.sh, scripts/uninstall.sh, release/{node,coordinator}/*.service, release/templates/*.json
- No bundle assembly, SBOM, provenance, or signature tooling exists yet.

Implementation plan:
1. scripts/assemble-bundle.sh — assembles complete and runtime-only bundles from OTP archives, llama-server binary, GGUF model, systemd/install assets, licenses, manifest; parameterized by arch and bundle-kind
2. scripts/verify-bundle.sh — verifies SHA-256 manifest of every nested file; validates SBOM/provenance references; fails on tamper; ships inside the bundle
3. scripts/generate-sbom.sh — generates SPDX 2.3 JSON SBOM from bundle contents and components.toml
4. scripts/generate-provenance.sh — generates SLSA-conformant provenance (source commit, builder image digest, toolchain, deps)
5. scripts/sign-bundle.sh — signs bundle manifest (minisign or GPG; graceful no-op when key not available)
6. Makefile targets: bundle-amd64, bundle-arm64, bundle-runtime-amd64, bundle-runtime-arm64, verify-bundle
7. tests/test_bundle.py — unit tests: assembly with mock artifacts, tamper detection, SBOM/provenance structure, manifest coverage
---
author: oompah
created: 2026-07-23 23:44
---
Implementation: Assembled the signed offline bundle infrastructure.

Files added/changed:
- scripts/assemble-bundle.sh: Main assembly script. Stages OTP archives, llama-server binary, GGUF model, systemd units, installer scripts, and license files into a versioned bundle directory. Generates manifest.sha256 (SHA-256 for every nested file), manifest.json (structured metadata), sbom.spdx.json, provenance.json. Creates reproducible tar.gz archive with SOURCE_DATE_EPOCH support plus archive-level .sha256. Validates model SHA-256 before staging (fails before any host mutation). Skips signing if no --sign-key provided.
- scripts/generate-sbom.sh: Generates SPDX 2.3 JSON SBOM with packages for Exocomp, Erlang/OTP, llama.cpp, and conditionally the Qwen model (complete bundle only). Includes DESCRIBES/CONTAINS relationships, license fields, and PURL external references.
- scripts/generate-provenance.sh: Generates SLSA v0.2 provenance (in-toto Statement). Records source commit, builder image digest, toolchain versions (from builders.lock), dependency locks (mix.lock SHA-256), build invocation parameters.
- scripts/sign-bundle.sh: Signs manifest.sha256 with minisign. Gracefully fails if minisign not installed.
- scripts/verify-bundle.sh: Ships inside the bundle. Verifies: (1) manifest.sha256 exists and is non-empty, (2) every listed file exists and matches its SHA-256, (3) sbom.spdx.json has required SPDX 2.3 structure, (4) provenance.json has required SLSA fields, (5) optional signature verification via minisign. --strict mode requires bundle.minisig.
- Makefile: Added test-bundle, bundle-amd64, bundle-arm64, bundle-runtime-amd64, bundle-runtime-arm64, verify-bundle targets. Fixed help awk pattern to include digits (for amd64/arm64 target names). Bundle variable overrides (NODE_ARCHIVE_*, COORD_ARCHIVE_*, LLAMA_SERVER_*, MODEL_PATH, MODEL_SHA256).
- tests/test_bundle.py: 68 tests covering assembly, manifest coverage, SBOM structure, provenance structure, tamper detection (modify/delete), checksum self-consistency, runtime bundle (no model), model SHA-256 pre-verification, SBOM complete-vs-runtime, strict mode, standalone script invocation.
---
author: oompah
created: 2026-07-23 23:44
---
Run #1 [attempt=1, profile=quick, role=fast -> Claude/default]
- Turns: 0, Tool calls: 79
- Tokens: 108 in / 3.8K out [3.9K total]
- Cost: $0.0000
- Exit: terminated, Duration: 11m 47s
- Log: EXOCOMP-44__20260723T233300Z.jsonl
---
<!-- COMMENTS:END -->
