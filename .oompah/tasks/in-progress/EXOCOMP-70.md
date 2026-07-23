---
id: EXOCOMP-70
type: task
status: In Progress
priority: null
title: Create systemd unit file and fixture installer/cleanup scripts
parent: EXOCOMP-29
children: []
blocked_by:
- EXOCOMP-69
labels: []
assignee: null
created_at: '2026-07-23T21:06:39.885357Z'
updated_at: '2026-07-23T21:28:22.650567Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 5f72f1e8-1b66-4ac6-b760-0652d514d678
oompah.work_branch: epic-EXOCOMP-4
---
## Summary

Create the systemd service unit definition and the install/cleanup shell scripts for the M4 fixture service.

Deliverables:
1. test/fixtures/exocomp_fixture/exocomp-fixture.service — systemd unit file targeting the fixture daemon. Should include: restart policy suitable for testing (e.g. Restart=on-failure, StartLimitBurst=3), WorkingDirectory, RuntimeDirectory=exocomp-fixture, and a health probe via ExecStartPost or a separate check.
2. test/fixtures/exocomp_fixture/install.sh — idempotent installer that: copies the unit file to /etc/systemd/system/, copies the service script to /usr/local/bin/, runs systemctl daemon-reload, then systemctl enable and start the fixture service. Must require root/sudo. Must be safe to run repeatedly.
3. test/fixtures/exocomp_fixture/cleanup.sh — idempotent cleanup that stops, disables, and removes only fixture-owned resources (/etc/systemd/system/exocomp-fixture.service, /usr/local/bin/exocomp-fixture, /run/exocomp-fixture/). Must not touch any non-fixture systemd units or files. Must be safe to run on a clean system (no-op when fixture isn't installed).

All scripts must be non-interactive (no prompts). Add a README in test/fixtures/exocomp_fixture/ noting VM or privileged-container requirement.

Depends on: EXOCOMP-69 (fixture service script). Reference: plans/milestone-4-service-recovery.md.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:26
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:26
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:28
---
Understanding (duplicate screening): EXOCOMP-70 is the systemd unit/installer/cleanup slice of parent feature EXOCOMP-29. Investigating whether any existing task covers the same scope before implementation begins.
---
<!-- COMMENTS:END -->
