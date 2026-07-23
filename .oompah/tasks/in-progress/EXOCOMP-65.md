---
id: EXOCOMP-65
type: feature
status: In Progress
priority: 2
title: Pin multi-architecture OTP release builders
parent: EXOCOMP-42
children: []
blocked_by:
- EXOCOMP-7
labels:
- focus-complete:duplicate_detector
- needs:devops
assignee: null
created_at: '2026-07-23T21:06:03.498156Z'
updated_at: '2026-07-23T21:16:35.782353Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 6c439d58-2ec6-4091-9cb3-34c49e6e67d5
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 571275
  total_output_tokens: 10304
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 571275
      output_tokens: 10304
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 571258
    output_tokens: 3322
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:13:01.463638+00:00'
  - profile: standard
    model: unknown
    input_tokens: 17
    output_tokens: 6982
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:16:28.249067+00:00'
---
## Summary

Create digest-pinned Linux amd64 and arm64 builder definitions for the supported glibc baseline and the Elixir/OTP versions established by EXOCOMP-7. Add non-interactive Make targets/scripts that select an explicit target architecture, build from a clean checkout, and fail clearly when the host lacks the required container/emulation capability. Keep builder inputs immutable and record the exact builder image digest/toolchain versions for later manifests. Add focused tests or static validation for pinning, supported-architecture mapping, and non-interactive invocation. Acceptance: both target builders can produce the node and coordinator Mix releases with ERTS enabled; no floating image/package/toolchain inputs remain; relevant Make quality gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:11
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:11
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:13
---
Agent completed successfully in 91s (574580 tokens)
---
author: oompah
created: 2026-07-23 21:13
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 9
- Tokens: 571.3K in / 3.3K out [574.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 31s
- Log: EXOCOMP-65__20260723T211136Z.jsonl
---
author: oompah
created: 2026-07-23 21:13
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-42`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:13
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:13
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:15
---
Duplicate screening: No duplicate found. EXOCOMP-65 is a unique child task deliberately created by the EXOCOMP-42 epic planner (see EXOCOMP-42 comment #27-29).

Closest candidates reviewed:
- **EXOCOMP-7** (Done): Establishes Elixir 1.20.2/OTP 28.5.0.3 with a SINGLE digest-pinned Alpine builder (sha256:53d8a7a0caf...). EXOCOMP-65 scope is distinct: it needs SEPARATE digest-pinned builders for BOTH amd64 and arm64 using a glibc baseline, plus architecture-selection Make targets, capability checks, and arch-mapping validation.
- **EXOCOMP-42** (Open, parent): Covers the full reproducible artifact epic; EXOCOMP-65 is its first child and first dependency in the chain 65 -> 66 -> 67 -> 68.
- **EXOCOMP-68** (Open): Qualification task that *consumes* EXOCOMP-65 artifacts; does not duplicate the builder pinning scope.

Evidence: `git show origin/EXOCOMP-7:Makefile` confirms EXOCOMP-7 uses a single-arch Alpine (musl) builder without `--platform` flag. EXOCOMP-65 must add glibc-based amd64+arm64 builders with explicit `--platform linux/amd64` and `--platform linux/arm64` and their respective digest pins.
---
author: oompah
created: 2026-07-23 21:16
---
Focus handoff: duplicate_detector

1. **Outcome:** No duplicate confirmed. EXOCOMP-65 is unique — the first child of EXOCOMP-42, created by the epic planner to deliver digest-pinned amd64 and arm64 builder definitions with glibc baseline.

2. **Relevant files, commands, evidence, decisions:**
   - `origin/EXOCOMP-7:Makefile` — current single-arch Alpine (musl) builder: `hexpm/elixir:1.20.2-erlang-28.5.0.3-alpine-3.24.1@sha256:53d8a7a0...` — EXOCOMP-65 must pivot to glibc images and add explicit `--platform` for both architectures
   - `plans/milestone-6-release.md` — specifies glibc-based Linux (x86_64 and aarch64) as supported targets (M6-CRIT-2)
   - EXOCOMP-42 comment #27 confirms dependency chain: EXOCOMP-7 → EXOCOMP-65 → EXOCOMP-66 → EXOCOMP-67 → EXOCOMP-68
   - Current worktree is on branch `epic-EXOCOMP-42` — implementing agent must create/checkout a `EXOCOMP-65` branch to land commits on the right branch
   - `hexpm/elixir` Docker Hub has Debian and Ubuntu variants for glibc: e.g. `1.20.2-erlang-28.5.0.3-debian-bullseye-20250317-slim` or Ubuntu Jammy

3. **Remaining work and risks:**
   - Pin separate digest-tagged `hexpm/elixir` glibc images for linux/amd64 AND linux/arm64 (two different digests)
   - Add Make targets: `build-amd64`, `build-arm64` (and optionally `build-all-arch`) with `--platform linux/amd64` or `--platform linux/arm64` passed to the container engine
   - Add a capability check script that detects binfmt/QEMU support and fails clearly on missing emulation
   - Record toolchain versions (Elixir, OTP, glibc baseline, image digest) in an immutable builder lockfile/vars for manifest use later (EXOCOMP-66)
   - Add static validation tests for: image digest format, supported-architecture list, and non-interactive flag presence in Make targets
   - Risk: Coordinator depends on EXOCOMP-65 being done before EXOCOMP-66 can package the archives
   - Risk: QEMU emulation for arm64 on amd64 hosts must be confirmed (binfmt_misc setup)
   - Risk: Alpine (musl) OTP releases do not start on glibc-only hosts — the glibc pivot is essential for the acceptance criteria in M6-CRIT-2

4. **Recommended next focus:** `devops` — this is a Docker/container builder infrastructure task (image selection, platform flags, capability detection, Makefile wiring).
---
author: oompah
created: 2026-07-23 21:16
---
Agent completed successfully in 188s (6999 tokens)
---
author: oompah
created: 2026-07-23 21:16
---
Run #2 [attempt=2, profile=standard, role=standard -> Claude/default]
- Turns: 33, Tool calls: 23
- Tokens: 17 in / 7.0K out [7.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 8s
- Log: EXOCOMP-65__20260723T211325Z.jsonl
---
author: oompah
created: 2026-07-23 21:16
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
<!-- COMMENTS:END -->
