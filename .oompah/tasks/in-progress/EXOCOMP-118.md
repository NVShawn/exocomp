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
- focus-complete:frontend
assignee: null
created_at: '2026-07-26T03:58:30.973367Z'
updated_at: '2026-07-26T04:19:45.246532Z'
work_branch: epic-EXOCOMP-117
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 07944eee-61ca-483c-852d-f95ad80398dc
oompah.work_branch: epic-EXOCOMP-117
oompah.task_costs:
  total_input_tokens: 2269558
  total_output_tokens: 11207
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 2269558
      output_tokens: 11207
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 2269544
    output_tokens: 7004
    cost_usd: 0.0
    recorded_at: '2026-07-26T04:03:55.158344+00:00'
  - profile: deep
    model: unknown
    input_tokens: 14
    output_tokens: 4203
    cost_usd: 0.0
    recorded_at: '2026-07-26T04:09:28.467391+00:00'
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
author: oompah
created: 2026-07-26 04:07
---
Run #1 [attempt=1, profile=deep, role=deep -> Codex/default]
- Turns: 0, Tool calls: 54
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 3m 29s
- Log: EXOCOMP-118__20260726T040407Z.jsonl
---
author: oompah
created: 2026-07-26 04:07
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-07-26 04:07
---
Focus: Frontend Developer
---
author: oompah
created: 2026-07-26 04:08
---
Discovery: the four failures share an inconsistent payload contract. config/config.exs hard-codes /var/lib/exocomp/replay_ledger.dets while install.sh and StateDirectory own /var/lib/exocomp-node; assemble-bundle.sh copies only the llama executable at bundle root (no companion .so closure and no installation into the node release); it also omits state-backup.sh. Assembly emits <bundle>.tar.gz.sha256 and embeds component archives as releases/*.tar.gz covered by manifest.sha256, but installation.md/lifecycle.md use checksums.sha256 and root-level archives. I will add a relocatable llama wrapper plus validated bundled ELF-library closure, install that runtime into node versions, align state paths/systemd write access, ship lifecycle tooling, and test the delivered commands/payload directly.
---
author: oompah
created: 2026-07-26 04:08
---
Understanding: Dispatched as Frontend Developer focus. After reviewing the codebase, this task involves exclusively DevOps/systems work: (1) fixing a path mismatch in config/config.exs where production config opens /var/lib/exocomp/replay_ledger.dets but the installer creates /var/lib/exocomp-node; (2) adding state-backup.sh to the assemble-bundle.sh scripts section which currently ships only install.sh, uninstall.sh, and verify-bundle.sh; (3) packaging llama-server shared library dependencies; (4) aligning documented checksum/install commands with actual archive layout. There is zero frontend (HTML/CSS/JS/UI) work in this issue. Proceeding to hand off to devops.
---
author: oompah
created: 2026-07-26 04:08
---
Discovery: Confirmed all four rc.2 defects in code:

1. PATH MISMATCH (config/config.exs:13): Production config hardcodes /var/lib/exocomp/replay_ledger.dets but install.sh:setup_users_and_dirs() creates var_dir=/var/lib/exocomp-node. Fix: change config.exs to use /var/lib/exocomp-node/replay_ledger.dets.

2. MISSING state-backup.sh (scripts/assemble-bundle.sh:~195, section 2e): Bundle ships install.sh, uninstall.sh, verify-bundle.sh only. state-backup.sh exists in scripts/ but is never copied to BUNDLE_STAGE/scripts/. Fix: add cp -f for state-backup.sh in that section.

3. LLAMA-SERVER SHARED LIBRARY: Bundle copies only the llama-server binary (section 2b) with no accompanying shared libraries. Fix: need to also copy libllama-server-impl.so and any other runtime deps into a lib/ subdirectory alongside the binary, and set RPATH or LD_LIBRARY_PATH accordingly in systemd unit.

4. CHECKSUM PATH MISMATCH: install.sh:verify_checksums() looks for CHECKSUMS_FILE defaulting to checksums.sha256 in BUNDLE_ROOT, but assemble-bundle.sh generates manifest.sha256 inside the bundle and <bundle>.tar.gz.sha256 at dist level. The documented commands and installer lookup don't align. Fix: align the filename or docs.

All fixes are in shell scripts (assemble-bundle.sh), Elixir config (config/config.exs), possibly systemd unit templates, and docs. No frontend work involved.
---
author: oompah
created: 2026-07-26 04:09
---
Focus handoff: frontend

1. Outcome: Frontend focus confirmed there is zero frontend (UI/CSS/JS) work in this task. All four rc.2 defects are DevOps/systems issues in shell scripts, Elixir config, and systemd units.

2. Relevant files and evidence:
   - config/config.exs line 13: hardcodes /var/lib/exocomp/replay_ledger.dets (wrong dir)
   - install.sh:setup_users_and_dirs(): creates /var/lib/exocomp-node (correct installer dir)
   - scripts/assemble-bundle.sh section 2e (~line 195): ships install.sh, uninstall.sh, verify-bundle.sh but NOT state-backup.sh
   - scripts/state-backup.sh: exists in repo, just not included in bundle assembly
   - assemble-bundle.sh section 2b: ships llama-server binary only, no shared library (.so) dependencies
   - install.sh:verify_checksums(): expects checksums.sha256 in bundle root; assemble-bundle.sh produces manifest.sha256 inside bundle and <name>.tar.gz.sha256 in dist/ — misaligned

3. Remaining work (all DevOps):
   - Fix config/config.exs to use /var/lib/exocomp-node/replay_ledger.dets
   - Add state-backup.sh to assemble-bundle.sh scripts section
   - Add llama-server shared library packaging (lib/ directory + LD_LIBRARY_PATH or RPATH in systemd unit)
   - Align checksum filename between assembler and installer / docs
   - Add regression tests: clean-root install, no-host-Erlang startup, verbatim-doc commands, shipped-only backup/restore
   - Run make test-installer, test-bundle, test-release-packaging

4. Recommended next focus: devops — all changes are in shell scripts, Elixir config, and systemd/release templates.
---
author: oompah
created: 2026-07-26 04:09
---
Agent completed successfully in 103s (4217 tokens)
---
author: oompah
created: 2026-07-26 04:09
---
Run #2 [attempt=2, profile=deep, role=deep -> Claude/default]
- Turns: 25, Tool calls: 16
- Tokens: 14 in / 4.2K out [4.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 43s
- Log: EXOCOMP-118__20260726T040747Z.jsonl
---
author: oompah
created: 2026-07-26 04:09
---
Focus handoff from `frontend` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-26 04:11
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-07-26 04:11
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-07-26 04:11
---
Understanding: implementing the clean-host runtime contract end to end: align the replay ledger with installer-owned durable state; ship llama-server with its complete non-system shared-library closure and relocatable lookup; reconcile the bundle manifest/archive paths with documented verification and installation commands; and include shipped backup/restore tooling. I will add focused bundle, installer, and lifecycle regressions, then run test-installer, test-bundle, test-release-packaging, and the available clean-systemd gate before commit/push/closure.
---
author: oompah
created: 2026-07-26 04:13
---
Discovery: confirmed the rc.2 failures are one inconsistent payload contract. Production node config targets /var/lib/exocomp while install.sh and StateDirectory own /var/lib/exocomp-node; assembly places component archives under releases/ and emits manifest.sha256 plus an adjacent outer .sha256 while docs/installer referenced root archives and checksums.sha256; only the llama executable was staged and not installed with its companion DSOs; and state-backup.sh existed only in the source tree. A terminated prior attempt left relevant uncommitted edits, which I reviewed and am completing with focused regressions rather than discarding.
---
author: oompah
created: 2026-07-26 04:19
---
Implementation: production replay state now targets /var/lib/exocomp-node and rendered units explicitly allow only the installer-owned state directory. Bundle assembly emits a relocatable llama launcher, original executable, and copied .so payload, validates every ELF NEEDED entry against the shipped closure or pinned host baseline, ships state-backup.sh, and records it in provenance. install.sh atomically places llama plus exocomp-state-backup in each node/versioned release before switching current. Installation/lifecycle/maintainer docs now use the delivered outer .sha256, extracted directory, releases/* archives, manifest.sha256, installed inference path, and installed backup command. Regressions cover incomplete payload rejection, real dynamic/transitive llama loading, rendered state ownership, verbatim doc commands, bundled-ERTS service-start control flow with host Erlang/network tools forbidden, and shipped-only backup/restore.
---
<!-- COMMENTS:END -->
