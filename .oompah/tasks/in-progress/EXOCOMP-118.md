---
id: EXOCOMP-118
type: bug
status: In Progress
priority: 1
title: Make the shipped node bundle install and start cleanly
parent: EXOCOMP-117
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-26T03:58:30.973367Z'
updated_at: '2026-07-26T04:04:28.619142Z'
work_branch: epic-EXOCOMP-117
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: eaa487c6-37e6-4d72-baa7-9ba4e63e08ed
oompah.work_branch: epic-EXOCOMP-117
oompah.task_costs:
  total_input_tokens: 2269544
  total_output_tokens: 7004
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 2269544
      output_tokens: 7004
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 2269544
    output_tokens: 7004
    cost_usd: 0.0
    recorded_at: '2026-07-26T04:03:55.158344+00:00'
---
## Summary

Context
The v0.1.0-rc.2 clean-host evidence shows the installed node crashes because production config opens /var/lib/exocomp/replay_ledger.dets while the installer owns /var/lib/exocomp-node. The bundled llama-server also fails with a missing libllama-server-impl.so, documented archive and checksum paths do not match the extracted bundle, and scripts/state-backup.sh is not shipped.

Implementation
Align production runtime paths with installer-owned directories and permissions. Package every llama-server runtime dependency. Make the documented checksum and install commands match the delivered archive layout. Include the backup and restore utility in the installed and offline payloads. Relevant areas include config/config.exs, scripts/assemble-bundle.sh, installer assets, systemd units, and docs/installation.md plus docs/lifecycle.md.

Testing
Add regression tests that install the assembled bundle into a clean root, start the node service without host Erlang or network access, execute the documented verification and install commands verbatim, and complete backup and restore using only shipped files. Run make test-installer, make test-bundle, make test-release-packaging, and the clean-systemd VM scenario.

Acceptance Criteria
- The installed node service remains active and owns a writable durable replay ledger.
- Bundled llama-server starts on a clean host with all runtime libraries present.
- Published verification and installation commands succeed verbatim.
- Shipped backup and restore preserve protected state.
- Focused tests and relevant Make gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-26 03:59
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-26 03:59
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-26 03:59
---
Understanding: duplicate screening will compare this issue's clean-host bundle failures—replay-ledger path ownership, missing llama-server shared libraries, archive/checksum command mismatch, and absent backup/restore payload—against existing tasks. I will read plausible candidates in full and either archive EXOCOMP-118 as a confirmed duplicate or hand it off without implementation.
---
author: oompah
created: 2026-07-26 04:02
---
Discovery: no duplicate confirmed. EXOCOMP-43/44 and recovery EXOCOMP-114 delivered the installer and bundle infrastructure; EXOCOMP-46/115 delivered lifecycle and backup/restore behavior; EXOCOMP-47 gathered the signed v0.1.0-rc.2 evidence and explicitly routed these newly observed runtime defects into remediation epic EXOCOMP-117, whose task graph names EXOCOMP-118 as the dedicated child. EXOCOMP-68 tests OTP-release startup rather than the complete installed bundle. Adjacent EXOCOMP-120 owns bundle reproducibility, signed metadata, and licenses, while EXOCOMP-123 is downstream requalification. None covers EXOCOMP-118's combined replay-ledger path, llama runtime-library, delivered command-layout, and shipped backup-utility fixes.
---
author: oompah
created: 2026-07-26 04:02
---
Implementation: none in this duplicate_detector run, as required. The issue is unique and should proceed to an implementation specialist; repository files and git history were left unchanged.
---
author: oompah
created: 2026-07-26 04:02
---
Verification: searched task titles/content and repository docs/plans for clean-host, replay ledger, llama-server dependencies, archive/checksum paths, and state-backup terms; reviewed EXOCOMP-43, 44, 46, 47, 68, 114, 115, 117, 120, and 123 via full tracker views. docs/release-evidence/v0.1.0-rc.2/README.md records the four exact failures as newly observed qualification findings. No code changed, so Make quality gates are not applicable.
---
author: oompah
created: 2026-07-26 04:03
---
Focus handoff: duplicate_detector

1. Outcome: duplicate screening found no duplicate; EXOCOMP-118 is the unique corrective task for the installed-node and shipped-payload failures exposed by v0.1.0-rc.2.
2. Evidence/decisions: full records reviewed were EXOCOMP-43, 44, 46, 47, 68, 114, 115, 117, 120, and 123. The first group delivered the underlying installer/bundle/lifecycle machinery; EXOCOMP-47 produced the failure evidence; EXOCOMP-117 deliberately decomposed the fixes; EXOCOMP-120 and 123 have non-overlapping reproducibility and downstream qualification scopes. Relevant evidence is docs/release-evidence/v0.1.0-rc.2/README.md; likely implementation areas remain config/config.exs, scripts/assemble-bundle.sh, scripts/install.sh, release assets/systemd units, docs/installation.md, docs/lifecycle.md, and installer/bundle/release tests.
3. Remaining work/risks: align the durable ledger with installer-owned writable state; ship llama-server's complete shared-library closure and configure lookup; make documented verification/install commands match archive layout; ship state-backup.sh in installed/offline payloads; add clean-root/systemd, no-host-Erlang/no-network, verbatim-doc-command, and shipped-only backup/restore regressions. Guard the boundary with EXOCOMP-120 so runtime payload completeness stays here while signed metadata/license completeness stays there.
4. Recommended next focus: devops, because the work crosses release assembly, installer/systemd runtime ownership, offline payload layout, and clean-host qualification tests.
---
author: oompah
created: 2026-07-26 04:03
---
Completion: duplicate-detector focus is complete. No duplicate was found, no repository changes were made, and the task is labeled focus-complete:duplicate_detector plus needs:devops for fresh implementation dispatch. EXOCOMP-118 remains In Progress and was not archived or closed.
---
author: oompah
created: 2026-07-26 04:03
---
Agent completed successfully in 275s (2276548 tokens)
---
author: oompah
created: 2026-07-26 04:03
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 32
- Tokens: 2.3M in / 7.0K out [2.3M total]
- Cost: $0.0000
- Exit: normal, Duration: 4m 35s
- Log: EXOCOMP-118__20260726T035926Z.jsonl
---
author: oompah
created: 2026-07-26 04:03
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-26 04:04
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-07-26 04:04
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-07-26 04:04
---
Understanding: I will reproduce and correct the four rc.2 clean-host defects as one runtime-installability change: align the replay ledger with installer-owned state, assemble llama-server's complete shared-library closure with deterministic lookup, make published checksum/install commands match the actual archive, and ship backup/restore tooling in installed and offline payloads. I will add focused clean-root/doc-command/shipped-only lifecycle regressions, then run test-installer, test-bundle, test-release-packaging, and the clean-systemd VM gate before commit, push, and closure.
---
<!-- COMMENTS:END -->
