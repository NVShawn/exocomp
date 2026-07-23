---
id: EXOCOMP-47
type: chore
status: Merged
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
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:12:06.325063Z'
updated_at: '2026-07-23T23:50:23.627750Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 8b00a712-e38c-4339-9c7b-086c729ec63f
oompah.work_branch: epic-EXOCOMP-6
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 23:48
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 23:48
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 23:48
---
Understanding: Screening EXOCOMP-47 for duplication only. I will compare its M6 clean-host release qualification scope against existing tasks and their full descriptions/comments, then archive only if the same underlying work is already tracked; otherwise I will record the closest candidates and hand off to the next focus.
---
author: oompah
created: 2026-07-23 23:49
---
Discovery: Duplicate screening found no confirmed duplicate. Closest reviewed task EXOCOMP-68 qualifies only OTP archive reproducibility, clean-container ERTS startup, wrong-architecture behavior, and missing-runtime diagnostics; its full comments explicitly distinguish EXOCOMP-47 as downstream full M6 qualification. EXOCOMP-40 through EXOCOMP-46 produce or test individual inputs, while EXOCOMP-6 is the parent epic. The M6 plan assigns EXOCOMP-47 the unique cross-cutting candidate-tag matrix and signed M6-CRIT evidence.
---
author: oompah
created: 2026-07-23 23:50
---
Implementation: No repository implementation was performed, as required by the duplicate_detector focus. The only tracker action is recording the screening result and routing label; the live tracker already reports EXOCOMP-47 and parent EXOCOMP-6 as Merged.
---
author: oompah
created: 2026-07-23 23:50
---
Verification: Searched the tracker state ref and repository plans/docs for qualification, clean-host, release-gate, recovery, upgrade, rollback, and uninstall overlap; reviewed EXOCOMP-6, EXOCOMP-40 through EXOCOMP-46, and EXOCOMP-68 through full tracker views. No code changed, so Make quality gates are not applicable to this screening-only run.
---
author: oompah
created: 2026-07-23 23:50
---
Focus handoff: duplicate_detector

1. Outcome: No duplicate confirmed; EXOCOMP-47 uniquely owns final end-to-end M6 candidate qualification.
2. Evidence: Reviewed EXOCOMP-6, EXOCOMP-40 through EXOCOMP-46, and closest candidate EXOCOMP-68 in full; searched origin/oompah/state/proj-c260b117 plus plans/docs. EXOCOMP-68 explicitly excludes the PKI, multi-node, M4/M5, lifecycle, hardening, documentation, and signed-evidence scope owned here.
3. Remaining work/risks: The live tracker already marks EXOCOMP-47 and its parent Merged. If qualification evidence was not actually captured before that transition, a subsequent implementation audit must verify every M6-CRIT item and both native architectures from the candidate tag; clean-host and signed-evidence claims cannot be established by fixture-only tests.
4. Recommended next focus: test or devops for a release-evidence audit, only if the current Merged state is determined premature. No repository files changed in this focus.
---
<!-- COMMENTS:END -->
