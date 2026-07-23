---
id: EXOCOMP-25
type: feature
status: In Progress
priority: 1
title: Implement unprivileged systemd executor and exact sudoers policy
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-21
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:10:11.402376Z'
updated_at: '2026-07-23T22:23:28.288984Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: d5ff8a15-8a42-45a7-8e8a-88c55bd0b799
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 79
  total_output_tokens: 2395
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 79
      output_tokens: 2395
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 52
    output_tokens: 1803
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:16:55.975515+00:00'
  - profile: standard
    model: unknown
    input_tokens: 27
    output_tokens: 592
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:23:26.603314+00:00'
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Implement unprivileged systemd executor and exact sudoers policy.

Implementation
Implement action execution under a dedicated unprivileged account; generate exact per-service sudoers entries; map installed action IDs to fixed executable/argv/environment/timeouts; serialize per target; capture bounded output; invoke post-action verification; expose no generic command.

Testing
Test service allow-list, unknown units, shell metacharacters, argv/environment injection, executable path changes, timeout, oversized output, sudo denial, concurrent targets, and generated policy snapshots.

Acceptance Criteria
- [ ] Node release does not run as root.
- [ ] Only installed allow-listed services can reach systemctl.
- [ ] No request/model field becomes shell syntax or arbitrary argv.
- [ ] Privilege policy is minimal and deterministic.
- [ ] Focused executor tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 22:14
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:15
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:16
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed. EXOCOMP-25 is a unique task with no coverage overlap in the existing task graph.

Evidence reviewed:
- All M3 siblings (EXOCOMP-22 through EXOCOMP-28) and parent epic EXOCOMP-3:
  - EXOCOMP-22: Policy selection engine (In Progress) — distinct scope
  - EXOCOMP-23: Approval issuance (Open) — distinct scope
  - EXOCOMP-24: Approval replay prevention (Open) — distinct scope
  - EXOCOMP-26: Bounded system-log cleanup action (Open) — covers the specific cleanup action, not executor infrastructure
  - EXOCOMP-27: Lifecycle integration (Open) — A2A integration, not executor
  - EXOCOMP-28: M3 verification (Open) — integration tests, not implementation

- EXOCOMP-10 (Done): Linux and systemd diagnostic *collectors* — reads metrics from systemctl show, read-only, no privilege elevation. Distinct from EXOCOMP-25 which is about *action execution* (restart, remediation) under a dedicated unprivileged account via exact sudoers entries.

- EXOCOMP-70/EXOCOMP-72 (Done): systemd fixture unit file and test environment docs — fixture infrastructure, not executor implementation.

- No code exists yet in apps/ for an executor, sudoers generator, or privilege separation layer.

Relevant design reference: plans/milestone-3-safety-validation.md section 'Privilege Separation' (M3-CRIT-7) and 'Action Catalog' — EXOCOMP-25 implements the executor side of the policy engine.

Remaining work and risks:
1. Implement Elixir modules for the restricted executor: map installed action IDs to fixed executable/argv/environment/timeouts; no generic command exposure.
2. Generate per-service exact sudoers entries for configured allow-listed services only.
3. Serialize per-target; capture bounded output.
4. Invoke post-action verification hooks.
5. Test service allow-list, unknown units, shell metacharacters, argv/environment injection, executable path changes, timeout, oversized output, sudo denial, concurrent targets, and generated sudoers snapshots.
6. Ensure the node runtime account is not root.
7. Blocker: EXOCOMP-21 (type system) is Done — unblocked. EXOCOMP-22 (policy selection) is In Progress but executor can be built independently and wired later.

Recommended next focus: feature
---
author: oompah
created: 2026-07-23 22:16
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 34
- Tokens: 52 in / 1.8K out [1.9K total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 57s
- Log: EXOCOMP-25__20260723T221501Z.jsonl
---
author: oompah
created: 2026-07-23 22:17
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:17
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-23 22:23
---
Run #2 [attempt=2, profile=standard, role=standard -> Claude/default]
- Turns: 0, Tool calls: 16
- Tokens: 27 in / 592 out [619 total]
- Cost: $0.0000
- Exit: terminated, Duration: 6m 17s
- Log: EXOCOMP-25__20260723T221711Z.jsonl
---
<!-- COMMENTS:END -->
