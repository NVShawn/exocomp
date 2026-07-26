---
id: EXOCOMP-120
type: bug
status: Backlog
priority: 1
title: Make offline bundles reproducible and cryptographically complete
parent: EXOCOMP-117
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-26T03:58:32.906799Z'
updated_at: '2026-07-26T03:58:32.906799Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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

