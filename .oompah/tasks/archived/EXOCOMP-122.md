---
id: EXOCOMP-122
type: feature
status: Archived
priority: 2
title: Add a shipped-artifact M5 performance qualification gate
parent: EXOCOMP-117
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
- focus-complete:docs
assignee: null
created_at: '2026-07-26T03:58:34.780590Z'
updated_at: '2026-08-03T12:07:41.429494Z'
work_branch: epic-EXOCOMP-117
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 606e8961-8c5e-49c8-9abb-36203f03c7a5
oompah.work_branch: epic-EXOCOMP-117
oompah.task_costs:
  total_input_tokens: 1395209
  total_output_tokens: 9129
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1395209
      output_tokens: 9129
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 1395139
    output_tokens: 6928
    cost_usd: 0.0
    recorded_at: '2026-07-26T06:28:41.099313+00:00'
  - profile: default
    model: unknown
    input_tokens: 70
    output_tokens: 2201
    cost_usd: 0.0
    recorded_at: '2026-07-26T06:34:15.438453+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-4de73f5cde60: '2026-08-03T12:07:38.656189+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-122
    target_state: Archived
    evidence_fingerprint: 3cb5e28a6c715c3b3890888e22e551e3c7f4e73063c1243dfc2ba8534ef65d0c
    audit_ids:
    - audit-b76f85d6c2eb
    kind: result
    applied: true
    retired_at: '2026-08-03T12:07:38.656201+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-122
    audit_id: audit-b76f85d6c2eb
    attempt_id: attempt-4de73f5cde60
    target_state: Archived
    evidence_fingerprint: 3cb5e28a6c715c3b3890888e22e551e3c7f4e73063c1243dfc2ba8534ef65d0c
    status: Archived
    audit_ids:
    - audit-b76f85d6c2eb
    applied: false
    created_at: '2026-08-03T12:07:38.656223+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-b76f85d6c2eb
    project_id: proj-c260b117
    task_id: EXOCOMP-122
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 3cb5e28a6c715c3b3890888e22e551e3c7f4e73063c1243dfc2ba8534ef65d0c
    attempts:
    - version: 1
      attempt_id: attempt-4de73f5cde60
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 3cb5e28a6c715c3b3890888e22e551e3c7f4e73063c1243dfc2ba8534ef65d0c
      created_at: '2026-08-03T12:06:21.877309+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-03T12:06:21.877309+00:00'
      branch_key: epic-EXOCOMP-117
      verdict: pass
      completed_at: '2026-08-03T12:07:38.656016+00:00'
      ended_at: '2026-08-03T12:07:38.656016+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-08-03T12:01:06.599442+00:00'
    updated_at: '2026-08-03T12:07:38.656016+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-4de73f5cde60
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 3cb5e28a6c715c3b3890888e22e551e3c7f4e73063c1243dfc2ba8534ef65d0c
    created_at: '2026-08-03T12:06:21.877309+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-03T12:06:21.877309+00:00'
    branch_key: epic-EXOCOMP-117
---
## Summary

Context
The v0.1.0-rc.2 qualification could find only bench-llama-short, which uses a fake server. There is no documented Make target or versioned baseline that measures the installed node, coordinator, and real llama-server release payload for M5 acceptance.

Implementation
Add short and full Make targets that run the M5 harness against shipped release artifacts, record pinned host profiles and versioned amd64 and arm64 baselines, separate BEAM control-plane usage from llama.cpp, and enforce documented regression budgets with clear failed-metric output. Integrate the full target into release qualification docs and evidence collection.

Testing
Cover harness configuration, artifact identity, host-profile capture, baseline selection, threshold pass and fail behavior, missing metric failure, and result reproducibility. Exercise the short target in CI and the full target on clean amd64 and full-system arm64 guests using the exact candidate artifacts.

