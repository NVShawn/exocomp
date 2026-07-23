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
- needs:feature
assignee: null
created_at: '2026-07-23T19:12:02.637514Z'
updated_at: '2026-07-23T23:00:40.078312Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 52f1d2f0-03a3-48c7-823d-566b52d2ef3a
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 1125239
  total_output_tokens: 6758
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1125239
      output_tokens: 6758
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
<!-- COMMENTS:END -->
