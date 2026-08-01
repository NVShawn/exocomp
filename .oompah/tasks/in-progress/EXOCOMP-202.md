---
id: EXOCOMP-202
type: task
status: In Progress
priority: 1
title: Package the profile helper with exact sudo authorization
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-201
labels: []
assignee: null
created_at: '2026-07-30T21:38:33.244906Z'
updated_at: '2026-08-01T15:34:16.089729Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-202
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: c2919d420c4e11b546e9bf47bda6a138e512fc2fb07a47de176fd011c267510e
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:19:06.092058+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: EXOCOMP-201 implements the helper and explicitly excludes installer
    integration; EXOCOMP-203 only consumes the helper in recovery. EXOCOMP-186 is
    the parent epic, while EXOCOMP-207 is a later broad-repair roadmap. No active
    task duplicates packaging and exact sudo authorization.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: afab5f1a-b14b-4fbb-bb39-d1199ad5cf09
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-202
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-202
  base_branch: epic-EXOCOMP-186
  base_sha: 8e3debd59e5a3ca32307b8a0c2e8c219456cb58c
  updated_at: '2026-08-01T15:31:09.037094+00:00'
oompah.task_costs:
  total_input_tokens: 1054271
  total_output_tokens: 5174
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 1054271
      output_tokens: 5174
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 1054271
    output_tokens: 5174
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:19:06.091083+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-202__20260801T141709Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-186--task-EXOCOMP-202
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:19:06.142043+00:00'
---
## Summary

Plan: plans/mission-control.md, profile helper packaging.

Deliverable: Install the profile helper as a root-owned executable and grant the node account one exact no-argument sudo command for it.

Acceptance criteria:
- Release archives include both supported architectures and record the helper in manifests and SBOMs.
- Installer sets root ownership and non-writable executable permissions.
- Sudoers grants only the exact helper path with no arguments; direct systemctl wildcard privileges are not added.
- Upgrade, dry-run, rollback, and uninstall handle the helper and sudoers entry idempotently.
- visudo validation failure rolls back the policy installation.

Tests: Extend installer, packaging, tamper-detection, upgrade, uninstall, and sudoers tests; run make test-installer, make test-release-packaging, and make test-bundle.

Out of scope: Helper parsing logic, recovery policy, and Ceph health collection.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:17
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:17
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:19
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 28
- Tokens: 1.1M in / 5.2K out [1.1M total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 6s
- Log: EXOCOMP-202__20260801T141709Z.jsonl
---
author: oompah
created: 2026-08-01 15:31
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 15:31
---
Focus: Software Engineer
---
author: oompah
created: 2026-08-01 15:33
---
## Understanding

Task: Package the profile_action_helper with exact sudo authorization

Interpretation:
- Include the profile_action_helper binary (already implemented in EXOCOMP-201) in release bundles for both amd64 and arm64
- Install it as root-owned executable in a standard location (/opt/exocomp-helper or similar)
- Grant the exocomp-node service account a sudo entry for EXACTLY the helper path with no arguments
- visudo must validate the sudoers entry; validation failure rolls back installation
- Handle idempotently: upgrade, dry-run, rollback, and uninstall should all handle the helper properly
- Extend installer, packaging, tamper-detection, upgrade, uninstall, and sudoers tests
- Tests: make test-installer, make test-release-packaging, make test-bundle

Key findings:
- profile_action_helper.c is implemented and has native tests via test-profile-action-helper target
- install.sh already has framework for sudoers policies with render_sudoers function
- Makefile already has build and test targets for the helper

Planned approach:
1. Determine helper installation path and ownership
2. Modify bundle assembly to include profile_action_helper binaries
3. Modify install.sh to install helper with root ownership and proper permissions
4. Add a dedicated sudo entry for the helper (separate from service allow-list)
5. Modify uninstall.sh to remove the helper and sudoers entry
6. Extend tests for installer, packaging, and sudoers validation
7. Verify all test targets pass
---
author: oompah
created: 2026-08-01 15:34
---
## Discovery

Key findings:
1. profile_action_helper.c is already implemented in apps/exocomp_node/priv/
   - Validates stdin-only request protocol with strict parsing
   - Supports exactly: Ceph profile v1, restart_failed_daemon action
   - Validates target units (ceph-osd@N, ceph-mon@id, ceph-crash, etc.)
   - Executes systemctl show/restart with direct argv (no shell)
   - Has native tests via make test-profile-action-helper

2. Build system already has:
   - Makefile target: build-profile-action-helper (creates _build/profile-action-helper/profile_action_helper)
   - Test target: test-profile-action-helper

3. Action catalog (Exocomp.Node.ActionCatalog):
   - Uses /usr/bin/sudo to invoke actions
   - Validates service names against regex before sudo invocation
   - install.sh already has render_sudoers() function for creating sudo policies
   - Tests already verify sudoers format, no wildcards, exact entries

Implementation plan:
1. Modify assemble-bundle.sh to build and include profile_action_helper binary for each architecture
2. Modify install.sh to:
   - Install helper to /opt/exocomp/bin/profile-action-helper (root-owned, non-writable)
   - Create a dedicated sudo entry granting exocomp-node EXACTLY this helper with no arguments
   - Include helper path in manifest for proper cleanup
   - Handle visudo validation; fail+rollback if validation fails
3. Modify uninstall.sh to remove the helper binary and sudoers entry
4. Extend installer tests to verify profile_action_helper installation, ownership, permissions, and sudoers entry

Next steps:
- Implement bundle assembly changes
- Implement installer changes  
- Implement uninstaller changes
- Implement and extend tests
---
<!-- COMMENTS:END -->
