---
id: EXOCOMP-42
type: feature
status: Open
priority: 2
title: Build reproducible amd64 and arm64 OTP release artifacts
parent: EXOCOMP-6
children:
- EXOCOMP-65
- EXOCOMP-66
- EXOCOMP-67
- EXOCOMP-68
blocked_by:
- EXOCOMP-7
labels:
- focus-complete:duplicate_detector
- focus-complete:epic_planner
- needs:devops
assignee: null
created_at: '2026-07-23T19:12:01.640063Z'
updated_at: '2026-07-23T21:14:43.631749Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: cbc45827-610d-4368-98a0-0e57ca7d9f36
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 1067519
  total_output_tokens: 13945
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1067519
      output_tokens: 13945
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 29
    output_tokens: 6890
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:43:50.347840+00:00'
  - profile: default
    model: unknown
    input_tokens: 495920
    output_tokens: 3121
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:57:52.048717+00:00'
  - profile: standard
    model: unknown
    input_tokens: 571570
    output_tokens: 3934
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:04:07.400459+00:00'
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Build reproducible amd64 and arm64 OTP release artifacts.

Implementation
Create pinned target builders for node/coordinator releases with ERTS; produce versioned archives and manifests; inspect runtime dynamic dependencies; record source/toolchain/dependency identity; ensure build commands are non-interactive.

Testing
Build twice for each architecture and compare reproducible fields; start both releases in clean target containers without Elixir/Erlang; test wrong-architecture and missing-runtime diagnostics.

Acceptance Criteria
- [ ] Both architectures produce node/coordinator archives with ERTS.
- [ ] Clean targets start without development tooling.
- [ ] Runtime dependencies are documented and inspected.
- [ ] Artifacts carry exact source/build identity.
- [ ] Release-build tests pass.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:26
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:26
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:41
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:41
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:41
---
Understanding: Investigating EXOCOMP-42 for duplicates. The issue requests building reproducible amd64 and arm64 OTP release artifacts with ERTS-bundled archives, manifests, runtime dependency inspection, and build identity recording. Searching existing tasks for overlap.
---
author: oompah
created: 2026-07-23 20:43
---
Discovery: Reviewed all 47+ tasks in the project. No duplicate of EXOCOMP-42 found.

