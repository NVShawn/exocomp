---
id: EXOCOMP-47
type: chore
status: Backlog
priority: 2
title: Qualify the M6 open-source release on clean hosts
parent: EXOCOMP-6
children: []
blocked_by:
- EXOCOMP-40
- EXOCOMP-41
- EXOCOMP-43
- EXOCOMP-44
- EXOCOMP-45
- EXOCOMP-46
labels: []
assignee: null
created_at: '2026-07-23T19:12:06.325063Z'
updated_at: '2026-07-23T19:14:01.231495Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Qualify the M6 open-source release on clean hosts.

Implementation
Run release qualification on clean amd64 and arm64 hosts: verify artifacts, offline install, PKI init, node enrollment/renewal, multi-node diagnostics, M4 recovery, M5 gates, hardening inspection, upgrade, rollback, backup/restore, and uninstall; collect signed evidence.

Testing
Execute all release, security, documentation-command, clean-host, and repository Make gates from the candidate tag; verify checksums, signatures, SBOM, provenance, licenses, file ownership, and no-network behavior.

Acceptance Criteria
- [ ] Every M6-CRIT-* item has recorded pass/fail evidence.
- [ ] Both architectures pass complete clean-host qualification.
- [ ] Failed-service recovery and performance gates pass using shipped artifacts.
- [ ] Upgrade/rollback/uninstall preserve protected state and user data.
- [ ] Candidate is reproducible and publication-ready.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

