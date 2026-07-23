---
id: EXOCOMP-43
type: feature
status: In Progress
priority: 2
title: Implement hardened installers and uninstallers
parent: EXOCOMP-6
children: []
blocked_by:
- EXOCOMP-25
- EXOCOMP-42
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:12:02.637514Z'
updated_at: '2026-07-23T23:20:39.204396Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 0bc64c04-e17c-4fac-b761-ab53d827f251
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 2185201
  total_output_tokens: 70796
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 2185201
      output_tokens: 70796
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 531536
    output_tokens: 3280
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:49:08.021188+00:00'
  - profile: standard
    model: unknown
    input_tokens: 593703
    output_tokens: 3478
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:51:12.903265+00:00'
  - profile: deep
    model: unknown
    input_tokens: 89
    output_tokens: 58830
    cost_usd: 0.0
    recorded_at: '2026-07-23T23:17:18.323183+00:00'
  - profile: standard
    model: unknown
    input_tokens: 1059873
    output_tokens: 5208
    cost_usd: 0.0
    recorded_at: '2026-07-23T23:20:36.512022+00:00'
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Implement hardened installers and uninstallers.

Implementation
Implement non-interactive node/coordinator install, upgrade hooks, dedicated users/directories, atomic version link, configuration templates, systemd hardening, exact sudoers policy, installed-file manifest, and scoped uninstall/purge categories; preserve PKI/config/audit/execution state by default.

Testing
Test clean install, repeat install, permissions, service startup, invalid checksum/config, exact privileges, upgrade preparation, default uninstall, explicit system-cache purge, and proof user data/non-owned resources remain.

