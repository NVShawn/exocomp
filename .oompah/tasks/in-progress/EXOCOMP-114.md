---
id: EXOCOMP-114
type: chore
status: In Progress
priority: 1
title: Recover omitted M6 governance, builder, qualification, and bundle work
parent: EXOCOMP-110
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-25T17:58:22.988216Z'
updated_at: '2026-07-25T19:18:43.962913Z'
work_branch: epic-EXOCOMP-110
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 2c055333-8232-48ba-a723-f1ede6e97f8d
oompah.work_branch: epic-EXOCOMP-110
---
## Summary

Recover stranded EXOCOMP-41, EXOCOMP-44, EXOCOMP-65, EXOCOMP-67, and EXOCOMP-68 deliverables onto the EXOCOMP-110 shared recovery branch based on current main. Integrate licensing/governance checks, pinned multi-architecture builders, release dependency inspection, reproducibility qualification, offline bundle assembly, SBOM/provenance/signing/verification tooling, documentation, fixtures, and tests. Preserve hardened installer work already on main and run all release/compliance Make targets.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 19:03
---
Verification environment hint: the completed EXOCOMP-112 recovery proved the pinned Make gates work through the already-running Podman service. Create an empty ignored/temporary storage config, then run with CONTAINERS_STORAGE_CONF=<that-file>, XDG_RUNTIME_DIR=/home/shedwards/.oompah/tmp/<task>-runtime, DOCKER_HOST=, and CONTAINER_ENGINE='podman --remote --url unix:///run/user/1000/podman/podman.sock'. For make test, also pass _CONTAINER_USER_FLAG=--userns=keep-id. Remove the temporary config/runtime before committing. This passed fmt-check, lint, all 1,487 tests, both release builds, and smoke tests on EXOCOMP-112.
---
author: oompah
created: 2026-07-25 19:18
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 19:18
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-25 19:18
---
Understanding: I am the Duplicate Investigator for EXOCOMP-114 ('Recover omitted M6 governance, builder, qualification, and bundle work'). This task aims to recover deliverables from EXOCOMP-41, EXOCOMP-44, EXOCOMP-65, EXOCOMP-67, and EXOCOMP-68 onto the EXOCOMP-110 shared recovery branch. My role is to determine whether this work is already covered by an existing task before any implementation proceeds. I will search for duplicate tasks now.
---
<!-- COMMENTS:END -->
