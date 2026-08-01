---
id: EXOCOMP-190
type: task
status: Ready to Integrate
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
updated_at: '2026-08-01T14:05:28.326223Z'
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
oompah.agent_run_id: 87bd83ec-6baf-4890-b8c9-bbd76c65d7c4
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-190
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-190
  head_sha: 93a832c3fbe51efa38fe05cf3646c1f15e57bb45
  submitted_at: '2026-08-01T14:04:40.056152+00:00'
  updated_at: '2026-08-01T14:04:40.056152+00:00'
oompah.task_costs:
  total_input_tokens: 796282
  total_output_tokens: 14907
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 796282
      output_tokens: 14907
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 795292
    output_tokens: 14641
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:52:32.115709+00:00'
  - profile: default
    model: haiku
    input_tokens: 990
    output_tokens: 266
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:05:27.050046+00:00'
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
author: oompah
created: 2026-08-01 13:52
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 13:52
---
Focus: Software Engineer
---
author: oompah
created: 2026-08-01 13:54
---
**Understanding & Plan**

Task: Implement `exocomp.service.inventory` skill for enabled service discovery.

**Key Requirements:**
1. Read-only skill that lists enabled/enabled-runtime systemd services
2. Return: Type, RemainAfterExit, condition result, load state, active state, substate
3. Exclude: completed oneshots, static, indirect, disabled, masked, generated, exocomp-node.service
4. Mark failed conditions as not_applicable
5. No shell invocation; bounded output; per-subprocess timeout
6. Tests with command fixtures for all states/edge cases

**Planned Approach:**
1. Create `Exocomp.Node.Skills.ServiceInventory` skill module following the behavior contract
2. Create a new collector or extend `Exocomp.Node.Collectors.Systemd` to query systemd for enabled units
3. Implement filtering logic to exclude unwanted unit types
4. Build comprehensive tests with injected systemctl fixtures for:
   - Multiple enabled service states
   - Enabled-runtime services
   - All exclusion cases (oneshot, disabled, masked, etc.)
   - Timeout handling
   - Malformed output
   - Output truncation

**Key implementation details:**
- Use `systemctl list-units --type=service --state=enabled` or similar fixed argv
- Query properties via `systemctl show` with fixed property list
- Handle the condition result field (mark failed as not_applicable)
- Implement output size cap + timeout as seen in existing Systemd collector

Next: Explore existing code to determine best collector approach.
---
author: oompah
created: 2026-08-01 14:04
---
**Discovery & Implementation Complete**

**Code Added:**
1. `Exocomp.Node.Collectors.ServiceInventory` — New collector that:
   - Lists enabled/enabled-runtime services via `systemctl list-unit-files`
   - Queries properties (Type, RemainAfterExit, Condition, ConditionResult, UnitFileState, LoadState, ActiveState, SubState)
   - Filters to exclude: static, indirect, disabled, masked, generated units, exocomp-node.service, completed oneshots
   - Marks failed conditions as 'not_applicable'
   - Enforces output size limits and per-service timeouts
   - No shell invocation; uses System.cmd/3 with fixed argv

2. `Exocomp.Node.Skills.ServiceInventory` — New skill handler that:
   - Executes ServiceInventory collector with configurable timeout
   - Returns artifact with normalized observation data
   - Takes no required parameters

3. Dispatcher update to register skill as 'exocomp.service.inventory'

**Tests Added:** 25 comprehensive test cases covering:
- Basic skill execution and artifact structure
- Service filtering (inclusions/exclusions for all unit types)
- Failed condition marking as not_applicable
- Timeout handling at both skill and collector levels
- Malformed output handling
- Output size limit enforcement
- Empty service list handling
- All required properties returned

**Test Results:** All tests passing (511 passed, 0 failed)
---
author: oompah
created: 2026-08-01 14:04
---
Implemented exocomp.service.inventory skill for enabled long-running systemd service discovery with comprehensive filtering, property collection, and test coverage
---
author: oompah
created: 2026-08-01 14:05
---
**Completion**

**Delivered:**
- Exocomp.Node.Collectors.ServiceInventory: Production collector for enabled service inventory
- Exocomp.Node.Skills.ServiceInventory: Read-only A2A skill handler
- Skills.Dispatcher registration for 'exocomp.service.inventory'
- 25 comprehensive test cases with fixtures for all acceptance criteria

**Acceptance Criteria Met:**
✓ Returns enabled and enabled-runtime services with Type, RemainAfterExit, Condition, LoadState, ActiveState, SubState
✓ Excludes completed oneshots, static, indirect, disabled, masked, generated, exocomp-node.service
✓ Failed conditions marked as not_applicable
✓ Output size validated and per-service timeout enforced
✓ No shell invocation; uses System.cmd with fixed argv
✓ Tests include all states, timeouts, malformed output, truncation

**Code Quality:**
- All 511 tests passing
- No warnings in new code
- Follows existing patterns and conventions
- Comprehensive error handling

Branch: epic-EXOCOMP-185--task-EXOCOMP-190
Commit: 93a832c3
---
author: oompah
created: 2026-08-01 14:05
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 0, Tool calls: 54
- Tokens: 990 in / 266 out [1.3K total]
- Cost: $0.0000
- Exit: terminated, Duration: 12m 41s
- Log: EXOCOMP-190__20260801T135252Z.jsonl
---
<!-- COMMENTS:END -->
