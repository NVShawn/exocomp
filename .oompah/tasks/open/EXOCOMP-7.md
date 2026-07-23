---
id: EXOCOMP-7
type: feature
status: Open
priority: 1
title: Scaffold the Elixir umbrella and quality gates
parent: EXOCOMP-1
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
- needs:feature
assignee: null
created_at: '2026-07-23T19:08:52.964005Z'
updated_at: '2026-07-23T19:25:15.736600Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: dbb624f6-9d2c-4d3a-8088-1875f36f7953
oompah.work_branch: epic-EXOCOMP-1
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Scaffold the Elixir umbrella and quality gates.

Implementation
Create the Elixir 1.20/OTP 28 umbrella with shared core/protocol, node, and coordinator applications; configure separate node and coordinator releases with ERTS; pin exact toolchain and builder versions; replace placeholder Make targets with non-interactive build, test, lint, format, and format-check targets.

Testing
Run every Make target from a clean checkout; add ExUnit smoke tests that start each application in test mode and build both releases.

Acceptance Criteria
- [ ] Clean checkout builds without host Elixir when using the pinned builder.
- [ ] Both releases contain ERTS and start in test mode.
- [ ] make build, make test, make lint, and make fmt-check pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 19:20
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 19:20
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 19:23
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 19:23
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 19:25
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate found. EXOCOMP-7 is a unique, foundational task.

**Evidence reviewed:**
- Searched all 47 tasks across .oompah/tasks (in-progress, open) via the oompah/state branch
- EXOCOMP-7 is a child of EXOCOMP-1 (epic: M1 Prototype Elixir node agent)
- Other M1 children (EXOCOMP-8 through EXOCOMP-13) all depend on EXOCOMP-7 being completed first; none overlap with umbrella scaffold scope
- M2-M6 tasks (EXOCOMP-14 through EXOCOMP-47) cover coordinator, safety, recovery, performance, and release work — none involve creating the initial Elixir umbrella or make targets
- Closest candidates reviewed: EXOCOMP-42 (Build reproducible OTP release artifacts, M6) and EXOCOMP-1 (parent epic) — neither covers the same implementation scope

**Remaining work:**
- Create the Elixir 1.20/OTP 28 umbrella with core/protocol, node, and coordinator apps
- Configure node and coordinator releases with ERTS included
- Pin toolchain and builder image digests
- Replace placeholder Makefile targets with working build, test, lint, format, and fmt-check targets
- Add ExUnit smoke tests for each app starting in test mode and releasing both builds

**Risks:**
- This is the blocker for EXOCOMP-8 and EXOCOMP-9 (and transitively all other M1 tasks); delays cascade
- Builder image pinning requires Docker/container registry access at implementation time
- Elixir/OTP version availability in environment needs to be confirmed

**Recommended next focus:** feature (or devops) — this is a scaffolding/build infrastructure task that creates the Elixir umbrella, configures Mix releases, and sets up Make quality gates
---
<!-- COMMENTS:END -->
