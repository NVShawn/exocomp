---
id: EXOCOMP-123
type: task
status: In Progress
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
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-26T03:58:35.710500Z'
updated_at: '2026-07-26T07:59:43.795742Z'
work_branch: epic-EXOCOMP-117
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: c521c741-cfe1-40c3-9e12-b5944f19e031
oompah.work_branch: epic-EXOCOMP-117
oompah.task_costs:
  total_input_tokens: 669741
  total_output_tokens: 8681
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 669741
      output_tokens: 8681
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 669727
    output_tokens: 4922
    cost_usd: 0.0
    recorded_at: '2026-07-26T07:57:17.437765+00:00'
  - profile: standard
    model: unknown
    input_tokens: 14
    output_tokens: 3759
    cost_usd: 0.0
    recorded_at: '2026-07-26T07:59:06.258785+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-26 07:54
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-26 07:54
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-26 07:57
---
Agent completed successfully in 177s (674649 tokens)
---
author: oompah
created: 2026-07-26 07:57
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 12
- Tokens: 669.7K in / 4.9K out [674.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 57s
- Log: EXOCOMP-123__20260726T075424Z.jsonl
---
author: oompah
created: 2026-07-26 07:57
---
Agent completed without closing this issue (177s (674649 tokens)). Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-26 07:57
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-26 07:57
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-26 07:58
---
Understanding: Duplicate-detector pass only. EXOCOMP-123 is the designated child requalification task under remediation epic EXOCOMP-117. I will compare its scope against existing tasks—particularly EXOCOMP-47 (original M6 qualification), other EXOCOMP-117 sibling tasks (118-122), and any other candidate—then either archive this issue as a confirmed duplicate or record the no-duplicate result and hand off to an implementation specialist.
---
author: oompah
created: 2026-07-26 07:58
---
Discovery: No confirmed duplicate. Full records reviewed for EXOCOMP-47 and EXOCOMP-117 (parent epic with children EXOCOMP-118, 119, 120, 121, 122). Key distinctions: EXOCOMP-47 owned the *initial* M6 qualification run that produced signed failure evidence for v0.1.0-rc.2 (now Merged, evidence committed to main via PR #17). EXOCOMP-117 is the remediation epic; its children (EXOCOMP-118 through EXOCOMP-122) are each done, delivering: clean bundle install, production coordinator PKI/enrollment wiring, reproducible offline bundles, robust cross-arch tests, and shipped M5 performance gate. EXOCOMP-123 is explicitly the distinct follow-up requalification task—to build a new signed release candidate after fixes land and run the complete qualification matrix fresh, without reusing results from the failed rc.2 run. It is not a repeat of EXOCOMP-47 (which recorded failure evidence) nor does it overlap any of the sibling remediation tasks.
---
author: oompah
created: 2026-07-26 07:58
---
Focus handoff: duplicate_detector

1. Outcome: Duplicate screening confirmed no duplicate. EXOCOMP-123 is the unique designated child task for post-remediation requalification of the M6 release candidate. All sibling remediation tasks (EXOCOMP-118, 119, 120, 121, 122) are now Done, unblocking this task.

2. Evidence/decisions: Full task records reviewed: EXOCOMP-47 (initial M6 qualification—now Merged with failure evidence), EXOCOMP-117 (remediation epic with all children Done), EXOCOMP-118 through EXOCOMP-122 (each covering a distinct defect domain: bundle runtime paths/llama deps/backup tooling; coordinator PKI/enrollment; offline bundle reproducibility; cross-arch test robustness; M5 performance gate). Docs searched: docs/release-evidence/v0.1.0-rc.2/, docs/clean-host-qualification.md, docs/installation.md. No scope overlap found with any of the above.

3. Remaining work/risks: The full requalification scope is substantial: build the exact candidate twice for amd64 and arm64; run all required Make gates (release-check, test-release-packaging, test-installer, test-bundle, test-release-matrix, test); run every documented live scenario (PKI init, enrollment/renewal, multi-node diagnostics, failed-service recovery, shipped-artifact M5 gates, hardening, upgrade/rollback, backup/restore, default+purge uninstall) on clean systemd guests; verify checksums, signatures, SBOM, provenance, reproducibility; commit signed indexed evidence. Requires a booted VM environment (QEMU arm64 accepted per EXOCOMP-47 precedent). No code changes needed for this specific task—evidence collection and qualification run only.

4. Recommended next focus: devops (release qualification, signing, and evidence collection across both architectures).
---
author: oompah
created: 2026-07-26 07:59
---
Agent completed successfully in 91s (3773 tokens)
---
author: oompah
created: 2026-07-26 07:59
---
Run #2 [attempt=2, profile=standard, role=standard -> Claude/default]
- Turns: 25, Tool calls: 17
- Tokens: 14 in / 3.8K out [3.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 31s
- Log: EXOCOMP-123__20260726T075740Z.jsonl
---
author: oompah
created: 2026-07-26 07:59
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-26 07:59
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-26 07:59
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-07-26 07:59
---
Understanding: DevOps qualification pass for a fresh post-remediation M6 candidate. I will identify and pin the exact source/tag, inspect the established rc.2 evidence contract, build/rebuild amd64 and arm64 artifacts where supported, run all repository and release Make gates plus shipped-artifact/live checks available in clean guests, and record only newly verified evidence. I will not reuse rc.2 results; unavailable signing or guest infrastructure will be documented and routed as remaining work rather than represented as passing.
---
<!-- COMMENTS:END -->
