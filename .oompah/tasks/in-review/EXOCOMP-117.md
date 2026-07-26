---
id: EXOCOMP-117
type: epic
status: In Review
priority: 1
title: Remediate v0.1.0-rc.2 M6 qualification failures
parent: null
children:
- EXOCOMP-118
- EXOCOMP-119
- EXOCOMP-120
- EXOCOMP-121
- EXOCOMP-122
- EXOCOMP-123
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-26T03:57:27.844799Z'
updated_at: '2026-07-26T04:56:22.465431Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Triggered by: EXOCOMP-47

Context
Signed qualification evidence is published under docs/release-evidence/v0.1.0-rc.2 and records a publication-blocking result on clean amd64 and full-system arm64 guests.

Scope
Coordinate focused child fixes for shipped runtime/install correctness, production PKI and enrollment startup, deterministic and cryptographically complete bundles, portable cross-architecture tests, and a real shipped-artifact M5 performance gate. Finish with a new signed candidate and repeat the complete clean-host matrix.

Testing
Each child must add regression coverage and run its relevant Make targets. Final qualification must run release-check, test-release-packaging, test-installer, test-bundle, test-release-matrix on amd64 and arm64, repository tests, and live systemd scenarios from the exact signed candidate.

Acceptance Criteria
- Every failure recorded for v0.1.0-rc.2 has an implemented and tested fix.
- A new signed candidate passes all M6-CRIT items on clean amd64 and full-system arm64 guests.
- Signed indexed evidence is committed and merged.
- The release is reproducible and publication-ready.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

