---
id: EXOCOMP-72
type: task
status: In Progress
priority: null
title: Document VM/privileged-container requirements for systemd fixture tests
parent: EXOCOMP-29
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T21:06:59.701752Z'
updated_at: '2026-07-23T21:17:06.611350Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 7fab8c25-f25a-4aec-8085-b715e817e85e
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 45
  total_output_tokens: 1576
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 45
      output_tokens: 1576
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 45
    output_tokens: 1576
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:15:40.042344+00:00'
---
## Summary

Create documentation explaining how to run the M4 systemd fixture integration tests. Add docs/testing-systemd-fixture.md.

Content must cover:
1. Why systemd tests cannot run in a standard CI container — systemd requires PID 1 or a privileged cgroup environment
2. Supported test environments: recommended VM setup (e.g. QEMU/KVM with systemd-based Linux) and/or privileged Docker/Podman container approach (e.g. --privileged with systemd as init)
3. Step-by-step setup instructions for at least one supported environment
4. How to run the fixture tests: make target, ExUnit tag filter, expected output
5. How to verify non-fixture services are untouched after a test run
6. Cleanup procedure after testing

Also add a brief note in the top-level README.md or AGENTS.md pointing to this doc.

This task can be worked in parallel with EXOCOMP-69, EXOCOMP-70, and EXOCOMP-71 since it is documentation only. Reference: plans/milestone-4-service-recovery.md, section 'Reference Fixture'.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:13
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:13
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:15
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate found. EXOCOMP-72 is a unique, dedicated documentation task.

**Evidence reviewed:**
- Searched all task files and plans for: systemd, fixture, testing-systemd, VM, privileged, document
- Read EXOCOMP-29 (parent), EXOCOMP-69, EXOCOMP-70, EXOCOMP-71 (siblings) in full including all comments
- EXOCOMP-29 was explicitly decomposed by an Epic Planner into 4 children: EXOCOMP-69 (daemon script), EXOCOMP-70 (unit file/installer/cleanup), EXOCOMP-71 (ExUnit tests), EXOCOMP-72 (documentation). See EXOCOMP-29 comment #31.
- Closest candidate for overlap: EXOCOMP-70 mentions 'Add a README in test/fixtures/exocomp_fixture/ noting VM or privileged-container requirement' — but that is a brief in-fixture README, not the full docs/testing-systemd-fixture.md that EXOCOMP-72 requires. Distinct scope.
- No other task in the tracker covers creating docs/testing-systemd-fixture.md with step-by-step VM/privileged-container setup, make targets, ExUnit tag filters, expected output, verification, and cleanup procedures.

**Relevant files:**
- plans/milestone-4-service-recovery.md — Section 'Reference Fixture' defines what the documentation must explain
- plans/fixture-design.md — Design decisions that the documentation should reference (health port 8877, mode file, fixture resource paths)
- docs/README.md, README.md, AGENTS.md — Locations where a pointer to the new doc should be added

**Remaining work:**
- Create docs/testing-systemd-fixture.md covering all 6 required content areas
- Add a brief pointer in README.md or AGENTS.md
- Commit and push

**Risks:**
- None identified; this is pure documentation with no code dependencies
- EXOCOMP-70 and EXOCOMP-71 are not yet done, so some make targets/ExUnit tags may not exist yet — the doc agent should note expected targets based on plans and EXOCOMP-71 description rather than verifying live

**Recommended next focus:** docs
---
author: oompah
created: 2026-07-23 21:15
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 31
- Tokens: 45 in / 1.6K out [1.6K total]
- Cost: $0.0000
- Exit: terminated, Duration: 2m 19s
- Log: EXOCOMP-72__20260723T211330Z.jsonl
---
author: oompah
created: 2026-07-23 21:15
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:15
---
Focus: Technical Writer
---
author: oompah
created: 2026-07-23 21:17
---
**Understanding & Plan**

This is a pure documentation task. The previous agent confirmed no duplicates exist. My role is to create docs/testing-systemd-fixture.md covering all 6 required areas, and add a pointer to it in README.md.

Key context gathered:
- plans/milestone-4-service-recovery.md defines the fixture: crashable systemd service with health endpoint, mode controls (active/failed/degraded/flapping/restart-failure), and clean installer/cleanup
- Health port: 8877 (from fixture design); mode file controls behavior; fixture resources are isolated from operator services
- Sibling tasks EXOCOMP-69/70/71 are not yet complete, so make targets/ExUnit tags referenced in the doc are based on the plans (test-fixture make target, @tag :systemd_fixture ExUnit filter)
- Existing make test target runs in a container — systemd fixture tests require a real systemd environment (VM or --privileged container) and cannot use the standard container runner

Plan: create docs/testing-systemd-fixture.md then add a two-line pointer in README.md, commit and push.
---
<!-- COMMENTS:END -->
