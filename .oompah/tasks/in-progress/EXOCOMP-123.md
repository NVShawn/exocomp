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
updated_at: '2026-07-26T12:08:52.590496Z'
work_branch: epic-EXOCOMP-117
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: b4fecb11-2cb3-4f6b-87b1-38f4db77e56b
oompah.work_branch: epic-EXOCOMP-117
oompah.task_costs:
  total_input_tokens: 670149
  total_output_tokens: 172457
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 670149
      output_tokens: 172457
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
<!-- COMMENTS:END -->