Closest candidates reviewed:
- **EXOCOMP-7** (Done): "Scaffold the Elixir umbrella and quality gates" — Foundational umbrella setup with ERTS-inclusive releases, but scoped to creating the Mix project structure and initial Make targets, not to building architecture-specific release archives, manifests, runtime dependency inspection, or build identity recording. The EXOCOMP-7 duplicate investigator already noted EXOCOMP-42 as distinct (comment #5 on EXOCOMP-7).
- **EXOCOMP-35** (Backlog): "Build the reproducible benchmark harness" — Shares the keyword 'reproducible' but is a M5 performance benchmark infrastructure task under parent EXOCOMP-5, unrelated to release artifact production.
- **EXOCOMP-44** (Open): "Assemble signed offline bundles, SBOMs, and provenance" — A downstream M6 sibling that is explicitly *blocked by* EXOCOMP-42; covers bundle assembly after artifacts exist, not artifact building.
- **EXOCOMP-41**, **EXOCOMP-43**, **EXOCOMP-45**, **EXOCOMP-46**, **EXOCOMP-47** — All M6 siblings with distinct scopes (licensing, installers, documentation, qualification).

EXOCOMP-42 is a unique task with its own well-defined scope: pinned amd64/arm64 builder containers, versioned OTP archives, build manifests, runtime dependency inspection, and source/toolchain identity recording.
---
author: oompah
created: 2026-07-23 20:43
---
Focus handoff: duplicate_detector

1. **Outcome:** No duplicate confirmed. EXOCOMP-42 is a unique task.

2. **Evidence reviewed:**
   - Scanned all task files on `origin/oompah/state/proj-c260b117` (47 tasks across all statuses)
   - Checked EXOCOMP-7 (Done, M1 scaffold) — confirmed distinct scope; EXOCOMP-7's own duplicate_detector already noted EXOCOMP-42 as a different task
   - Checked EXOCOMP-35 (Backlog, M5 benchmark harness) — shares 'reproducible' keyword only, different domain
   - Checked all 6 M6 siblings (EXOCOMP-41–47) — all have distinct scopes; EXOCOMP-43 and EXOCOMP-44 are downstream blockers of this task
   - Reviewed EXOCOMP-6 (parent epic) and EXOCOMP-29, EXOCOMP-10 (other in-progress tasks) — no overlap
   - Reviewed backlog EXOCOMP-48–60 — unrelated (A2A protocol, bench scaffolding, node PKI)
   - Relevant plan file: `plans/milestone-6-release.md` — confirms this task maps to M6-CRIT-2 and M6-CRIT-8

3. **Remaining work:**
   - Create pinned amd64 and arm64 builder Docker targets for node/coordinator OTP releases
   - Produce versioned archives and manifests with source/toolchain/dependency identity
   - Inspect and document runtime dynamic dependencies
   - Write tests: build twice per arch, compare reproducible fields; start in clean containers; test wrong-arch and missing-runtime diagnostics
   - Run `make` quality gates and release/documentation tests
   - EXOCOMP-7 blocker is now Done, so work can proceed

4. **Recommended next focus:** `devops` (CI/CD, Docker builders, release pipeline) or `feature` (the Elixir release configuration and test scaffold)
---
author: oompah
created: 2026-07-23 20:43
---
Agent completed successfully in 160s (6919 tokens)
---
author: oompah
created: 2026-07-23 20:43
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 51, Tool calls: 38
- Tokens: 29 in / 6.9K out [6.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 40s
- Log: EXOCOMP-42__20260723T204112Z.jsonl
---
author: oompah
created: 2026-07-23 20:43
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 20:47
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 20:47
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-07-23 20:52
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:52
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 20:57
---
Agent completed successfully in 336s (499041 tokens)
---
author: oompah
created: 2026-07-23 20:57
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 8
- Tokens: 495.9K in / 3.1K out [499.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 5m 36s
- Log: EXOCOMP-42__20260723T205218Z.jsonl
---
author: oompah
created: 2026-07-23 20:57
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-6`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:02
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:02
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 21:04
---
Agent completed successfully in 120s (575504 tokens)
---
author: oompah
created: 2026-07-23 21:04
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 9
- Tokens: 571.6K in / 3.9K out [575.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 0s
- Log: EXOCOMP-42__20260723T210213Z.jsonl
---
author: oompah
created: 2026-07-23 21:04
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-6`. Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
author: oompah
created: 2026-07-23 21:04
---
Retrying (attempt #2, agent: deep)
---
author: oompah
created: 2026-07-23 21:04
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 21:05
---
Understanding: Decomposing EXOCOMP-42 into independently deliverable children covering pinned multi-architecture builders, deterministic release packaging/identity, runtime dependency inspection, and clean-target/reproducibility diagnostics. I will preserve scope boundaries with EXOCOMP-43 installers and EXOCOMP-44 signed bundles/SBOMs, wire child dependencies, then return the epic to Backlog for implementation.
---
author: oompah
created: 2026-07-23 21:06
---
Discovery: EXOCOMP-42 currently has no children. plans/milestone-6-release.md maps it to M6-CRIT-2 plus the reproducible build-identity portion of M6-CRIT-8. The current branch is still the project skeleton, so children must depend on EXOCOMP-7 and remain implementation-ready after the umbrella/release configs land. Downstream EXOCOMP-43 and EXOCOMP-44 already depend on this epic, confirming installers, signatures, SBOMs, and offline bundle assembly are out of scope.
---
author: oompah
created: 2026-07-23 21:07
---
Implementation: Created four child tasks: EXOCOMP-65 pinned amd64/arm64 builders; EXOCOMP-66 deterministic node/coordinator archives and build-identity manifests; EXOCOMP-67 ELF/NIF runtime dependency inspection and documentation; EXOCOMP-68 clean-target, wrong-architecture, missing-runtime, and double-build reproducibility qualification. Dependencies are EXOCOMP-65 <- EXOCOMP-7, EXOCOMP-66 <- EXOCOMP-65, EXOCOMP-67 <- EXOCOMP-66, and EXOCOMP-68 <- EXOCOMP-66/67.
---
author: oompah
created: 2026-07-23 21:07
---
Verification: Re-read EXOCOMP-42 and all four new children through the tracker. The children are linked to the parent, start in Backlog at priority 2, carry independent context/acceptance criteria/tests, cover every stated acceptance criterion, and explicitly exclude EXOCOMP-43 installer and EXOCOMP-44 signing/SBOM/offline-bundle scope. No repository files changed, so code quality gates are not applicable to this planning-only focus.
---
author: oompah
created: 2026-07-23 21:07
---
Completion: Epic decomposition is complete. EXOCOMP-65 through EXOCOMP-68 collectively cover pinned builders, four ERTS-inclusive architecture/product archives, reproducible identity manifests, inspected/documented runtime dependencies, and the required clean-target/negative/repeat-build test matrix. The parent is ready to return to Backlog while its children are implemented.
---
author: oompah
created: 2026-07-23 21:07
---
Focus handoff: epic_planner\n\n1. Outcome: Decomposed EXOCOMP-42 into four actionable children (EXOCOMP-65 through EXOCOMP-68) with acceptance criteria and dependencies.\n2. Evidence/decisions: plans/milestone-6-release.md M6-CRIT-2 and reproducible identity from M6-CRIT-8 define scope; EXOCOMP-43 owns installers and EXOCOMP-44 owns signatures/SBOMs/offline bundles. Dependency chain: 7 -> 65 -> 66 -> 67 -> 68, with 68 also explicitly consuming 66 artifacts.\n3. Remaining work/risks: Implement the children in order; multi-architecture execution may require binfmt/QEMU or native runners, and runtime-library baselines must be pinned consistently with builder glibc.\n4. Recommended next focus: devops for EXOCOMP-65, followed by feature/test work for EXOCOMP-66 through EXOCOMP-68.
---
author: oompah
created: 2026-07-23 21:07
---
Run #3 [attempt=3, profile=deep, role=deep -> Codex/default]
- Turns: 0, Tool calls: 9
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 2m 48s
- Log: EXOCOMP-42__20260723T210438Z.jsonl
---
<!-- COMMENTS:END -->
