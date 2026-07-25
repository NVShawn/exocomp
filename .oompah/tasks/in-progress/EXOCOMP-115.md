---
id: EXOCOMP-115
type: feature
status: In Progress
priority: 1
title: Implement exocomp work falsely marked Merged without delivery
parent: EXOCOMP-110
children: []
blocked_by:
- EXOCOMP-111
- EXOCOMP-112
- EXOCOMP-113
- EXOCOMP-114
labels: []
assignee: null
created_at: '2026-07-25T17:58:24.080768Z'
updated_at: '2026-07-25T20:11:39.116111Z'
work_branch: epic-EXOCOMP-110
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 2456d083-5dda-40f6-b2b0-eab84c413b5e
oompah.work_branch: epic-EXOCOMP-110
---
## Summary

Implement the scopes that never landed or never ran: EXOCOMP-31 automatic already-failed service recovery, EXOCOMP-45 operator/PKI/policy guides, EXOCOMP-46 upgrade/rollback/backup/removal lifecycle and tests, EXOCOMP-47 clean-host release qualification, and EXOCOMP-66 deterministic node/coordinator archives and build identity manifests. Build on the recovered EXOCOMP-110 branch, satisfy the original acceptance criteria, and run all relevant Make targets.

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
created: 2026-07-25 20:10
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 20:10
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-25 20:10
---
Understanding: EXOCOMP-115 is an umbrella recovery task requesting implementation of five scopes previously marked Merged without actual delivery: EXOCOMP-31 (automatic already-failed service recovery), EXOCOMP-45 (operator/PKI/policy guides), EXOCOMP-46 (upgrade/rollback/backup/removal lifecycle and tests), EXOCOMP-47 (clean-host release qualification), and EXOCOMP-66 (deterministic node/coordinator archives and build identity manifests). My role is Duplicate Investigator: I will search for any existing task that already covers this same recovery scope before considering implementation.
---
author: oompah
created: 2026-07-25 20:11
---
Discovery: Duplicate screening found NO confirmed duplicate. EXOCOMP-115 is the unique, canonical implementation task for five never-delivered scopes within the EXOCOMP-110 recovery epic.

Reviewed candidates:
- EXOCOMP-111 (Done): Recovers M1 A2A codec/fixture stranded commits — different scope, different source tasks (EXOCOMP-49, 51)
- EXOCOMP-112 (Done): Recovers M5 benchmark/sampler stranded commits — different scope (EXOCOMP-28, 33, 56)
- EXOCOMP-113 (Done): Recovers M3/M4 acceptance and fault-injection stranded commits — different scope (EXOCOMP-53, 65, etc.)
- EXOCOMP-114 (Done): Recovers M6 governance/builder/qualification/bundle stranded commits (EXOCOMP-41, 44, 65, 67, 68) — different scope. Comment #16 in EXOCOMP-114 explicitly confirms: 'EXOCOMP-66 deterministic archive packaging is explicitly assigned to downstream recovery EXOCOMP-115.'
- EXOCOMP-116 (Open): Downstream verification task, different purpose

Source tasks (EXOCOMP-31, 45, 46, 47, 66): All in 'Needs Human' status with explicit comments pointing to EXOCOMP-115 as the vehicle to implement their never-delivered work.

Key distinction: EXOCOMP-111–114 recover *stranded commits* (work was written but never landed); EXOCOMP-115 must *implement from scratch* the work that was never written for these five tasks.

EXOCOMP-115 is not a duplicate. Proceeding to focus handoff.
---
<!-- COMMENTS:END -->