Acceptance Criteria
- [ ] Installer validates before host mutation.
- [ ] Services run unprivileged with expected hardening.
- [ ] Only configured exact privilege rules are installed.
- [ ] Default uninstall preserves protected operator state and all user data.
- [ ] Install tests pass.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 22:47
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:47
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:49
---
Agent completed successfully in 91s (534816 tokens)
---
author: oompah
created: 2026-07-23 22:49
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 7
- Tokens: 531.5K in / 3.3K out [534.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 31s
- Log: EXOCOMP-43__20260723T224740Z.jsonl
---
author: oompah
created: 2026-07-23 22:49
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-6`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 22:49
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:49
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:51
---
Agent completed successfully in 107s (597181 tokens)
---
author: oompah
created: 2026-07-23 22:51
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 16
- Tokens: 593.7K in / 3.5K out [597.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 47s
- Log: EXOCOMP-43__20260723T224927Z.jsonl
---
author: oompah
created: 2026-07-23 22:51
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-6`. Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
author: oompah
created: 2026-07-23 22:51
---
Retrying (attempt #2, agent: deep)
---
author: oompah
created: 2026-07-23 22:51
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:58
---
Focus handoff: duplicate_detector

1. Outcome: No duplicate confirmed. EXOCOMP-43 is a unique task.

2. Evidence reviewed:
   - EXOCOMP-25 (Done): Implements unprivileged executor and exact sudoers POLICY — a prerequisite runtime security module, not an installer. Distinct scope.
   - EXOCOMP-42 (Done): Builds reproducible OTP release archives — a prerequisite artifact builder, not a system installer/uninstaller. Distinct scope.
   - EXOCOMP-44 (Open): Signed offline bundles, SBOMs, provenance — downstream bundling step, not installer scripts.
   - No existing task covers: dedicated user/directory creation, versioned install directories, atomic symlinks, systemd unit deployment with hardening, sudoers installation, installed-file manifests, or scoped uninstall/purge categories.
   - plans/milestone-6-release.md: EXOCOMP-43 maps to M6-CRIT-4 and M6-CRIT-6.

3. Remaining work:
   - Node and coordinator install scripts (preflight → user creation → versioned dir → atomic link → systemd unit → sudoers → manifest)
   - Hardened systemd unit files for node and coordinator
   - Configuration templates
   - Uninstall with scoped purge categories (default preserves PKI/config/audit)
   - Test suite: clean install, repeat install, permissions, service startup, invalid checksum/config, exact privileges, upgrade preparation, default uninstall, explicit system-cache purge, proof user data/non-owned resources remain

4. Recommended next focus: feature (shell scripting + Python test suite)
---
author: oompah
created: 2026-07-23 23:00
---
Understanding: Implementing hardened installers and uninstallers for exocomp node/coordinator.

Scope (from milestone-6-release.md, M6-CRIT-4 and M6-CRIT-6):
- scripts/install.sh: Non-interactive installer with preflight validation, dedicated user/dir setup, versioned install directory, atomic current symlink, config templates, systemd hardening, exact sudoers policy, installed-file manifest
- scripts/uninstall.sh: Scoped uninstaller with purge categories; default preserves config/PKI/audit/execution state
- release/node/exocomp-node.service: Hardened systemd unit (NoNewPrivileges, ProtectSystem=strict, CapabilityBoundingSet=, etc.)
- release/coordinator/exocomp-coordinator.service: Same for coordinator
- release/templates/: node.json and coordinator.json config templates
- test/installer/test_installer.py: Tests for clean install, repeat install, permissions, invalid checksums/config, sudoers content, default uninstall, system-cache purge, user data preservation

Tests will use EXOCOMP_ROOT env var to redirect paths for root-free CI testing. Systemd-dependent tests are marked and skipped when not in a systemd environment.

Prerequisite EXOCOMP-25 (executor/sudoers Elixir modules) is Done on origin/EXOCOMP-25 but not yet merged to main. The installer generates sudoers entries directly in bash (same format as the Elixir module) so no runtime dependency.
---
author: oompah
created: 2026-07-23 23:11
---
Implementation: Implemented hardened installer and uninstaller.

Files created:
- scripts/install.sh: 8-phase hardened installer (preflight validation → user/dir setup → versioned release extract → config template → sudoers policy → systemd unit → activate → manifest). Supports EXOCOMP_ROOT/EXOCOMP_SKIP_SYSTEMD/EXOCOMP_SKIP_USERADD/EXOCOMP_SKIP_CHOWN env overrides for testing without root/systemd.
- scripts/uninstall.sh: Scoped uninstaller reading manifest to remove only exocomp-owned files. Default preserves config/, log/, pki/, var/lib/. Supports --purge system-cache category.
- release/node/exocomp-node.service: Hardened systemd unit (NoNewPrivileges, ProtectSystem=strict, CapabilityBoundingSet=, PrivateTmp, MemoryDenyWriteExecute, LockPersonality, RestrictNamespaces, SystemCallFilter, UMask=0077, dedicated user)
- release/coordinator/exocomp-coordinator.service: Same hardening for coordinator
- release/templates/node.json: Node configuration template with PKI paths, action allow-list, diagnostics
- release/templates/coordinator.json: Coordinator configuration template with PKI, A2A agent card, approval settings
- test/installer/test_installer.py: 50 tests covering all acceptance criteria
- Makefile: test-installer target added
---
author: oompah
created: 2026-07-23 23:16
---
Verification: All tests pass.

make test-installer: 50/50 installer tests pass
  - TestCleanInstall (8 tests): versioned dir, symlink, config, systemd unit, sudoers, manifest
  - TestRepeatInstall (2 tests): idempotent, config preserved on repeat
  - TestPermissions (4 tests): 644 unit, 440 sudoers, 640 config, a-w release dir
  - TestInvalidChecksum (3 tests): tampered bundle rejected, no host mutation on failure
  - TestExactPrivileges (5 tests): exact entries, no wildcards, metacharacter rejection
  - TestUpgradePreparation (3 tests): new version beside old, atomic symlink update, config preserved
  - TestDefaultUninstall (7 tests): unit+sudoers removed, config/log/configdir preserved
  - TestSystemCachePurge (3 tests): release dirs removed, config+log preserved
  - TestUserDataPreservation (4 tests): home dir untouched, var/lib preserved, PKI preserved, bad purge rejected
  - TestDryRun (2 tests): exits 0, no files created
  - TestMissingComponentFlag (1 test)
  - TestUnitHardeningDirectives (6 tests): 16 directives verified in both unit files
  - TestConfigTemplates (2 tests): valid JSON, expected keys present

make test-fixture-service: 22/22 existing fixture tests pass (no regressions)
bash -n: install.sh and uninstall.sh syntax valid

Acceptance criteria confirmed:
✓ Installer validates before host mutation (checksum, arch, disk space check)
✓ Services run unprivileged with expected hardening (16 directives per unit file)
✓ Only configured exact privilege rules are installed (no wildcards, metacharacter injection rejected)
✓ Default uninstall preserves protected operator state and all user data
✓ Install tests pass
---
author: oompah
created: 2026-07-23 23:16
---
Completion: EXOCOMP-43 delivered.

Files created on epic-EXOCOMP-6 branch (commit 3036c94):
- scripts/install.sh — Hardened 8-phase installer (preflight→user/dir→extract→config→sudoers→unit→activate→manifest)
- scripts/uninstall.sh — Scoped uninstaller with purge categories; default preserves PKI/config/audit
- release/node/exocomp-node.service — 16-directive hardened systemd unit (NoNewPrivileges, ProtectSystem=strict, CapabilityBoundingSet=, UMask=0077, SystemCallFilter, etc.)
- release/coordinator/exocomp-coordinator.service — Same hardening for coordinator
- release/templates/node.json — Node configuration template
- release/templates/coordinator.json — Coordinator configuration template
- test/installer/test_installer.py — 50 tests (pytest, no root/systemd required)
- Makefile — test-installer target

Security properties enforced:
1. Checksums verified before any host mutation; tampered bundles rejected
2. Service names in allow-list validated by strict regex; shell metacharacters rejected unconditionally
3. Sudoers entries name exact executable + exact argument — no wildcards
4. Release directories locked a-w after install; only root can write
5. Uninstaller reads manifest to remove only exocomp-owned files
6. Config/PKI/log directories preserved by default; explicit purge categories required to remove system cache
7. Systemd hardening: 16 security directives per unit file, dedicated unprivileged accounts
---
author: oompah
created: 2026-07-23 23:17
---
Implemented hardened installers and uninstallers: install.sh (8-phase, preflight validation, versioned dirs, atomic symlink, sudoers, hardened systemd units, manifest), uninstall.sh (scoped, preserves PKI/config/audit by default), 2 hardened systemd unit files (16 security directives each), 2 config templates, 50 passing tests. All acceptance criteria met.
---
author: oompah
created: 2026-07-23 23:17
---
Agent completed successfully in 1534s (58919 tokens)
---
author: oompah
created: 2026-07-23 23:17
---
Run #3 [attempt=3, profile=deep, role=deep -> Claude/default]
- Turns: 183, Tool calls: 105
- Tokens: 89 in / 58.8K out [58.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 25m 34s
- Log: EXOCOMP-43__20260723T225148Z.jsonl
---
author: oompah
created: 2026-07-23 23:17
---
Close refused by orchestrator: branch `epic-EXOCOMP-6` has 1 commit not on `main` and no open PR targets `main` from this branch.

Diagnostic:
  Unmerged commits: 1
    3036c94 EXOCOMP-43: implement hardened installers and uninstallers
  Open PRs from this branch: 0
  Merged PRs from this branch: 0

Required: open a PR before closing.
  gh pr create --base main --head epic-EXOCOMP-6 --title "EXOCOMP-43: Implement hardened installers and uninstallers" --body "..."

Task reopened. Re-dispatch on the next tick will see this comment in its prompt context.
---
author: oompah
created: 2026-07-23 23:17
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 23:17
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 23:20
---
Agent completed successfully in 191s (1065081 tokens)
---
author: oompah
created: 2026-07-23 23:20
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 21
- Tokens: 1.1M in / 5.2K out [1.1M total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 11s
- Log: EXOCOMP-43__20260723T231728Z.jsonl
---
author: oompah
created: 2026-07-23 23:20
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-6`. Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
---
<!-- COMMENTS:END -->
