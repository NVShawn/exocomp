---
id: EXOCOMP-47
type: chore
status: Needs Human
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
- EXOCOMP-115
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:12:06.325063Z'
updated_at: '2026-07-26T00:45:05.210320Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 3469956c-048f-4369-a97f-e7b4c1223ad9
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 1007774
  total_output_tokens: 5743
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1007774
      output_tokens: 5743
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 1007700
    output_tokens: 3823
    cost_usd: 0.0
    recorded_at: '2026-07-23T23:50:37.782495+00:00'
  - profile: default
    model: unknown
    input_tokens: 74
    output_tokens: 1920
    cost_usd: 0.0
    recorded_at: '2026-07-26T00:45:03.861151+00:00'
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
author: oompah
created: 2026-07-23 23:50
---
Agent completed successfully in 136s (1011523 tokens)
---
author: oompah
created: 2026-07-23 23:50
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 24
- Tokens: 1.0M in / 3.8K out [1.0M total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 16s
- Log: EXOCOMP-47__20260723T234824Z.jsonl
---
author: oompah
created: 2026-07-25 18:32
---
Action required: use recovery task EXOCOMP-115 to implement and verify this task's previously undelivered scope on main. Do not mark this task Merged again until EXOCOMP-115 lands and the original acceptance criteria are confirmed against main.
---
author: oompah
created: 2026-07-25 18:32
---
Moved to Needs Human from the dashboard/API. Human action required: inspect EXOCOMP-47 (Qualify the M6 open-source release on clean hosts), add the specific decision, missing information, or manual fix needed, then move the task back to Open when it is ready for agents again.
---
author: oompah
created: 2026-07-25 20:09
---
The parent epic EXOCOMP-6 merged from epic-EXOCOMP-6, but this task was Needs Human with work branch epic-EXOCOMP-6. Its work is not proven to be in the merged epic. Inspect the task's agent history and remote branches, recover any missing commits through a new recovery epic or approved follow-up PR, then move this task to Done only after the recovered work is verified on the target branch.
---
author: oompah
created: 2026-07-25 21:11
---
Human action required: choose and sign a candidate tag that contains main merge 2085e44152f03ffd41f35cbfeee89a0da53b8bce, then follow docs/clean-host-qualification.md on one native amd64 host and one native arm64 host (no QEMU/emulation). Attach the signed M6-CRIT evidence for artifact verification, offline install/no-network behavior, PKI/enrollment/renewal, multi-node diagnostics, failed-service recovery, M5 gates, hardening, upgrade/rollback, backup/restore, and uninstall. For each M6-CRIT item, answer: did it pass on both native architectures, and where is the signed evidence? If every answer is yes, move EXOCOMP-47 to Merged; if any answer is no, move it to Open with the failing criterion and logs.
---
author: oompah
created: 2026-07-26 00:38
---
Human decision received: bare metal is not required. A clean, full-system arm64 VM is acceptable qualification evidence. QEMU CPU emulation on this amd64 host may be used if the guest reports arm64, runs systemd, starts the shipped arm64 artifacts, and completes every M6-CRIT scenario. A passing M5 gate counts as conservative evidence; a performance-only failure under emulation is inconclusive and must remain unresolved rather than being waived.
---
author: oompah
created: 2026-07-26 00:40
---
The parent epic EXOCOMP-6 merged from epic-EXOCOMP-6, but this task was Open with work branch epic-EXOCOMP-6. Its work is not proven to be in the merged epic. Inspect the task's agent history and remote branches, recover any missing commits through a new recovery epic or approved follow-up PR, then move this task to Done only after the recovered work is verified on the target branch.
---
author: oompah
created: 2026-07-26 00:40
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-26 00:40
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-26 00:42
---
Understanding: EXOCOMP-47 needs M6 release qualification on clean hosts. The recovery epic EXOCOMP-115 has already landed on origin/main (commits 301d87e and 516faf8), which added docs/clean-host-qualification.md, docs/release-qualification.md, and corresponding Makefile targets (test-bundle, release-check, build-amd64, test-release-matrix). The current epic-EXOCOMP-6 branch is behind origin/main by ~24 commits. Plan: (1) merge origin/main into this branch to recover all EXOCOMP-115 work, (2) run the automated qualification gates that work in this environment (fmt-check, lint, test-installer), (3) document what requires native-hardware runs as Needs Human, (4) close appropriately.
---
author: oompah
created: 2026-07-26 00:43
---
Discovery: Fast-forwarded epic-EXOCOMP-6 to origin/main (2085e44). All EXOCOMP-115/114/113 recovery work is now present: docs/clean-host-qualification.md, docs/release-qualification.md, Makefile targets (test-bundle, release-check, build-amd64, test-release-matrix), and test suites (tests/test_bundle.py, tests/test_check_compliance.py, tests/test_operator_docs.py, tests/test_package_release.py). Running automated gates now.
---
author: oompah
created: 2026-07-26 00:45
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 40
- Tokens: 74 in / 1.9K out [2.0K total]
- Cost: $0.0000
- Exit: terminated, Duration: 4m 58s
- Log: EXOCOMP-47__20260726T004008Z.jsonl
---
<!-- COMMENTS:END -->
