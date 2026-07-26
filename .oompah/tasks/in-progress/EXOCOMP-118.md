---
id: EXOCOMP-118
type: bug
status: In Progress
priority: 1
title: Make the shipped node bundle install and start cleanly
parent: EXOCOMP-117
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-26T03:58:30.973367Z'
updated_at: '2026-07-26T04:02:54.251890Z'
work_branch: epic-EXOCOMP-117
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 595769bb-eb20-448f-af30-0e751949a9b3
oompah.work_branch: epic-EXOCOMP-117
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
<!-- COMMENTS:END -->
