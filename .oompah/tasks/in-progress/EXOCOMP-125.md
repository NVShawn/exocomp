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
- needs:devops
assignee: null
created_at: '2026-07-27T16:09:24.864781Z'
updated_at: '2026-07-27T16:19:08.374709Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 42267f60-2369-4ee3-bc34-ff63f3171f41
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
<!-- COMMENTS:END -->
