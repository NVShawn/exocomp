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
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T21:06:39.885357Z'
updated_at: '2026-07-23T21:31:56.155420Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: cb20a695-acf4-45da-af24-e389935863a5
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 23
  total_output_tokens: 5667
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 23
      output_tokens: 5667
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 23
    output_tokens: 5667
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:28:57.115019+00:00'
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
author: oompah
created: 2026-07-23 21:28
---
Focus handoff: duplicate_detector

Outcome: No duplicate found. EXOCOMP-70 is a distinct implementation child of EXOCOMP-29 and should proceed to implementation.

Evidence: Reviewed all sibling tasks under EXOCOMP-29 in full, including all comments and task states:
- EXOCOMP-69 (Merged): fixture service daemon script at test/fixtures/exocomp_fixture/bin/exocomp-fixture — distinct scope (the ExecStart target binary)
- EXOCOMP-70 (this task): systemd unit file + install.sh + cleanup.sh — distinct scope
- EXOCOMP-71 (Open): ExUnit integration tests — distinct scope
- EXOCOMP-72 (Merged): docs/testing-systemd-fixture.md — distinct scope (full test environment doc)

Searched for: systemd, fixture, install, cleanup, exocomp-fixture across all task files and plans.

Note on README: EXOCOMP-70 description mentions 'Add a README in test/fixtures/exocomp_fixture/ noting VM or privileged-container requirement.' The README already exists from EXOCOMP-69 (test/fixtures/exocomp_fixture/README.md) and covers the fixture daemon. The feature agent should check if VM/privileged-container requirement is already noted there and either update it or confirm it is covered. Given EXOCOMP-72 already created docs/testing-systemd-fixture.md with full detail, the README may just need a brief note and pointer.

Current state of test/fixtures/exocomp_fixture/:
- bin/exocomp-fixture (executable Python 3 daemon, from EXOCOMP-69, health on 127.0.0.1:8877, state in /run/exocomp-fixture/)
- README.md (exists, from EXOCOMP-69)
- test/test_fixture.py (Python unit tests, from EXOCOMP-69)

Missing deliverables (what EXOCOMP-70 must create):
1. test/fixtures/exocomp_fixture/exocomp-fixture.service — systemd unit with Restart=on-failure, StartLimitBurst=3, WorkingDirectory, RuntimeDirectory=exocomp-fixture, ExecStartPost health probe
2. test/fixtures/exocomp_fixture/install.sh — idempotent: copy unit to /etc/systemd/system/, copy bin to /usr/local/bin/, systemctl daemon-reload, enable, start; requires root; safe to repeat
3. test/fixtures/exocomp_fixture/cleanup.sh — idempotent: stop, disable, remove only /etc/systemd/system/exocomp-fixture.service, /usr/local/bin/exocomp-fixture, /run/exocomp-fixture/; no-op on clean system

The docs/testing-systemd-fixture.md (EXOCOMP-72) already references make fixture-install and make fixture-cleanup targets — the feature agent should also add these Makefile targets.

Remaining work/risks:
- The feature agent must create the 3 files above
- Should also add Makefile targets fixture-install and fixture-cleanup (referenced in docs but not yet defined)
- All scripts must be non-interactive (use -f flags, etc.)
- Branch is currently behind main — MUST run git pull before starting work
- The worktree is on branch epic-EXOCOMP-29, but the task targets epic-EXOCOMP-4. Running git pull already fast-forwarded to the latest main (which now includes EXOCOMP-69 and EXOCOMP-72 merged work). The feature agent should check if they are on the correct branch before committing.

Recommended next focus: devops (or feature)
---
author: oompah
created: 2026-07-23 21:28
---
Agent completed successfully in 147s (5690 tokens)
---
author: oompah
created: 2026-07-23 21:28
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 44, Tool calls: 28
- Tokens: 23 in / 5.7K out [5.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 27s
- Log: EXOCOMP-70__20260723T212634Z.jsonl
---
author: oompah
created: 2026-07-23 21:29
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:29
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:29
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-07-23 21:30
---
Understanding (DevOps): Creating the systemd unit file, install.sh, and cleanup.sh for the exocomp-fixture service.

Current state:
- Branch epic-EXOCOMP-29 is up to date with origin/main
- test/fixtures/exocomp_fixture/bin/exocomp-fixture exists (Python 3 daemon from EXOCOMP-69)
- test/fixtures/exocomp_fixture/README.md exists but needs VM/privileged-container note
- docs/testing-systemd-fixture.md already references make fixture-install and fixture-cleanup targets

Plan:
1. Create branch EXOCOMP-70 from current HEAD
2. Create test/fixtures/exocomp_fixture/exocomp-fixture.service (systemd unit with Restart=on-failure, StartLimitBurst=3, RuntimeDirectory, ExecStartPost health probe)
3. Create test/fixtures/exocomp_fixture/install.sh (idempotent, requires root, copies unit + binary, daemon-reload, enable, start)
4. Create test/fixtures/exocomp_fixture/cleanup.sh (idempotent, stop/disable/remove only fixture resources, no-op on clean system)
5. Update README.md with VM/privileged-container requirement note
6. Add Makefile targets fixture-install and fixture-cleanup
---
author: oompah
created: 2026-07-23 21:31
---
Discovery: Reviewed existing codebase state.

Key findings:
- bin/exocomp-fixture listens on 127.0.0.1:8877/health, uses /run/exocomp-fixture as state dir (via FIXTURE_STATE_DIR env var)
- docs/testing-systemd-fixture.md references make fixture-install and fixture-cleanup targets that do not yet exist in the Makefile
- README.md existed but had no VM/privileged-container note
- The docs use 'exocomp_fixture' (underscore) in some places, but the actual binary and task spec use 'exocomp-fixture' (dash) — following the task spec and binary naming

Files to create:
1. exocomp-fixture.service — health probe via ExecStartPost (curl loop with 5s timeout), RuntimeDirectory=exocomp-fixture, Restart=on-failure, StartLimitBurst=3
2. install.sh — copies binary + unit, daemon-reload, enable, start/restart; requires root
3. cleanup.sh — stops/disables/removes only fixture resources; no-op on clean system
---
<!-- COMMENTS:END -->
