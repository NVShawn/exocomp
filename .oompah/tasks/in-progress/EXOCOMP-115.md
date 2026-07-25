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
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-25T17:58:24.080768Z'
updated_at: '2026-07-25T20:12:52.647304Z'
work_branch: epic-EXOCOMP-110
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: bd604beb-43ad-42b0-b835-f81518db0056
oompah.work_branch: epic-EXOCOMP-110
oompah.task_costs:
  total_input_tokens: 23
  total_output_tokens: 5329
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 23
      output_tokens: 5329
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 23
    output_tokens: 5329
    cost_usd: 0.0
    recorded_at: '2026-07-25T20:12:23.039310+00:00'
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
author: oompah
created: 2026-07-25 20:12
---
Focus handoff: duplicate_detector

1. **Outcome:** No duplicate confirmed. EXOCOMP-115 is a unique task that owns implementation of five scopes that were never written and never delivered, despite being falsely marked Merged in their parent epics.

2. **Relevant files, commands, and evidence:**
   - Source tasks and their specifications:
     - EXOCOMP-31: Automatic recovery of an already-failed service (plans/milestone-4-service-recovery.md). Status: Needs Human.
     - EXOCOMP-45: Installation, PKI, policy, and operations guides (plans/milestone-6-release.md). Status: Needs Human.
     - EXOCOMP-46: Upgrade/rollback/backup/removal docs and tests (plans/milestone-6-release.md). Status: Needs Human.
     - EXOCOMP-47: M6 clean-host release qualification (plans/milestone-6-release.md). Status: Needs Human. Previous duplicate screening completed (focus-complete:duplicate_detector label on EXOCOMP-47); unique scope confirmed.
     - EXOCOMP-66: Deterministic OTP archives and identity manifests. Status: Needs Human. EXOCOMP-114 comment #16 explicitly delegates deterministic COOKIE/archive work here.
   - Working branch: epic-EXOCOMP-110 (shared recovery branch with EXOCOMP-111-114 already landed)
   - Verification environment: Podman service at unix:///run/user/1000/podman/podman.sock; CONTAINERS_STORAGE_CONF=<tmp-config>, XDG_RUNTIME_DIR=/home/shedwards/.oompah/tmp/EXOCOMP-115-runtime, DOCKER_HOST=, CONTAINER_ENGINE='podman --remote --url unix:///run/user/1000/podman/podman.sock', _CONTAINER_USER_FLAG=--userns=keep-id for make test. 1,564 tests currently pass (per EXOCOMP-114 verification).
   - EXOCOMP-114 note: releases/COOKIE determinism check currently fails because EXOCOMP-66 deterministic archive work was explicitly delegated to EXOCOMP-115.

3. **Remaining work and risks:**
   - EXOCOMP-31: Implement automatic failed-service recovery path in Elixir. The state machine/policy/audit/executor infrastructure exists from earlier work. Need: failed-service allow-list check, one restart per episode, systemd+health stability verification, terminal artifacts, cooldown on failure. Cover all 8 acceptance tests from the task description.
   - EXOCOMP-45: Write installation/PKI/policy/operations guides in docs/. Cover: supported hosts, online/offline install, coordinator init, offline-root, fingerprint distribution, enrollment, renewal/revocation/rotation, inventory, diagnostics, model sizing, service allow-lists, sudoers, approvals, data classification, bounded cleanup, audit retention. Run markdown/link checks.
   - EXOCOMP-46: Document and test upgrade/rollback/backup/removal. Cover: side-by-side upgrade, validation, health-gated switch, automatic rollback, compatibility limits, PKI/state backup/restore, troubleshooting, safe removal. 8 lifecycle tests.
   - EXOCOMP-47: M6 clean-host qualification scripts/docs. Smoke-test on amd64 (arm64 requires binfmt/QEMU which is not available). Document signed evidence collection procedure.
   - EXOCOMP-66: Deterministic OTP release archives (normalized ordering/ownership/timestamps/modes using tag epoch) and machine-readable manifests per archive (product/version/arch, commit, builder digest, dependency lock identity, exact build command, file inventory, SHA-256). This resolves the releases/COOKIE nondeterminism that currently blocks EXOCOMP-114's reproducibility check.
   - Risk: EXOCOMP-31 may need access to existing service-recovery state machine modules; check what is already on the branch before writing new code.

4. **Recommended next focus:** feature (all five scopes require new code and/or documentation implementation).
---
author: oompah
created: 2026-07-25 20:12
---
Agent completed successfully in 130s (5352 tokens)
---
author: oompah
created: 2026-07-25 20:12
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 31, Tool calls: 20
- Tokens: 23 in / 5.3K out [5.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 10s
- Log: EXOCOMP-115__20260725T201016Z.jsonl
---
author: oompah
created: 2026-07-25 20:12
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-25 20:12
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-25 20:12
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-25 20:12
---
Understanding: I am a Software Engineer agent taking over from the duplicate_detector. My task is to implement five scopes that were falsely marked Merged without delivery: EXOCOMP-31 (automatic failed-service recovery), EXOCOMP-45 (operator/PKI/policy guides), EXOCOMP-46 (upgrade/rollback/backup/removal lifecycle + tests), EXOCOMP-47 (clean-host release qualification), and EXOCOMP-66 (deterministic OTP archives + build identity manifests). I will first explore the codebase to understand existing patterns, then implement each scope in order, run the relevant make gates, and close the task.
---
author: oompah
created: 2026-07-25 20:12
---
Security constraint for EXOCOMP-66: resolve releases/COOKIE nondeterminism without deriving or shipping a predictable/fixed production cookie. Prefer omitting secret-bearing COOKIE content from published deterministic artifacts and generating/provisioning a cryptographically random cookie at install/first-start (or requiring RELEASE_COOKIE) while keeping the complete-content qualification honest. Add regressions proving two packaged artifacts are byte-identical, no reusable secret is embedded, and installed instances receive usable non-predictable cookie material. Also keep live arm64 qualification explicitly unverified on this amd64 host; do not report offline structural coverage as a live arm64 pass.
---
<!-- COMMENTS:END -->
