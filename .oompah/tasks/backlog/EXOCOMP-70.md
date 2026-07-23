---
id: EXOCOMP-70
type: task
status: Backlog
priority: null
title: Create systemd unit file and fixture installer/cleanup scripts
parent: EXOCOMP-29
children: []
blocked_by:
- EXOCOMP-69
labels: []
assignee: null
created_at: '2026-07-23T21:06:39.885357Z'
updated_at: '2026-07-23T21:07:02.645018Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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

