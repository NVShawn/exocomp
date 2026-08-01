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
updated_at: '2026-08-01T15:31:11.263742Z'
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
<!-- COMMENTS:END -->
