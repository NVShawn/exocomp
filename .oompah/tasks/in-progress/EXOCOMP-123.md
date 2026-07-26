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
updated_at: '2026-07-26T18:17:55.586616Z'
work_branch: epic-EXOCOMP-117
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 9b467efa-c6d5-45c3-b9e1-2cbd91b1eb8a
oompah.work_branch: epic-EXOCOMP-117
oompah.task_costs:
  total_input_tokens: 670850
  total_output_tokens: 333087
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 670850
      output_tokens: 333087
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
  - profile: deep
    model: unknown
    input_tokens: 204
    output_tokens: 79688
    cost_usd: 0.0
    recorded_at: '2026-07-26T09:36:10.797973+00:00'
  - profile: standard
    model: unknown
    input_tokens: 204
    output_tokens: 84088
    cost_usd: 0.0
    recorded_at: '2026-07-26T10:11:26.283244+00:00'
  - profile: standard
    model: unknown
    input_tokens: 202
    output_tokens: 65994
    cost_usd: 0.0
    recorded_at: '2026-07-26T12:51:02.074766+00:00'
  - profile: deep
    model: unknown
    input_tokens: 204
    output_tokens: 85826
    cost_usd: 0.0
    recorded_at: '2026-07-26T14:53:54.238737+00:00'
  - profile: standard
    model: unknown
    input_tokens: 295
    output_tokens: 8810
    cost_usd: 0.0
    recorded_at: '2026-07-26T16:01:41.602495+00:00'
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
author: oompah
created: 2026-07-26 08:02
---
Discovery: origin/main is 01c14b8 (only EXOCOMP-118 merged); the current epic branch is seven commits ahead through EXOCOMP-122 at 371ca4e, and no post-remediation candidate tag exists. Therefore the task's mandatory order—siblings land on main, then sign an exact candidate—has not yet occurred. The rc.2 SSH signing identity is available and verifies, and the retained amd64 KVM and full-system arm64 QEMU guests are running with the pinned llama/model inputs, but they contain rc.2 state and have no clean snapshots. I will use them only for preflight regression gates unless/until an exact signed post-merge candidate and clean guest reset are available.
---
author: oompah
created: 2026-07-26 08:12
---
Implementation: Preflight exposed an integration regression between EXOCOMP-119 and the release qualification path. Updated scripts/smoke-releases.sh and scripts/test-clean-container.sh so their narrowly scoped bundled-ERTS probes explicitly disable coordinator PKI only inside the ephemeral eval process; production startup remains fail-closed and will still be qualified with initialized PKI on systemd guests. Added structural regression assertions in scripts/test-release-builders.sh for both probes. make test-builders passes (runtime-dependency fixtures, 13 offline matrix checks, packaging/normalizer/operator-doc suites).
---
author: oompah
created: 2026-07-26 08:36
---
Implementation: Live publication preflight found two additional release blockers. The coordinator systemd unit now receives the bootstrap PKI/enrollment state paths (e5db3e0). Bundle Make targets now pass an immutable builder identity and minisign key into the assembler, with structural gate coverage and maintainer documentation (b6fa9ee). The prior b10107 binary input also exposed an undeclared libgomp dependency; I am rebuilding the exact pinned upstream tag with OpenMP disabled so the offline runtime has a redistributable, closed dependency set.
---
author: oompah
created: 2026-07-26 08:53
---
Discovery: Signed candidate v0.1.0-rc.3 was rejected immediately by its fresh exact-tag make fmt-check gate; no rc.3 result will be reused for acceptance. The drift was confined to five EXOCOMP-119 coordinator source/test files. I applied mix format through the pinned Elixir 1.20.2 builder, verified fmt/lint and an 844-test pass, and added fresh invariant rc.4 M5 baseline identities. Commit 73b61e8 is now undergoing preflight before a replacement tag is signed.
---
author: oompah
created: 2026-07-26 08:59
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 256
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: stalled, Duration: 1h 0m 11s
- Log: EXOCOMP-123__20260726T075922Z.jsonl
---
author: oompah
created: 2026-07-26 08:59
---
Agent stalled 1 time(s) (3611s). Escalating from 'standard' to 'deep'. Retrying in 10s (attempt #1)
---
author: oompah
created: 2026-07-26 08:59
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-07-26 08:59
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-26 09:01
---
Understanding: Software Engineer continuation run on EXOCOMP-123. The previous DevOps agent successfully made all code fixes (PKI wiring, bundle signing inputs, coordinator formatting, rc.4 M5 baselines) and signed the v0.1.0-rc.4 tag at commit 73b61e8, then stalled during live qualification. My role is to: (1) verify the code changes are sound by running available source-tree tests, (2) create the docs/release-evidence/v0.1.0-rc.4/ evidence directory structure, (3) run all Make gates available in this environment, and (4) determine next steps for live VM qualification. Branch is clean and up to date with origin.
---
author: oompah
created: 2026-07-26 09:11
---
Discovery: Both qualification VMs (exocomp-amd64-qualification and exocomp-arm64-qualification) are running and accessible via QEMU guest agent. The amd64 VM already has all repository/release Make gates passed for rc.4 (verified in rc4/evidence/raw/amd64/repo-gates/ transcript). rc.4 artifacts (node + coordinator) are built at rc4/src-gates/dist/releases/. llama-b10107-no-openmp runtime is complete. Coordinator currently running rc.3 on amd64 VM. arm64 VM source is at rc.2 HEAD, no rc.4 qualification started yet. Writing comprehensive live qualification scripts to run on both VMs.
---
author: oompah
created: 2026-07-26 09:35
---
Implementation: Fixed version-detection regression in scripts/install.sh (commit bf0b3ee). The sed regex \`[0-9]+\.[0-9]+\.[0-9]+[^.]*\` stopped at the dot in \`-rc.4\`, causing the full substitution to fail—install.sh would output the raw filename, fail semver validation, and die before creating any directories. Fixed with \`.+\` backtracked against the \`-linux-(amd64|arm64)\.tar\.gz\` suffix, which correctly extracts \`0.1.0-rc.4\`. Added 5-case parametrised test \`TestVersionValidation::test_version_detected_from_archive_name\` covering stable and pre-release versions; 76 installer tests pass. Will now re-run coordinator install on the amd64 qualification VM.
---
author: oompah
created: 2026-07-26 09:36
---
Agent failed: Reached maximum number of turns (200). Retrying in 20s (attempt #2)
---
author: oompah
created: 2026-07-26 09:36
---
Run #2 [attempt=2, profile=deep, role=deep -> Claude/default]
- Turns: 342, Tool calls: 236
- Tokens: 204 in / 79.7K out [79.9K total]
- Cost: $0.0000
- Exit: error, Duration: 36m 24s
- Log: EXOCOMP-123__20260726T085948Z.jsonl
---
author: oompah
created: 2026-07-26 09:36
---
Retrying (attempt #2, agent: standard)
---
author: oompah
created: 2026-07-26 09:36
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-26 09:46
---
Understanding (continuation run #2): Picking up from previous Software Engineer session. Previous agent fixed install.sh version detection (bf0b3ee) and wrote QA scripts, then hit max turns. Root causes for the 7 failures in the amd64 qualification run are now identified: (1) PKI ceremony fails with pki_storage_error because exocomp-coordinator user cannot traverse /var/lib/exocomp-qualification/rc4/ (mode 750, owned by exocomp:exocomp, not in group) — the offline backup path in QA scripts is inaccessible; (2) The bundle on the VM was assembled from rc.4 tag (73b61e8) BEFORE the install.sh fix (bf0b3ee), so install.sh in the bundle extracts version as 0.1.0 instead of 0.1.0-rc.4. Coordinator still functions but version directory is wrong. These issues cascade into all downstream failures: coordinator starts but crashes (PKI uninitialized), node never successfully enrolls, M5 bench never runs. Plan: fix both issues in source, create rc.5 candidate, rebuild bundles on both VMs, run fresh qualification.
---
author: oompah
created: 2026-07-26 09:49
---
Discovery: Root cause of all 7 amd64 failures confirmed. (1) PKI ceremony uses eval mode with --boot RELEASE_BOOT_SCRIPT_CLEAN, so no OTP applications start; Bootstrap.initialize() runs directly. The failure is pki_storage_error because exocomp-coordinator user cannot traverse /var/lib/exocomp-qualification (mode 750, owned by exocomp:exocomp, user not in group), making ensure_parent() fail with EACCES for the offline_backup path. Fix: use /tmp/exocomp-offline-root-rc4 as offline backup (tmpfs, accessible to all). (2) Bundle install.sh regex extracts VERSION=0.1.0 (OTP version, not 0.1.0-rc.4) but both OTP and installer versions work identically since the wrapper script uses start_erl.data not the outer dir name. Fix: pass --version 0.1.0-rc.4 explicitly. (3) Crash dump in log is from systemd service restart after failed ceremony (separate from eval). Plan: rewrite QA scripts with both fixes, re-run amd64, run arm64 fresh.
---
author: oompah
created: 2026-07-26 10:11
---
Agent failed: Reached maximum number of turns (200). Retrying in 40s (attempt #3)
---
author: oompah
created: 2026-07-26 10:11
---
Run #3 [attempt=3, profile=standard, role=standard -> Claude/default]
- Turns: 322, Tool calls: 216
- Tokens: 204 in / 84.1K out [84.3K total]
- Cost: $0.0000
- Exit: error, Duration: 34m 50s
- Log: EXOCOMP-123__20260726T093637Z.jsonl
---
author: oompah
created: 2026-07-26 10:12
---
Retrying (attempt #3, agent: standard)
---
author: oompah
created: 2026-07-26 10:12
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-26 10:12
---
Understanding (continuation attempt #3): I am reconciling the current branch/tag/evidence/VM state left by the prior qualification runs, then will resume the exact signed post-remediation candidate qualification on clean amd64 and arm64 systemd guests. I will preserve rejected rc.3/rc.4 results as non-acceptance evidence, fix only newly proven release blockers with focused tests, and close only after every M6-CRIT/live scenario has fresh signed indexed passing evidence committed and pushed.
---
author: oompah
created: 2026-07-26 10:24
---
Discovery: Fresh rc.5 live-path inspection found an untested privilege-boundary blocker before signing. ActionCatalog generated exact sudoers entries for /usr/bin/systemctl and /usr/bin/journalctl, but Executor invoked those programs directly as the unprivileged exocomp-node service user; fixture/unit tests injected a commander or ran as root, masking the production denial. rc.5 remains unsigned and is rejected as a preflight identity. The replacement source is b4d0123.
---
author: oompah
created: 2026-07-26 10:24
---
Implementation: ActionCatalog now executes the immutable privileged commands through /usr/bin/sudo with absolute systemctl/journalctl paths and validated fixed argv, matching the installed NOPASSWD policy while preserving the no-shell boundary. Updated focused catalog, executor, and M3 acceptance assertions; added invariant amd64/arm64 rc.6 M5 baseline identities. Host-native make release-check and make test-installer pass (28 governance tests, 76 installer tests), and M5 structural tests pass. Commit b4d0123 is pushed.
---
author: oompah
created: 2026-07-26 10:46
---
Discovery: rc.7 amd64 shipped-artifact preflight now passes end to end: strict signed-bundle verification in a no-network namespace, offline coordinator/node install, production PKI ceremony with offline root removal, healthy coordinator, node-bound enrollment over TLS, and enrolled node systemd startup. Two preceding failures were confined to the uncommitted qualification helper (service account inherited inaccessible /root; SSL application not started for the clean enrollment eval), not candidate code. Candidate commit remains 4a02c172da52ef7fe04aaa8bf7cc0701c4b38859.
---
author: oompah
created: 2026-07-26 11:04
---
Implementation: rc.7 is rejected by live failed-service recovery. The node action catalog correctly invoked exact sudo, but the shipped unit made every setuid transition impossible (NoNewPrivileges=true, empty capability bounding set, SecureBits=noroot). Commit 34ee7d2 applies the live-validated minimum: node-only CAP_SETUID/CAP_SETGID bounding set, no ambient capabilities, NoNewPrivileges=false, no noroot secure bit, and account-scoped !pam_session while preserving exact NOPASSWD commands and sudo auditing. Installer/Elixir regression tests and operator documentation were updated; invariant rc.8 M5 baselines were added. Host gates: 76 installer tests and 28 release-check tests pass.
---
author: oompah
created: 2026-07-26 11:12
---
Run #4 [attempt=4, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 325
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: stalled, Duration: 1h 0m 8s
- Log: EXOCOMP-123__20260726T101214Z.jsonl
---
author: oompah
created: 2026-07-26 11:12
---
Agent stalled 2 time(s) (3608s). Escalating from 'standard' to 'deep'. Retrying in 80s (attempt #4)
---
author: oompah
created: 2026-07-26 11:13
---
Retrying (attempt #4, agent: deep)
---
author: oompah
created: 2026-07-26 11:13
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-26 11:14
---
Understanding (continuation attempt #4): Resuming from the rc.8 node privilege-boundary fix at commit 34ee7d2. I will reconcile branch/tag/evidence/VM state, preflight and sign the next exact candidate, run every required repository, packaging, offline, systemd/live, M5, upgrade/rollback, backup/restore, and uninstall scenario fresh on amd64 and arm64, record signed indexed evidence, then commit, push, and close only if every M6-CRIT item passes.
---
author: oompah
created: 2026-07-26 11:23
---
Discovery: rc.8 pretag amd64 passed strict no-network verification/install, production PKI init, enrollment/renewal, restart durability, audit fail-closed behavior, and live failed-service recovery through shipped sudo. The required live multi-node diagnostic then exposed a distinct release blocker: the coordinator's production A2A client has no :a2a_tls runtime configuration, Bootstrap emits only coordinator.pem (leaf) plus intermediate_ca.pem, and the node rejects the outbound coordinator client certificate with TLS unknown_ca because no coordinator chain file is presented. rc.8 remains unsigned/rejected preflight source; no result will be reused for acceptance.
---
author: oompah
created: 2026-07-26 11:37
---
Implementation: rc.9 fixes production coordinator-to-node A2A mTLS by emitting and validating a leaf-plus-intermediate coordinator chain, wiring it into the systemd/runtime outbound client, and covering bootstrap corruption plus installer/runtime structure. Added invariant rc.9 M5 ceilings and committed qualification helpers that exercise exact-tag offline install/PKI/enrollment, signed approval and replay denial, multi-node diagnostics, automatic recovery, bounded cleanup/unsafe denials, lifecycle rollback/backup/uninstall, and protected-state preservation. Focused gates pass: test-builders and all 76 installer tests; the clean amd64 full rerun passes 845 tests (10 excluded).
---
author: oompah
created: 2026-07-26 11:53
---
Discovery: signed rc.9 is rejected and none of its results will count for acceptance. Its amd64 live run proved the production signed-approval gate and exact sudo restart worked, then the exact-tag qualification helper supplied active service evidence without the required health classification; ApprovalRequired correctly escalated the post-action verification as unstable. This is confined to the new qualification helper, not candidate runtime behavior. I added a real fixture health probe to the helper and created fresh invariant rc.10 M5 identities; qualification restarts from the replacement signed tag.
---
author: oompah
created: 2026-07-26 12:08
---
Discovery: Signed rc.10 is rejected by the first shipped M5 short gate. The standalone bench_harness release starts :inets but omits its runtime :public_key dependency; OTP 28 :httpc constructs TLS hostname-verification options even for the local HTTP llama health probe, producing UndefinedFunctionError before measurement. Source/unit tests masked this because apps/bench/test/test_helper.exs explicitly starts :public_key. I stopped the incomplete arm64 rc.10 run and will qualify only a replacement candidate.
---
author: oompah
created: 2026-07-26 12:14
---
Agent stalled — no productive actions (writes/commands) for 10 consecutive turns (3645s). Retrying in 160s (attempt #5)
---
author: oompah
created: 2026-07-26 12:14
---
Run #5 [attempt=5, profile=deep, role=deep -> Codex/default]
- Turns: 1, Tool calls: 264
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: stalled, Duration: 1h 0m 45s
- Log: EXOCOMP-123__20260726T111352Z.jsonl
---
author: oompah
created: 2026-07-26 12:17
---
Retrying (attempt #5, agent: standard)
---
author: oompah
created: 2026-07-26 12:17
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-26 12:18
---
Understanding (continuation attempt #5): Resuming from rc.10 rejection. The two post-rc.10 commits (77c6d8c: add :public_key to bench extra_applications; 6df88c3: race-safe approval cleanup) are on HEAD. rc.11 M5 baseline directories exist but no git tag has been created and no evidence directory exists yet. My plan: (1) run available source-tree tests to verify fixes are sound, (2) sign the v0.1.0-rc.11 tag at HEAD, (3) create docs/release-evidence/v0.1.0-rc.11/ evidence structure, (4) run all Make gates available in this environment, (5) run qualification helpers against the amd64 and arm64 VMs if accessible, (6) commit signed indexed evidence and close the task.
---
author: oompah
created: 2026-07-26 12:43
---
Discovery (attempt #5): Both VMs accessible via QEMU agent. amd64 VM: rc11-preflight source checkout at 6df88c3 (correct HEAD), services running rc.10. arm64 VM: src/ updated from rc.4 to 6df88c3 via git fetch from GitHub. amd64 has llama-b10107-no-openmp runtime, arm64 uses llama-b10107 native binaries (no OpenMP deps). rc.11 signed tag created at HEAD (6df88c3) — fixes: :public_key in bench_harness extra_applications + race-safe approval cleanup. All source-tree gates pass (fmt-check, lint, test, test-bundle, test-installer, test-m5-qualification, release-check). Now launching comprehensive qualification on both VMs: two builds for reproducibility, bench_harness build, complete bundle assembly, preflight/operational/bench/lifecycle phases.
---
author: oompah
created: 2026-07-26 12:51
---
Agent failed: Reached maximum number of turns (200). Retrying in 300s (attempt #6)
---
author: oompah
created: 2026-07-26 12:51
---
Run #6 [attempt=6, profile=standard, role=standard -> Claude/default]
- Turns: 314, Tool calls: 227
- Tokens: 202 in / 66.0K out [66.2K total]
- Cost: $0.0000
- Exit: error, Duration: 33m 40s
- Log: EXOCOMP-123__20260726T121724Z.jsonl
---
author: oompah
created: 2026-07-26 12:56
---
Retrying (attempt #6, agent: standard)
---
author: oompah
created: 2026-07-26 12:56
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-26 12:56
---
Understanding (continuation attempt #6): v0.1.0-rc.11 is a signed tag at 6df88c3 and the branch is pushed. I am resuming the already-started fresh qualification by reconciling the two VM workspaces and any running/background build logs, then will complete double-build reproducibility, every required repository and shipped-artifact/live gate on amd64 and arm64, assemble a signed evidence index, commit and push it, and close only if every M6-CRIT requirement passes. Rejected rc.3 through rc.10 evidence will not be reused.
---
author: oompah
created: 2026-07-26 13:03
---
Discovery (continuation attempt #6): The prior guest jobs did not reach rc.11 qualification: the ephemeral orchestration wrappers copied archives from the obsolete _build/release/<arch> path and omitted RELEASE_VERSION, while current make build-* writes dist/releases artifacts using mix.exs version 0.1.0 unless RELEASE_VERSION is supplied. I corrected only the uncommitted guest orchestration to build 0.1.0-rc.11 into isolated build1/build2 directories, compare exact hashes, record every required Make gate per architecture, supply the locked builder-image digest during signed bundle assembly, and run both short and full shipped M5 gates. The signed candidate remains unchanged at 6df88c3. Fresh jobs are running in both dedicated systemd guests.
---
author: oompah
created: 2026-07-26 13:05
---
Discovery: signed v0.1.0-rc.11 is rejected and none of its incomplete results will count for acceptance. Fresh amd64 make test failed 1/845 in M3AcceptanceTest cleanup: Process.alive?/1 returned true, the ReplayLedger exited before GenServer.stop/3, and the untrapped cleanup exit failed the test. rc.11 fixed the identical TOCTOU race in approval_gate_test.exs but not the remaining M3 integration helpers. I stopped the arm64 rc.11 run and am applying the same exit-safe cleanup pattern across the remaining test helpers before signing a replacement candidate.
---
author: oompah
created: 2026-07-26 13:11
---
Implementation: Applied exit-safe GenServer teardown to all remaining node test helpers that used the racy Process.alive?/GenServer.stop check, not just the one rc.11 file; this preserves teardown intent while treating an already-exited linked process as successful cleanup. Added invariant amd64/arm64 rc.12 M5 baseline identities and updated the baseline inventory assertion. Commits b723eea, 33a9d23, and cf4c7b6 are pushed. Three consecutive pinned amd64 make test runs passed 845 tests (10 excluded); final exact-HEAD pretag gates are running before any rc.12 tag is created.
---
author: oompah
created: 2026-07-26 13:21
---
Discovery: the first rc.12 amd64 orchestration attempt stopped before live installation because its uncommitted wrapper named the pinned no-OpenMP executable llama-server.bin, while the verified runtime input is llama-server. Candidate artifacts and source gates were unaffected. I corrected the ephemeral path and restarted the entire amd64 rc.12 run from an empty rc12 evidence directory rather than reusing partial results. The arm64 exact-tag run continues independently.
---
author: oompah
created: 2026-07-26 13:29
---
Discovery: the corrected amd64 run passed all repo/build/preflight/operational scenarios, then the temporary wrapper pre-created the write-once BENCH_EVIDENCE_DIR; the shipped M5 harness correctly rejected it. I removed that wrapper-only mkdir for both short and full evidence paths. To keep the acceptance record atomic, I discarded the partial rc.12 directories, stopped arm64 before it reached the same condition, and restarted both complete exact-tag runs from empty evidence roots. Candidate source remains unchanged.
---
author: oompah
created: 2026-07-26 13:51
---
Verification progress: final rc.12 amd64 record has passed fmt/lint/release-check, packaging/installer/bundle/test, release matrix, two identical release builds, signed no-network bundle verification/install, production PKI/enrollment/renewal, restart/audit durability, multi-node diagnostics, approval/recovery, hardening, and the short shipped M5 gate; its mandatory 30-minute full M5 run is active. Arm64 has passed fmt/lint/release-check/packaging/installer and is advancing through test-bundle under full-system QEMU. No candidate failure is present.
---
author: oompah
created: 2026-07-26 13:56
---
Run #7 [attempt=7, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 162
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: stalled, Duration: 1h 0m 2s
- Log: EXOCOMP-123__20260726T125611Z.jsonl
---
author: oompah
created: 2026-07-26 13:56
---
Agent stalled 4 time(s) (3602s). Escalating from 'standard' to 'deep'. Retrying in 300s (attempt #7)
---
author: oompah
created: 2026-07-26 14:01
---
Retrying (attempt #7, agent: deep)
---
author: oompah
created: 2026-07-26 14:01
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-26 14:05
---
Understanding (attempt #7): Resuming from stalled Codex agent. Current state: amd64 completed Phases 1-8 (repo gates, builds, bundle, preflight, operational, bench-short) and was killed mid-Phase 9 (M5 bench full). No bench evidence dir exists yet; coordinator and node services are still active on 192.168.122.136. arm64 is mid-qualification: completed fmt-check, lint, release-check, test-release-packaging, test-installer, test-bundle, and is currently running 'make test' under QEMU emulation on 192.168.122.171. Plan: (1) Resume amd64 Phase 9 (M5 full bench, ~30 min) then Phase 10 (lifecycle), (2) Continue arm64 in parallel through all remaining phases, (3) Assemble evidence index, sign, commit, push, and close.
---
author: oompah
created: 2026-07-26 14:53
---
Agent failed: Reached maximum number of turns (200). Retrying in 300s (attempt #8)
---
author: oompah
created: 2026-07-26 14:53
---
Run #8 [attempt=8, profile=deep, role=deep -> Claude/default]
- Turns: 351, Tool calls: 235
- Tokens: 204 in / 85.8K out [86.0K total]
- Cost: $0.0000
- Exit: error, Duration: 52m 34s
- Log: EXOCOMP-123__20260726T140121Z.jsonl
---
author: oompah
created: 2026-07-26 14:59
---
Retrying (attempt #8, agent: standard)
---
author: oompah
created: 2026-07-26 14:59
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-26 14:59
---
Understanding (continuation attempt #8): Resuming from where attempt #7 left off. Previous state: v0.1.0-rc.12 signed at HEAD (cf4c7b6), amd64 had completed Phases 1-8 including short M5 bench and was running full M5 bench (~30 min), arm64 had passed fmt/lint/release-check/packaging/installer/test-bundle and was running make test. I will: (1) reconcile VM and evidence state, (2) complete any remaining phases on both architectures, (3) assemble signed indexed evidence, (4) commit, push, and close. Will not reuse any rc.3 through rc.11 results.
---
author: oompah
created: 2026-07-26 15:11
---
Discovery: Signed rc.12 is rejected by the lifecycle phase. Root cause: the shipped state-backup.sh binary uses --no-same-owner during archive extraction in validate_archive(), causing restored config files (coordinator.json, release-cookie.env) to be owned by root:root instead of exocomp-coordinator:exocomp-coordinator. The coordinator service cannot read its config from root:root 600 files running as the exocomp-coordinator service user, producing {:file_read, :eacces} on every startup. This is a divergence between the committed source (which has --no-same-owner at the rc.12 tag) and what was needed. A previous agent's uncommitted working-tree fix (--same-owner) is already present along with a bundle regression test, rc.13 M5 baselines, and updated baseline count assertion. I will commit the fix, run source-tree gates, create rc.13, and restart full qualification on both VMs from clean state.
---
author: oompah
created: 2026-07-26 15:30
---
Verification progress (attempt #8): rc.13 qualification running on both VMs.

amd64 (192.168.122.136): Phases 1-8 complete (repo gates, double build, reproducibility, bench_harness build, bundle assembly, live preflight, operational, M5 bench short). Phase 9 (M5 bench full, ~30 min) now active. All prior phases passed. Fixed: src-gates symlink issue in continuation script (live-preflight.sh expects \${QUALIFICATION_ROOT}/src-gates).

arm64 (192.168.122.171): In repository gate phase (release-check compliance tests) under full QEMU emulation. Expected to be ~2-3x slower than amd64 overall.

Root cause of today's rc.13: state-backup.sh --no-same-owner → --same-owner fix now in source at 640dd7dd. All prior rc candidates (rc.3-rc.12) remain rejected; no results reused.
---
author: oompah
created: 2026-07-26 16:01
---
Agent stalled 5 time(s) (3761s (9105 tokens)). Escalating from 'standard' to 'deep'. Retrying in 300s (attempt #9)
---
author: oompah
created: 2026-07-26 16:01
---
Run #9 [attempt=9, profile=standard, role=standard -> Claude/default]
- Turns: 285, Tool calls: 183
- Tokens: 295 in / 8.8K out [9.1K total]
- Cost: $0.0000
- Exit: stalled, Duration: 1h 2m 41s
- Log: EXOCOMP-123__20260726T145902Z.jsonl
---
author: oompah
created: 2026-07-26 16:06
---
Retrying (attempt #9, agent: deep)
---
author: oompah
created: 2026-07-26 16:06
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-26 16:07
---
Understanding (continuation attempt #9): Resuming the signed v0.1.0-rc.13 qualification at commit 640dd7dd. The previous run reported amd64 phases 1-8 passing with the full M5 gate active and arm64 progressing through repository gates. I will reconcile current guest and evidence state, finish every missing exact-tag phase without reusing rejected candidates, assemble and verify signed indexed evidence, commit and push it, then close only if every M6-CRIT/live requirement passes.
---
author: oompah
created: 2026-07-26 16:08
---
Discovery (continuation attempt #9): rc.13 amd64 passed every repository/build/offline/live/operational gate and the full 30-minute M5 gate, then lifecycle failed during the synthetic prior-version node reinstall: /opt/exocomp/node/config/node.json and release-cookie.env became root-owned, so the exocomp-node service failed with {:file_read, :eacces}. Separately, an obsolete rc.12 arm64 continuation was still running concurrently against the same source checkout as rc.13, invalidating the in-progress arm64 record. I am stopping the obsolete job, determining whether the ownership failure is candidate installer behavior or helper setup, and will restart only fresh uncontaminated qualification work.
---
author: oompah
created: 2026-07-26 16:12
---
Implementation: rc.13 is rejected by live lifecycle and none of its results will count for acceptance. Commit 798ddd9 fixes the installer upgrade bug by removing the recursive root chown of the whole component tree, preserving service ownership of existing config/cookie/PKI/log state; a behavioral upgrade regression test now asserts protected-file UID/GID stability. Added invariant rc.14 M5 baselines. make test-installer passes 77 tests; structural M5 tests pass (the host container portion is unavailable because its rootless Podman runtime path is read-only). Signed tag v0.1.0-rc.14 at 798ddd92156afac4e790e17384ae28d9ed6c9c11 is verified and pushed.
---
author: oompah
created: 2026-07-26 16:24
---
Qualification restart: the first rc.14 orchestration stopped before live installation because the uncommitted evidence helper attempted to copy bundle metadata before strict preflight had extracted the archive. Candidate code/artifacts did not fail. I moved metadata capture after preflight, discarded both partial rc.14 evidence roots, cleaned both exact-tag checkouts, and restarted a single fresh run per architecture at 798ddd9. No partial result will be accepted.
---
author: oompah
created: 2026-07-26 16:26
---
Discovery: signed rc.14 is rejected by its fresh exact-tag make test gate (844/845). VacuumBoundsTest asserted function_exported?(VacuumBounds, :check_eligible, 1) without ensuring the module was loaded; under the clean parallel run it returned false despite the function existing. This is a test-order/load race, but the required exact-tag gate did not pass, so no rc.14 result will be accepted. I am stopping arm64, adding a load-safe structural assertion, and will require repeated full test passes before signing a replacement candidate.
---
author: oompah
created: 2026-07-26 16:31
---
Implementation: commit 151ce856 makes every VacuumBounds API-shape assertion explicitly load the module before function_exported?/3, eliminating the randomized test-order false negative; invariant rc.15 M5 baselines are added. Pretag verification on amd64 passed make test three consecutive times (845 tests, 10 excluded each), fmt-check, 32 focused M5 tests, and all 77 installer tests. Signed tag v0.1.0-rc.15 at 151ce8560dab898c789335660e4fe375a79269eb is verified and pushed; fresh dual-architecture qualification is starting from empty roots.
---
author: oompah
created: 2026-07-26 16:36
---
Understanding (continuation attempt #9): Resuming the active exact-tag v0.1.0-rc.15 qualification at 151ce8560dab898c789335660e4fe375a79269eb. Both dedicated clean systemd guest runs were launched from empty evidence roots after rc.14 was rejected. I will complete both architecture matrices, audit every live/M5/lifecycle result, assemble and verify a signed evidence index, commit and push the accepted evidence, then close only if every M6-CRIT requirement passes.
---
author: oompah
created: 2026-07-26 16:44
---
Verification progress: exact signed rc.15 is running from fresh empty evidence roots on both dedicated systemd guests. amd64 has passed every repository/release gate, two byte-identical builds, signed no-network bundle verification/install, production PKI/enrollment/renewal, restart and audit durability, multi-node diagnostics, approved recovery, hardening, and shipped M5 short; its mandatory full M5 collection is active. arm64 has passed fmt/lint and is advancing through release-check under full-system QEMU. No candidate failure is present.
---
author: oompah
created: 2026-07-26 17:06
---
Agent stalled — no productive actions (writes/commands) for 10 consecutive turns (3605s). Retrying in 300s (attempt #10)
---
author: oompah
created: 2026-07-26 17:06
---
Run #10 [attempt=10, profile=deep, role=deep -> Codex/default]
- Turns: 1, Tool calls: 194
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: stalled, Duration: 1h 0m 5s
- Log: EXOCOMP-123__20260726T160650Z.jsonl
---
author: oompah
created: 2026-07-26 17:12
---
Retrying (attempt #10, agent: standard)
---
author: oompah
created: 2026-07-26 17:12
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-26 17:12
---
Understanding (continuation attempt #10): Resuming the exact signed v0.1.0-rc.15 qualification at 151ce8560dab898c789335660e4fe375a79269eb. I will reconcile both dedicated guest jobs and fresh evidence roots, finish every missing repository/build/offline/live/M5/lifecycle gate without reusing rejected candidates, assemble and verify a signed evidence index, commit and push it, then close only if all M6-CRIT requirements pass.
---
author: oompah
created: 2026-07-26 17:13
---
Verification progress (continuation attempt #10): Both exact signed rc.15 guest jobs are still healthy. amd64 has passed all repository gates, double-build reproducibility, signed no-network bundle verification/install, production PKI/enrollment/renewal, multi-node diagnostics, approved recovery, hardening, and shipped M5 short; the full M5 process has crossed its 30-minute minimum and remains active. arm64 has passed through test-bundle and is running exact-tag make test under full-system QEMU. No candidate failure is present.
---
author: oompah
created: 2026-07-26 17:19
---
Discovery: signed rc.15 is rejected by live amd64 lifecycle and none of its results will count for acceptance. The installer application health gate invokes the release 'rpc' command with System.halt(...); because rpc evaluates remotely, a passing health check terminates the newly started service itself. systemd then runs ExecStop against an already-dead node, gets :noconnection, and restart churn makes the upgrade fail. Live inspection also found StartLimitIntervalSec/StartLimitBurst in [Service], which systemd ignores; both units must place start limits in [Unit]. I am stopping the obsolete arm64 rc.15 job and fixing both defects with regression coverage before a replacement candidate.
---
author: oompah
created: 2026-07-26 17:23
---
Implementation: commit c351dc2 fixes the live upgrade blockers. Installer RPC health probes now return :ok or raise on the remote service instead of calling System.halt, so a successful probe cannot terminate the service. Both node and coordinator start-limit directives moved from [Service] to [Unit]. Bundle regression fixtures reject destructive health RPCs and assert correct unit section placement; invariant rc.16 M5 identities are added. Focused results: 77 installer tests, 101 bundle tests, 28 release-check tests, and test-builders pass; host M5 structural tests pass while its container half is unavailable due the known read-only rootless-Podman runtime path.
---
author: oompah
created: 2026-07-26 17:32
---
Qualification progress: fresh exact-tag rc.16 runs are active from empty roots with the corrected double-bundle reproducibility check. amd64 has passed through test-bundle and is running make test; arm64 is completing pinned-builder startup for fmt-check under full-system QEMU. Both jobs are alive and no failure marker is present.
---
author: oompah
created: 2026-07-26 17:37
---
Verification progress: amd64 passed all repository gates, two identical release builds, and the newly required two byte-identical complete signed bundle assemblies. Strict no-network verification/install and production PKI/enrollment preflight also passed; operational scenarios are active. arm64 remains healthy in lint's fully emulated compile with no failure.
---
author: oompah
created: 2026-07-26 18:12
---
Run #11 [attempt=11, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 170
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: stalled, Duration: 1h 0m 42s
- Log: EXOCOMP-123__20260726T171203Z.jsonl
---
author: oompah
created: 2026-07-26 18:12
---
Agent stalled 7 time(s) (3642s). Escalating from 'standard' to 'deep'. Retrying in 300s (attempt #11)
---
author: oompah
created: 2026-07-26 18:12
---
Discovery: signed rc.16 is rejected by fresh amd64 lifecycle and none of its results will count for acceptance. Full shipped M5 passed, but forced upgrade-health failure exposed an incomplete rollback contract: install.sh restores the prior symlink and calls systemctl restart without waiting for the restored application to become RPC-ready. In the live race, the new service was not yet RPC-ready when rollback began; ExecStop returned :noconnection, the stop timed out, and the installer returned while the prior service was only starting. The lifecycle's immediate prior-release RPC therefore failed. I am stopping the still-running arm64 rc.16 record and will make rollback ordered and application-health-verified before signing a replacement candidate.
---
author: oompah
created: 2026-07-26 18:17
---
Retrying (attempt #11, agent: deep)
---
author: oompah
created: 2026-07-26 18:17
---
Focus: Software Engineer
---
<!-- COMMENTS:END -->
