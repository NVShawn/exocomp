---
id: EXOCOMP-120
type: bug
status: In Progress
priority: 1
title: Make offline bundles reproducible and cryptographically complete
parent: EXOCOMP-117
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-26T03:58:32.906799Z'
updated_at: '2026-07-26T05:02:16.183738Z'
work_branch: epic-EXOCOMP-117
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: d29229cf-723e-41b6-896e-ea06365889e8
oompah.work_branch: epic-EXOCOMP-117
oompah.task_costs:
  total_input_tokens: 33
  total_output_tokens: 6286
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 33
      output_tokens: 6286
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 33
    output_tokens: 6286
    cost_usd: 0.0
    recorded_at: '2026-07-26T05:02:00.406475+00:00'
---
## Summary

Context
The v0.1.0-rc.2 OTP archives are reproducible, but two complete-bundle assemblies differ. The signed root does not authenticate the structured manifest, SBOM, or provenance, so tampering those files still passes strict verification. The shipped LICENSES directory is empty and required third-party license texts are absent.

Implementation
Remove all nondeterministic complete-bundle inputs and normalize archive metadata. Define one signed integrity root that transitively authenticates every shipped payload and metadata file, including manifest.json, SBOM, provenance, license inventory, and nested artifacts. Populate LICENSES from the governed component inventory and fail assembly when required texts are missing. Update verifier behavior and operator documentation.

Testing
Add double-build byte-identity tests, signed-metadata tamper tests for each metadata class, license completeness tests, offline strict verification, and negative cases for omitted or extra unsigned files. Run make release-check, make test-compliance, make test-bundle, make test-release-packaging, and both architecture bundle builds.

Acceptance Criteria
- Identical complete-bundle inputs produce byte-identical archives.
- Strict verification rejects any payload, manifest, SBOM, provenance, or license tamper.
- Every governed third-party component has its required shipped license and notice.
- Assembly fails closed for missing, untracked, or unsigned required content.
- Focused tests and relevant Make gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-26 04:59
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-26 04:59
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-26 04:59
---
Understanding: Investigating EXOCOMP-120 as Duplicate Investigator. The issue describes three distinct problems: (1) non-deterministic complete-bundle assembly producing non-byte-identical archives, (2) signed root not authenticating manifest.json, SBOM, provenance, or license files — so tampering those passes strict verification, (3) empty LICENSES directory missing required third-party license texts. Searching for existing tasks covering these topics before any implementation.
---
author: oompah
created: 2026-07-26 05:01
---
Discovery: No duplicate confirmed. Full records reviewed for EXOCOMP-41, EXOCOMP-44, EXOCOMP-47, EXOCOMP-68, EXOCOMP-117, EXOCOMP-118, and EXOCOMP-119. Key evidence: (1) EXOCOMP-44 built the initial bundle assembly infrastructure (assemble-bundle.sh, SBOM, provenance, signing, manifest.sha256) but qualification of rc.2 found that the signed root does NOT authenticate manifest.json, SBOM, or provenance — EXOCOMP-44 comment #21 explicitly notes 'signed-metadata and shipped-license defects are distinct follow-up work tracked by EXOCOMP-120'; (2) EXOCOMP-41 built the repo governance/license files but the assembled bundle LICENSES/ directory is empty — EXOCOMP-41 comment #29 says 'newly observed shipped-license completeness defect is distinct follow-up work tracked by EXOCOMP-120'; (3) EXOCOMP-68 covered OTP archive reproducibility (byte-identical double-build for OTP .tar.gz archives) but NOT complete-bundle reproducibility — the raw/amd64/live/bundle-reproducibility.sha256 evidence shows two identical complete-bundle assemblies have different SHA-256 values; (4) EXOCOMP-117 is the parent remediation epic that deliberately decomposed these defects — EXOCOMP-120 is its explicitly named unique child for 'deterministic and cryptographically complete bundles'. EXOCOMP-120 is unique and should proceed to implementation.
---
author: oompah
created: 2026-07-26 05:01
---
Focus handoff: duplicate_detector

1. Outcome: Duplicate screening found no duplicate. EXOCOMP-120 is the unique remediation child task for the three related v0.1.0-rc.2 qualification failures: (a) non-deterministic complete-bundle assembly, (b) signed root not authenticating manifest.json/SBOM/provenance/licenses, (c) empty LICENSES directory in the bundle.

2. Relevant files, commands, evidence, and decisions:
   - docs/release-evidence/v0.1.0-rc.2/README.md: M6-CRIT-8 records all three defects; evidence files raw/amd64/live/bundle-reproducibility.sha256 (differing SHA-256 for two identical assemblies) and raw/amd64/live/unsigned-metadata-tamper-verify.log (strict verify passes after manifest/provenance tamper) confirm the gaps.
   - docs/release-evidence/v0.1.0-rc.2/raw/arm64/artifacts/assemble.log: 'WARN: LICENSES/ directory not found at .../src/LICENSES; skipping' confirms the empty licenses gap.
   - scripts/assemble-bundle.sh: existing assembly script from EXOCOMP-44 — sources of nondeterminism (timestamps in SBOM/provenance, missing SOURCE_DATE_EPOCH normalization for complete bundle) need to be found and removed.
   - scripts/verify-bundle.sh: ships in bundle; needs to verify manifest.json, SBOM, provenance, and licenses files against the signed root.
   - licenses/ or LICENSES/: source tree location for component license texts that must be populated and staged.
   - tests/test_bundle.py: existing test suite (75 tests in rc.2) — needs double-build byte-identity tests, signed-metadata tamper tests for each metadata class, and license completeness tests.
   - Makefile targets: make release-check, make test-compliance, make test-bundle, make test-release-packaging.

3. Remaining work and risks:
   - Identify all nondeterministic inputs in complete bundle assembly (SBOM timestamps, provenance build timestamps, manifest timestamps, archive metadata) and normalize them.
   - Define a single signed integrity root that transitively covers manifest.json, SBOM, provenance, and license inventory alongside the existing payload files.
   - Update verify-bundle.sh to reject any tamper of these metadata files during strict verification.
   - Populate the LICENSES directory from the component inventory (licenses/components.toml) and fail assembly when required license texts are missing.
   - Add double-build byte-identity test, tamper tests for each metadata class, license completeness tests, and offline strict verification tests.
   - Risk: The SBOM and provenance have time-varying fields (creation timestamps, build timestamps) — these need to be set from SOURCE_DATE_EPOCH consistently.
   - Risk: The signed manifest structure needs to change — currently manifest.sha256 covers payload files but the signing needs to also cover manifest.json, sbom.spdx.json, provenance.json, and license files.

4. Recommended next focus: devops — the work crosses release assembly scripts (bash), tamper verification, offline bundle layout, and test suites (Python). All implementation is in scripts/assemble-bundle.sh, scripts/verify-bundle.sh, licenses/, and tests/test_bundle.py.
---
author: oompah
created: 2026-07-26 05:02
---
Agent completed successfully in 163s (6319 tokens)
---
author: oompah
created: 2026-07-26 05:02
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 46, Tool calls: 30
- Tokens: 33 in / 6.3K out [6.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 43s
- Log: EXOCOMP-120__20260726T045920Z.jsonl
---
author: oompah
created: 2026-07-26 05:02
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-26 05:02
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-07-26 05:02
---
Focus: DevOps Engineer
---
<!-- COMMENTS:END -->
