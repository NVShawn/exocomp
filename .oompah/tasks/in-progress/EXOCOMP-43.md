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
labels: []
assignee: null
created_at: '2026-07-23T19:12:02.637514Z'
updated_at: '2026-07-23T22:47:40.518177Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 589411ab-72b1-4625-b50a-81164d065314
oompah.work_branch: epic-EXOCOMP-6
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
<!-- COMMENTS:END -->
