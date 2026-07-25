---
id: EXOCOMP-114
type: chore
status: In Progress
priority: 1
title: Recover omitted M6 governance, builder, qualification, and bundle work
parent: EXOCOMP-110
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
- needs:chore
assignee: null
created_at: '2026-07-25T17:58:22.988216Z'
updated_at: '2026-07-25T19:19:58.727756Z'
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
author: oompah
created: 2026-07-25 19:19
---
Focus handoff: duplicate_detector

1. **Outcome:** No duplicate found. EXOCOMP-114 is a unique, canonical recovery task with no overlap with any other existing task.

2. **Evidence reviewed:**
   - EXOCOMP-111 (Done): Recovers M1 A2A codec/fixture work — distinct scope
   - EXOCOMP-112 (Done): Recovers M5 benchmark host-profile/sampler work — distinct scope
   - EXOCOMP-113 (Done): Recovers M3/M4 acceptance and fault-injection work — distinct scope
   - EXOCOMP-115 (Open): Implements EXOCOMP-31/45/46/47/66 — explicitly different source tasks, distinct scope
   - EXOCOMP-116 (Open): Verification step, downstream of recovery — distinct scope
   - EXOCOMP-41, 44, 65, 67, 68: All in 'Needs Human' state with documented work done on old branches that never landed on main. All contain explicit comments: 'use recovery task EXOCOMP-114 to integrate and verify this task's omitted deliverables on main.'
   - No other task in the tracker covers recovery of EXOCOMP-41 (licensing/governance), EXOCOMP-44 (signed offline bundles/SBOMs/provenance), EXOCOMP-65 (pinned multi-arch builders), EXOCOMP-67 (OTP release runtime dependency inspection), or EXOCOMP-68 (multi-arch qualification/reproducibility) onto the EXOCOMP-110 branch.

3. **Remaining work:**
   - Cherry-pick or re-implement deliverables from EXOCOMP-41 (Apache-2.0 LICENSE, governance files, compliance checks/tests), EXOCOMP-44 (bundle assembly scripts, SBOM generation, provenance, tamper-detection, signing), EXOCOMP-65 (builders.lock, build-releases.sh, capability checks, arch-select Make targets), EXOCOMP-67 (inspect-release-deps.sh, runtime-baseline.lock, dep-report.json, docs/runtime-dependencies.md), and EXOCOMP-68 (test-release-matrix.sh, test-clean-container.sh, docs/release-qualification.md) — integrating all onto the epic-EXOCOMP-110 branch, resolving conflicts with hardened installer work already on main, and running all release/compliance Make targets.
   - Key files to check on old branches: EXOCOMP-41 branch had commit 886a6ab; EXOCOMP-65/67/68 work was on epic-EXOCOMP-42; EXOCOMP-44 work never landed (agent run terminated).
   - Verification environment: use Podman service as documented in prior comments (CONTAINERS_STORAGE_CONF, XDG_RUNTIME_DIR, DOCKER_HOST=, CONTAINER_ENGINE='podman --remote --url unix:///run/user/1000/podman/podman.sock').

4. **Recommended next focus:** chore (integration/recovery of M6 governance, builder, qualification, and bundle deliverables)
---
<!-- COMMENTS:END -->
