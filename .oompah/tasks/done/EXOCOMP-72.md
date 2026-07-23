---
id: EXOCOMP-72
type: task
status: Done
priority: null
title: Document VM/privileged-container requirements for systemd fixture tests
parent: EXOCOMP-29
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T21:06:59.701752Z'
updated_at: '2026-07-23T21:26:15.156531Z'
work_branch: EXOCOMP-72
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/3
review_number: '3'
merged_at: null
oompah.agent_run_id: d6ad4144-c584-4fec-ab4a-b04d2699eba6
oompah.work_branch: EXOCOMP-72
oompah.task_costs:
  total_input_tokens: 75
  total_output_tokens: 10295
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 75
      output_tokens: 10295
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 45
    output_tokens: 1576
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:15:40.042344+00:00'
  - profile: standard
    model: unknown
    input_tokens: 30
    output_tokens: 8719
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:19:29.016961+00:00'
oompah.review_url: https://github.com/NVShawn/exocomp/pull/3
oompah.review_number: '3'
oompah.target_branch: main
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
author: oompah
created: 2026-07-23 21:18
---
**Implementation**

Created docs/testing-systemd-fixture.md (331 lines) covering all 6 required areas:

1. Why systemd tests cannot run in standard CI — explains PID 1, cgroup v2, and D-Bus requirements that standard unprivileged containers lack
2. Supported environments — privileged Podman/Docker container (recommended for dev) and QEMU/KVM VM (recommended for pre-merge validation), with a Mermaid comparison diagram
3. Step-by-step setup for both environments (container gets 4 steps, VM gets 3 steps)
4. How to run tests — make fixture-install, MIX_ENV=test mix test --only systemd_fixture, make test-fixture, expected output with scenario table
5. How to verify non-fixture services — diff-based pre/post check using systemctl list-units filtered by name prefix
6. Cleanup — make fixture-cleanup steps enumerated, plus container/VM teardown

Also updated:
- docs/README.md — added entry in Contents list
- README.md — added 3-line pointer paragraph under Development section

Note: make fixture-install, make fixture-cleanup, and make test-fixture targets are forward references to work in EXOCOMP-70/71; the doc notes this where relevant.
---
author: oompah
created: 2026-07-23 21:19
---
**Completion**

Delivered: docs/testing-systemd-fixture.md (331 lines, all 6 required areas covered) plus pointer updates in README.md and docs/README.md.

Committed on branch EXOCOMP-72 and pushed to origin. Branch is up to date with origin/EXOCOMP-72.

No code changes — documentation only. No tests required. EXOCOMP-70 and EXOCOMP-71 are siblings that will deliver the referenced make targets (fixture-install, fixture-cleanup, test-fixture); the doc notes those are forthcoming from those tasks.
---
author: oompah
created: 2026-07-23 21:19
---
Created docs/testing-systemd-fixture.md covering all 6 required areas (why CI fails, supported environments, setup steps, running tests, verification, cleanup). Added pointers in README.md and docs/README.md. Committed and pushed on branch EXOCOMP-72.
---
author: oompah
created: 2026-07-23 21:19
---
Agent completed successfully in 213s (8749 tokens)
---
author: oompah
created: 2026-07-23 21:19
---
Run #2 [attempt=2, profile=standard, role=standard -> Claude/default]
- Turns: 51, Tool calls: 36
- Tokens: 30 in / 8.7K out [8.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 33s
- Log: EXOCOMP-72__20260723T211558Z.jsonl
---
author: oompah
created: 2026-07-23 21:19
---
Close refused by orchestrator: branch `epic-EXOCOMP-4` has 1 commit not on `main` and no open PR targets `main` from this branch.

Diagnostic:
  Unmerged commits: 1
    5096f79 EXOCOMP-29: Add fixture design document and decompose into child tasks
  Open PRs from this branch: 0
  Merged PRs from this branch: 0

Required: open a PR before closing.
  gh pr create --base main --head epic-EXOCOMP-4 --title "EXOCOMP-72: Document VM/privileged-container requirements for systemd fixture tests" --body "..."

Task reopened. Re-dispatch on the next tick will see this comment in its prompt context.
---
author: oompah
created: 2026-07-23 21:25
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:25
---
Focus: Technical Writer
---
author: oompah
created: 2026-07-23 21:25
---
**Understanding & Resumption**

Previous agent completed all documentation work (docs/testing-systemd-fixture.md, README.md, docs/README.md) and pushed to origin/EXOCOMP-72. The task close was refused because no PR existed targeting main. Resuming to open a PR and close the task.
---
author: oompah
created: 2026-07-23 21:26
---
**Completion**

All work was delivered by the previous agent run:
- Created \`docs/testing-systemd-fixture.md\` (331 lines) covering all 6 required areas: why CI containers fail, supported environments, step-by-step setup, running tests with make target and ExUnit tag filter, verifying non-fixture services, and cleanup
- Updated \`docs/README.md\` (Contents entry) and \`README.md\` (pointer under Development)
- Committed and pushed to origin/EXOCOMP-72

This run opened PR #3 (https://github.com/NVShawn/exocomp/pull/3) targeting main, which was the missing step that caused the previous close to be refused. Task is now ready to close.
---
<!-- COMMENTS:END -->
