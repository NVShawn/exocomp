---
id: EXOCOMP-123
type: task
status: Open
priority: 1
title: Requalify the remediated M6 release candidate
parent: EXOCOMP-117
children: []
blocked_by:
- EXOCOMP-118
- EXOCOMP-119
- EXOCOMP-120
- EXOCOMP-121
- EXOCOMP-122
labels: []
assignee: null
created_at: '2026-07-26T03:58:35.710500Z'
updated_at: '2026-07-26T03:59:29.594952Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Context
v0.1.0-rc.2 has signed indexed failure evidence. After the sibling remediation tasks land on main, create a new signed candidate and repeat the complete qualification without reusing unverified results from the failed candidate.

Implementation
Build the exact candidate twice for amd64 and arm64. Run repository and release Make gates, offline verification and installation, production PKI initialization, enrollment and renewal, multi-node diagnostics, failed-service recovery, shipped-artifact M5 gates, hardening inspection, upgrade and automatic rollback, backup and restore, and default plus purge uninstall. Use clean systemd guests; full-system QEMU arm64 is accepted. Record signed indexed evidence and the accepted qualification identity.

Testing
Execute make release-check, make test-release-packaging, make test-installer, make test-bundle, make test-release-matrix for both architectures, make test, and every documented live scenario from the exact signed tag. Verify checksums, signatures, SBOM, provenance, licenses, file ownership, no-network behavior, reproducibility, and protected-state preservation.

Acceptance Criteria
- Every M6-CRIT item records passing evidence on both architectures.
- All required live scenarios pass using only shipped artifacts.
- The complete bundle is reproducible and publication-ready.
- Signed indexed evidence is committed, reviewed, and merged.
- No task is closed based solely on fixture or source-tree tests.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