Acceptance Criteria
- Documented Make targets run the real shipped processes rather than fake-only fixtures.
- Versioned baselines and raw evidence identify artifact and host profile.
- A threshold regression fails with the exact metric and budget.
- Both architecture qualification runs satisfy every applicable M5 criterion.
- Focused tests and relevant Make gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-26 06:24
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-26 06:24
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-26 06:24
---
Understanding: This focus is limited to duplicate screening. I will search existing task records and project documentation for M5 performance gates, shipped-artifact benchmarks, architecture baselines, and release qualification work; I will inspect every plausible task in full before deciding whether EXOCOMP-122 duplicates it. No implementation changes will be made in this run.
---
author: oompah
created: 2026-07-26 06:27
---
Discovery: Duplicate screening found no confirmed duplicate. Reviewed EXOCOMP-5, EXOCOMP-35, EXOCOMP-38, EXOCOMP-40, EXOCOMP-47, EXOCOMP-112, EXOCOMP-117, and EXOCOMP-123 in full where tracker history exists. EXOCOMP-35/38 delivered harness components and a fake-server short target; EXOCOMP-112 recovered host-profile/sampler pieces; EXOCOMP-40 nominally called for baselines/gates but has no delivery comments and its shipped-artifact outcome was disproven by signed v0.1.0-rc.2 evidence. EXOCOMP-47 and EXOCOMP-117 explicitly establish EXOCOMP-122 as a corrective remediation child, while EXOCOMP-123 is the downstream requalification task.
---
author: oompah
created: 2026-07-26 06:27
---
Implementation: No code or documentation was changed, as required by the duplicate_detector focus. The worktree remains clean; this run only inspected repository evidence and tracker records and will add the focus-complete routing label.
---
author: oompah
created: 2026-07-26 06:28
---
Verification: Repository checks corroborate a distinct undelivered gap: make help exposes only bench-llama-short and labels it as requiring no real llama-server; the focused workload tests use Bench.Test.FakeLlamaServer; docs/release-evidence/v0.1.0-rc.2 records M5 FAIL because no shipped-artifact Make gate or baseline exists. No tests were run because this screening made no source changes. git status is clean and up to date with origin/epic-EXOCOMP-117.
---
author: oompah
created: 2026-07-26 06:28
---
Focus handoff: duplicate_detector — (1) Outcome: no duplicate confirmed; EXOCOMP-122 is the remediation vehicle for an M5 shipped-artifact gap proven after earlier M5 tasks were merged. (2) Evidence: reviewed tracker records EXOCOMP-5/35/38/40/47/112/117/123; Makefile:181 defines only fake-compatible bench-llama-short; apps/bench/test/bench/workload/llama_inference_test.exs explicitly uses FakeLlamaServer; docs/release-evidence/v0.1.0-rc.2/README.md:52 records the missing shipped-artifact gate and baseline. EXOCOMP-40 is the closest title/scope match, but contains no implementation history and predates the signed failure evidence; EXOCOMP-117 intentionally created this distinct corrective child. (3) Remaining work/risks: implement real installed node/coordinator/llama-server short and full targets, artifact and host identity capture, versioned amd64/arm64 baselines, deterministic metric/budget failure behavior, CI/docs/evidence integration, and tests. Full verification requires exact candidate artifacts on clean amd64 and full-system arm64 guests; emulated performance-only failures remain inconclusive under existing qualification policy. (4) Recommended next focus: feature.
---
author: oompah
created: 2026-07-26 06:28
---
Completion: Duplicate investigation is complete. No duplicate was archived, no repository changes were made, and focus-complete:duplicate_detector is set. EXOCOMP-122 remains In Progress for a fresh feature-focused implementation run using the recorded handoff.
---
author: oompah
created: 2026-07-26 06:28
---
Agent completed successfully in 259s (1402067 tokens)
---
author: oompah
created: 2026-07-26 06:28
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 28
- Tokens: 1.4M in / 6.9K out [1.4M total]
- Cost: $0.0000
- Exit: normal, Duration: 4m 19s
- Log: EXOCOMP-122__20260726T062425Z.jsonl
---
author: oompah
created: 2026-07-26 06:28
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-26 06:28
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-26 06:28
---
Focus: Technical Writer
---
author: oompah
created: 2026-07-26 06:29
---
Understanding: As Technical Writer, I will document the M5 shipped-artifact performance qualification gate. The duplicate_detector run confirmed the gap: only a fake-server bench-llama-short target exists; no Make targets, versioned baselines, or documented regression budgets cover real shipped artifacts. My scope is documentation only — I will write or update docs in docs/ covering the new Make targets (bench-llama-short-shipped, bench-llama-full), artifact/host identity recording, baseline selection, threshold-failure semantics, and CI/release-qualification integration. I will explore the existing docs, Makefile, and bench harness first, then author the documentation.
---
author: oompah
created: 2026-07-26 06:30
---
Discovery: Explored the full M5 bench harness. Key findings: (1) Makefile has only bench-llama-short (fake server, no real llama-server required). (2) apps/bench contains Config, HostProfile, BeamSampler, Run, Sample, Report::Summary, Driver modules and the llama_inference_test.exs suite — all using FakeLlamaServer. (3) plans/milestone-5-performance.md defines M5 acceptance criteria, performance gates (< 5% CPU core, < 5% RAM for BEAM control plane), and measurement architecture. (4) Two pinned host profiles exist: apps/bench/priv/bench/profiles/amd64-ci.toml and arm64-ci.toml. (5) docs/release-qualification.md covers OTP reproducibility/clean-container matrix only; no M5 performance gate is documented anywhere in docs/. (6) docs/maintainer-release-checklist.md has no M5 qualification step. (7) docs/release-evidence/v0.1.0-rc.2/README.md explicitly records M5 FAIL with the reason: no shipped-artifact Make gate or baseline exists. I will now create docs/performance-qualification.md and update docs/release-qualification.md and docs/maintainer-release-checklist.md to document the M5 shipped-artifact gate, then hand off to the feature agent for implementation.
---
author: oompah
created: 2026-07-26 06:33
---
Implementation: Created docs/performance-qualification.md (421 lines) covering the M5 shipped-artifact gate in full. Updated docs/release-qualification.md to add an M5 section with make target examples and a link to the new doc. Updated docs/maintainer-release-checklist.md to add per-architecture M5 gate checklist items and evidence-collection steps. All docs pass make check-links and make compliance-check. Key decisions documented: (1) three-tier target model (bench-llama-short fake CI / bench-llama-short-shipped real CI / bench-llama-full release); (2) hard gates are CPU < 5% of one core and RAM < 5% of host RAM for BEAM control plane only, llama.cpp reported separately; (3) versioned TOML baselines in apps/bench/priv/bench/baselines/<version>/<arch>.toml; (4) failure output names the exact metric, observed value, budget, artifact, host, and baseline path; (5) missing metric is a gate failure; (6) bench-llama-full must pass on both native amd64 and full-system arm64 QEMU guests.
---
author: oompah
created: 2026-07-26 06:33
---
Verification: make check-links passes (all internal doc links resolve). make compliance-check passes. git status is clean and branch is up to date with origin/epic-EXOCOMP-117 at cd5c0c7. No code changes were made; only documentation was added or updated.
---
author: oompah
created: 2026-07-26 06:33
---
Focus handoff: docs — (1) Outcome: documentation complete. Created docs/performance-qualification.md specifying the full M5 shipped-artifact gate: three-tier Make targets, prerequisites, host profiles, versioned TOML baselines, hard gate format, missing-metric failure, artifact identity fields, evidence layout, architecture qualification requirements, and troubleshooting. Updated docs/release-qualification.md and docs/maintainer-release-checklist.md to cross-reference the new doc and include M5 steps. (2) Relevant files: docs/performance-qualification.md (new), docs/release-qualification.md (updated Related Docs + M5 section), docs/maintainer-release-checklist.md (new M5 gate section). Baseline directory location: apps/bench/priv/bench/baselines/<version>/<arch>.toml. (3) Remaining work: The feature implementation is entirely absent — Make targets bench-llama-short-shipped and bench-llama-full do not exist; baseline TOML files have not been created; the regression gate evaluator in Bench.Report.Summary is a stub; artifact-identity capture from build-identity.json is not wired; evidence JSONL output path is not implemented. The docs/ specification above is the authoritative contract for the feature agent. (4) Recommended next focus: feature.
---
author: oompah
created: 2026-07-26 06:34
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 53
- Tokens: 70 in / 2.2K out [2.3K total]
- Cost: $0.0000
- Exit: terminated, Duration: 5m 25s
- Log: EXOCOMP-122__20260726T062851Z.jsonl
---
author: oompah
created: 2026-07-26 06:34
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-26 06:34
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-07-26 06:35
---
Understanding: Continuing the completed documentation handoff as DevOps. I will reconcile docs/performance-qualification.md with the existing harness, release packaging, Makefile, and CI; implement reproducible short/full shipped-artifact orchestration with pinned baselines, host/artifact identity and evidence paths; add focused operational tests; then run the relevant Make gates. Any application-layer evaluator work that is materially outside this focus will receive a precise feature handoff after the DevOps surface is committed and pushed.
---
author: oompah
created: 2026-07-26 06:42
---
Discovery: The current Bench.Report.Summary and Bench.Driver are validation/serialization stubs, so Make/CI wiring alone cannot satisfy the gate. Release artifacts do contain build-identity.json at their root; installed releases live under /opt/exocomp/<component>/current; systemd exposes MainPID; the shipped llama launcher execs llama-server.bin with its bundled lib closure. I will build a standalone bench_harness OTP release using the existing digest-pinned Debian builder, run it natively, verify sampled PIDs resolve inside the exact supplied release/runtime artifacts, use direct shipped releases for short mode and installed systemd services for full mode, and preserve service state on cleanup.
---
author: oompah
created: 2026-07-26 07:13
---
Implementation: Added digest-pinned standalone bench_harness release construction plus bench-llama-short-shipped and bench-llama-full Make targets. Short mode launches and verifies the supplied OTP releases directly; full mode preserves systemd unit state and rejects MainPIDs outside the supplied installed roots. Added exact artifact/model/llama identity capture, runtime host capture, rc.2 and v0.1.0 amd64/arm64 TOML baselines, strict CPU/RAM aggregation excluding llama.cpp, missing-metric hard failure, actionable failure blocks, atomic JSONL/summary evidence, CI short-harness workflow, and release docs/checklist updates. Partial process startup is rolled back and tested.
---
author: oompah
created: 2026-07-26 07:34
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 263
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: stalled, Duration: 1h 0m 13s
- Log: EXOCOMP-122__20260726T063434Z.jsonl
---
author: oompah
created: 2026-07-26 07:34
---
Agent stalled 1 time(s) (3613s). Escalating from 'standard' to 'deep'. Retrying in 20s (attempt #2)
---
author: oompah
created: 2026-07-26 07:35
---
Retrying (attempt #2, agent: deep)
---
author: oompah
created: 2026-07-26 07:35
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-07-26 07:35
---
Understanding: Resuming the stalled DevOps implementation from the shared worktree. I will preserve and audit the existing shipped-artifact harness, reconcile it against the documented contract, run focused and repository Make gates, fix any failures within the DevOps scope, then commit/push and either complete the issue or leave a precise specialist handoff if clean native architecture qualification remains external.
---
author: oompah
created: 2026-07-26 07:41
---
Discovery: The inherited implementation is structurally complete and its prior run log records 108/108 bench tests plus a standalone harness build under the digest-pinned Elixir 1.20.2/OTP 28.5 image. Final audit found three reliability gaps before handoff: evidence was written directly into the final directory (allowing partial output), baseline validation did not require both documented <5% hard gates or prevent relaxed budgets, and CI exercised only the fake-server target rather than providing an exact candidate-bundle path for the shipped short gate. I will close those gaps and rerun the pinned focused suite through the existing container service workaround because the local Docker CLI cannot mutate its /run state in this managed sandbox.
---
author: oompah
created: 2026-07-26 07:50
---
Implementation: Delivered a standalone digest-pinned bench_harness release; real shipped-artifact short/full Make targets; direct-release and installed-systemd orchestration with PID/root verification and rollback; artifact/model/llama hashes; runtime host capture; strict per-version amd64/arm64 baselines; BEAM-only CPU/RAM aggregation with exact metric failures and missing-metric rejection; atomic JSONL/summary evidence; exact-candidate CI dispatch with archive/source identity checks and retained evidence; and release qualification documentation. Final hardening requires both <5% gates and rejects relaxed or incomplete baselines.
---
author: oompah
created: 2026-07-26 07:50
---
Verification: PASS — make test-m5-qualification completed through the pinned amd64 builder (3 Python operational checks and 32 focused ExUnit tests); the complete bench application passed 110/110 tests and warnings-as-errors compilation under Elixir 1.20.2/OTP 28.5; bench_harness assembled successfully and its CLI returned the expected actionable exit-2 missing-input diagnostic. PASS — make release-check (27 tests), make test-builders (13 structural/runtime-dependency checks plus packaging/docs suites), make check-links, compliance-check, workflow YAML parse, workflow shell syntax, changed-file formatting, and git diff --check. Native amd64 and full-system arm64 candidate performance runs remain intentionally owned by existing downstream requalification task EXOCOMP-123.
---
author: oompah
created: 2026-07-26 07:51
---
Completion: Shipped-artifact M5 qualification gate is complete in commit 371ca4e and pushed to origin/epic-EXOCOMP-117. The branch is clean and exactly matches origin. Delivered real short/full process orchestration, immutable harness build, strict versioned amd64/arm64 budgets, artifact/host identity, deterministic actionable failures, atomic raw evidence, candidate CI integration, focused tests, and release documentation. No new follow-up was filed because EXOCOMP-123 already owns clean amd64/full-system arm64 execution against the next exact signed candidate.
---
author: oompah
created: 2026-07-26 07:51
---
Run #3 [attempt=3, profile=deep, role=deep -> Codex/default]
- Turns: 0, Tool calls: 132
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 16m 24s
- Log: EXOCOMP-122__20260726T073513Z.jsonl
---
author: oompah
created: 2026-07-26 07:51
---
Delivered and pushed the shipped-artifact M5 qualification gate with real short/full targets, strict architecture baselines, artifact and host identity, atomic evidence, exact-metric failures, CI candidate execution, documentation, and passing focused/release checks (commit 371ca4e).
---
author: oompah
created: 2026-08-03 12:01
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-08-03 12:06
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-03 12:06
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-03 12:07
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- merged_commit: 371ca4e3678840f7a9b5f9a370ce9da24d9843ce
- docs_commit: cd5c0c7e
- commit_on_main: true
- makefile_targets_present: bench-llama-short-shipped, bench-llama-full, bench-harness, test-m5-qualification
- baselines_present: apps/bench/priv/bench/baselines/{v0.1.0-rc.2,v0.1.0}/{amd64,arm64}.toml
- docs_present: docs/performance-qualification.md
- workflow_present: .github/workflows/m5-harness.yml
- downstream_requalification_task: EXOCOMP-123
---
<!-- COMMENTS:END -->
