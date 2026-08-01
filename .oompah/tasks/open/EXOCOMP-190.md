---
id: EXOCOMP-190
type: task
status: Open
priority: 1
title: Implement enabled long-running systemd service discovery
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-187
labels: []
assignee: null
created_at: '2026-07-30T21:37:00.068929Z'
updated_at: '2026-08-01T13:52:35.466682Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-190
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: efeecae4d6a578a0eabde567f98eca502fb2e14c34dc6df060c7ebb67e9012f4
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:52:32.116194+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector  \nDuplicate preflight verdict: no_duplicate\
    \  \nMatches: none  \nEvidence: No `.oompah/tasks` records or matching active\
    \ task descriptions are present. Closest reviewed item, EXOCOMP-187, is a plan-only\
    \ architecture update and does not duplicate this implementation."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 817ae23f-78ad-42be-b8b0-c88725df78ef
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-190
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-190
  base_branch: epic-EXOCOMP-185
  base_sha: 6742aa13ef4dc7e3dafa1582cebb5e4550ba9a72
  updated_at: '2026-08-01T13:46:00.810756+00:00'
oompah.task_costs:
  total_input_tokens: 795292
  total_output_tokens: 14641
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 795292
      output_tokens: 14641
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 795292
    output_tokens: 14641
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:52:32.115709+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-190__20260801T134604Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-185--task-EXOCOMP-190
    source_sha: 6742aa13ef4dc7e3dafa1582cebb5e4550ba9a72
    completed_at: '2026-08-01T13:52:32.146188+00:00'
---
## Summary

Plan: plans/mission-control.md, automatic service path.

Deliverable: Add the read-only exocomp.service.inventory node skill using fixed systemctl argv and bounded output.

Acceptance criteria:
- Return enabled and enabled-runtime service units with Type, RemainAfterExit, condition result, load state, active state, and substate.
- Exclude completed oneshots, static, indirect, disabled, masked, generated units, and exocomp-node.service from the expected-running set.
- Mark a failed systemd condition as not_applicable.
- Validate output size and timeout each subprocess without invoking a shell.

Tests: Use injected command fixtures for every included and excluded state, timeout, malformed output, and output truncation; run make test.

Out of scope: Scheduling discovery, health incidents, application probes, and restart behavior.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:45
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:46
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:52
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 2, Tool calls: 21
- Tokens: 795.3K in / 14.6K out [809.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 6m 35s
- Log: EXOCOMP-190__20260801T134604Z.jsonl
---
<!-- COMMENTS:END -->
