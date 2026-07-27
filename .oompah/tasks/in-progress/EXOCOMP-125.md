---
id: EXOCOMP-125
type: task
status: In Progress
priority: 1
title: Complete remaining M5 workload and soak qualification
parent: null
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-27T16:09:24.864781Z'
updated_at: '2026-07-27T17:19:28.478867Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 2433a042-aec8-40a5-a73a-3a727cb18ca0
oompah.task_costs:
  total_input_tokens: 44
  total_output_tokens: 7386
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 44
      output_tokens: 7386
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 44
    output_tokens: 7386
    cost_usd: 0.0
    recorded_at: '2026-07-27T16:19:16.934986+00:00'
---
## Summary

Triggered by: EXOCOMP-124

Close M5-CRIT-3 through M5-CRIT-6. Main has pinned shipped-artifact CPU/RAM gates and startup/inference/saturation evidence, but lacks shipped llama restart results, mixed healthy/slow/unreachable coordinator polling benchmarks, recovery observation-to-verification latency under load, and multi-hour leak/soak analysis covering memory, processes, mailboxes, descriptors, and task history. Implement the missing workloads and reports, qualify amd64 and arm64 artifacts, commit raw evidence, and merge to main.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-27 16:15
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-27 16:15
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-27 16:15
---
Understanding (Duplicate Investigator): This task (triggered by EXOCOMP-124) asks to close M5-CRIT-3 through M5-CRIT-6 by implementing missing M5 workloads: llama restart benchmarks, mixed coordinator polling benchmarks, recovery observation-to-verification latency under load, and multi-hour leak/soak analysis. I will now search for candidate duplicates before any implementation.
---
author: oompah
created: 2026-07-27 16:19
---
Focus handoff: duplicate_detector\n\n1. Outcome: No duplicate confirmed. EXOCOMP-125 is a fresh, distinct task targeting M5-CRIT-3 through M5-CRIT-6, which have no prior implementation in the task tracker, git history, or committed evidence.\n\n2. Evidence reviewed:\n- EXOCOMP-122 (Merged): Adds shipped-artifact M5 gate (bench-llama-short-shipped / bench-llama-full Make targets), covers M5-CRIT-1/2 (idle CPU/RAM gates) only.\n- EXOCOMP-123 (referenced via EXOCOMP-124 comments): rc.23 bench evidence at docs/release-evidence/v0.1.0-rc.23/raw/amd64/bench/summary.json confirms only startup, sequential, and concurrent inference metrics are present — no restart results, no mixed healthy/slow/unreachable coordinator polling, no recovery observation-to-verification latency, no soak/leak analysis.\n- EXOCOMP-124 (Merged): Reconciled all 48 milestone checkboxes; confirmed M5-CRIT-3 through M5-CRIT-6 unchecked; explicitly created EXOCOMP-125 for these gaps.\n- EXOCOMP-126 (In Progress): Separate task — M4-CRIT-2 A2A workflow, not M5 benchmarks.\n- EXOCOMP-104 (Merged): Coordinator volatile restart recovery documentation — functional recovery, not benchmarks.\n- git log: zero commits implement llama restart benchmarks, mixed coordinator polling, recovery latency, or soak/leak workloads.\n- plans/milestone-5-performance.md: M5-CRIT-3 through M5-CRIT-6 remain unchecked as of fa241b2.\n\n3. What exists that the implementation agent can build on:\n- apps/bench/lib/bench/workload/llama_inference.ex already has crash_restart scenario scaffolding (measure_crash_restart/3 with crash_fn/0 parameter).\n- Coordinator polling logic exists in apps/exocomp_coordinator/.\n- The harness driver (apps/bench/lib/bench/driver.ex) and sampler stack are complete.\n- Versioned baselines under apps/bench/priv/bench/baselines/.\n- Raw evidence layout: docs/release-evidence/v0.1.0-rc.23/raw/{amd64,arm64}/bench/.\n\n4. Remaining work (all of M5-CRIT-3 through M5-CRIT-6):\n- M5-CRIT-3: Wire llama-server crash/restart benchmark into the full shipped-artifact run; report startup_ms, RSS, sequential/concurrent inference latency, saturation metrics, and restart_ms separately and as bundle totals.\n- M5-CRIT-4: Implement coordinator polling workload with healthy/slow/unreachable node mixtures; assert no unbounded mailbox growth during sustained polling.\n- M5-CRIT-5: Implement recovery (M4 path) latency workload: observation-to-verification elapsed time under concurrent inference load; verify M4 safety behavior is preserved.\n- M5-CRIT-6: Implement multi-hour soak workload analyzing memory slope, process count, per-named-process mailbox depth, file descriptor count, task registry size over time; soak analysis passes iff no sustained positive slope after warm-up.\n- Commit raw evidence for amd64 and arm64 and update milestone-5-performance.md checkboxes.\n\n5. Recommended next focus: devops (to implement the missing workloads, qualify on both architectures, and commit evidence).
---
author: oompah
created: 2026-07-27 16:19
---
Agent completed successfully in 214s (7430 tokens)
---
author: oompah
created: 2026-07-27 16:19
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 56, Tool calls: 41
- Tokens: 44 in / 7.4K out [7.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 34s
- Log: EXOCOMP-125__20260727T161545Z.jsonl
---
author: oompah
created: 2026-07-27 16:19
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-27 16:19
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-27 16:19
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-07-27 16:19
---
Understanding (DevOps): implement and test the remaining shipped-artifact M5 qualification workloads for llama crash/restart, mixed coordinator polling, recovery observation-to-verification latency under inference load, and leak/soak analysis; integrate reproducible Make targets/reporting, qualify only architectures supported by real evidence, update M5 criteria, then commit/push and close or leave a precise focus handoff if external hardware remains.
---
author: oompah
created: 2026-07-27 16:36
---
Discovery (DevOps): the shipped full gate already has authenticated OTP release RPC and separately owned llama-server, so the missing workloads can run inside the installed artifacts without linking source-tree coordinator code into the harness. Added opt-in runtime probes in exocomp_core, isolated real Registry/HealthPoller and RemediationLifecycle qualification probes in the coordinator, and pure harness-side soak analysis. Focused pinned-builder compile/tests pass (55 bench, 3 core probe, 2 coordinator probe).
---
author: oompah
created: 2026-07-27 16:45
---
Implementation: added opt-in shipped-VM telemetry probes; real llama crash/restart with PID retargeting and diagnostics; isolated healthy/slow/unreachable coordinator polling; M4 remediation observation-to-verification timing under concurrent inference with fail-closed safety validation; bounded two-hour inference soak with slope/window analysis for RSS, BEAM processes, named mailboxes, descriptors, and task/goal histories; hard summary gates, Make controls, focused tests, a pinned dual-architecture qualification runner with rollback capture, and operator documentation.
---
author: oompah
created: 2026-07-27 16:48
---
Verification (implementation): pinned-builder make fmt-check and make lint passed; make test-m5-qualification passed (4 workflow tests, 46 bench tests, 3 core probe tests, 2 coordinator workload tests); full make test passed (127 bench, 195 core, 502 coordinator, 845 node with 10 expected exclusions) and both OTP release smoke checks passed. Dual-architecture two-hour artifact qualification is the remaining verification stage.
---
author: oompah
created: 2026-07-27 16:57
---
Qualification update: the first amd64 live preflight correctly failed before benchmarking because the runner's private umask leaked into installation and denied the service account access. Fixed in f92f02c by isolating preflight under umask 022 while explicitly keeping rollback material 0600; shellcheck, bash syntax, static workflow tests passed. Stopped the obsolete arm64 preflight before mutation. Fresh exact-f92f02c amd64 and arm64 runs are active.
---
author: oompah
created: 2026-07-27 17:06
---
Qualification update: f92f02c passed amd64 offline install/readiness, then failed closed at the first sibling-release RPC because bench_harness inherited RELEASE_* launcher variables into the coordinator CLI; the installed coordinator's own RPC was verified healthy. Commit e2afa4b clears all caller release launcher variables while supplying only the protected sibling cookie, with a focused regression test (47 bench + probe suites pass). Fresh exact-e2afa4b runs are active on both guests.
---
author: oompah
created: 2026-07-27 17:19
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 293
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: stalled, Duration: 1h 0m 2s
- Log: EXOCOMP-125__20260727T161926Z.jsonl
---
author: oompah
created: 2026-07-27 17:19
---
Agent stalled 1 time(s) (3602s). Escalating from 'standard' to 'deep'. Retrying in 10s (attempt #1)
---
<!-- COMMENTS:END -->
