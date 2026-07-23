---
id: EXOCOMP-56
type: task
status: In Progress
priority: null
title: Implement host sampler with per-process/cgroup attribution
parent: EXOCOMP-35
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
- needs:feature
assignee: null
created_at: '2026-07-23T20:37:21.728642Z'
updated_at: '2026-07-23T21:58:31.804187Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 87029622-e026-4fcf-ad65-3f840e201e89
oompah.work_branch: epic-EXOCOMP-5
---
## Summary

In apps/bench, implement Bench.HostSampler — a GenServer that reads Linux /proc and optionally cgroup v1/v2 accounting to collect per-process resource usage at a configurable interval. The sampler must attribute metrics separately to three named targets: :node (exocomp_node process group), :coordinator (exocomp_coord process group), and :llama (llama-server process). Metrics per target: CPU usage (%), RSS/PSS bytes (from /proc/<pid>/status or /proc/<pid>/smaps_rollup), open file descriptors (from /proc/<pid>/fd count), cumulative disk I/O bytes (from /proc/<pid>/io), network I/O bytes (if cgroup v2 net accounting available), and page fault count (from /proc/<pid>/stat fields 9 and 10). Implement: Bench.HostSampler.start_link/1 (accepts [{:node, pid}, {:coordinator, pid}, {:llama, pid}]), Bench.HostSampler.stop/1, Bench.HostSampler.flush/1. If a PID is nil or the process has exited, emit a sample with value nil and metric tag :missing instead of crashing. Test: CPU usage increases when a test process runs a tight loop, RSS increases after allocation, missing PID produces :missing samples (not exceptions), attribution tags (:node/:coordinator/:llama) are preserved in sample source field. Reference: plans/milestone-5-performance.md (Measurement Architecture, Host sampling paragraph).

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:55
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:55
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:55
---
Understanding (Duplicate Investigator): Investigating whether EXOCOMP-56 ('Implement host sampler with per-process/cgroup attribution') is a duplicate of any existing task. The issue requests a Bench.HostSampler GenServer in apps/bench that reads Linux /proc and cgroup v1/v2 to collect per-process metrics (CPU, RSS/PSS, FD count, disk I/O, network I/O, page faults) attributed to :node, :coordinator, and :llama targets. Beginning search across .oompah/tasks, plans/, and docs/ for similar work.
---
author: oompah
created: 2026-07-23 21:58
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed. EXOCOMP-56 is a unique task with no overlapping scope in the project.

Evidence reviewed:
- EXOCOMP-35 (parent epic, 'Build the reproducible benchmark harness'): explicitly lists EXOCOMP-56 as a distinct child for the host sampler, alongside EXOCOMP-50 (scaffold), EXOCOMP-52 (config), EXOCOMP-53 (host profiles), EXOCOMP-54 (raw sample model), EXOCOMP-55 (BEAM sampler). Each covers a different harness subsystem.
- EXOCOMP-55 (Needs Human): Bench.BeamSampler — uses :erlang built-ins for BEAM runtime metrics; completely different from EXOCOMP-56's /proc-based per-process Linux host sampling with cgroup attribution.
- EXOCOMP-53 (Done): Bench.HostProfile — static host detection and profile comparison, not a runtime sampler.
- EXOCOMP-54 (Done): Bench.Sample and Bench.Run data model — explicitly the data substrate that EXOCOMP-56's sampler will write to.
- EXOCOMP-62 (Done): LlamaServer OTP supervisor — manages the OS process lifecycle, does not sample its resource usage.
- Searched for 'HostSampler', 'host sampler', 'cgroup', '/proc/', 'per-process', 'resource usage', 'sampl.*proc' across .oompah/tasks, plans, docs, and codebase. No matches found for any existing implementation.
- Milestone-5-performance.md references 'Host sampling' as a distinct architectural component (separate paragraph from 'BEAM telemetry').

Key implementation context for the next agent:
- Target file: apps/bench/lib/bench/host_sampler.ex (module Bench.HostSampler)
- apps/bench scaffold exists on branch EXOCOMP-50 (commit 812a83d), with EXOCOMP-52/53/54 branches adding more modules. The feature agent should build on the latest of these (EXOCOMP-54 at commit 75dda39 is the most recent Done branch).
- Bench.Sample struct (from EXOCOMP-54) is the data model that HostSampler's flush/1 should return — source field will be :node, :coordinator, or :llama.
- Required API: start_link/1 (accepts [{:node, pid}, {:coordinator, pid}, {:llama, pid}]), stop/1, flush/1.
- Graceful missing-PID handling: emit sample with value nil and metric tag :missing; do not crash.
- Metrics: CPU%, RSS/PSS bytes, FD count, disk I/O bytes, network I/O (cgroup v2), page fault count.
- Reading from /proc/<pid>/status, /proc/<pid>/smaps_rollup, /proc/<pid>/fd, /proc/<pid>/io, /proc/<pid>/stat.
- Tests: CPU usage increases under tight loop, RSS increases after allocation, missing PID → :missing samples (not exceptions), attribution tags preserved in sample source field.
- Makefile targets: make test, make lint, make fmt-check.

Remaining work and risks:
- Implement GenServer reading /proc/ files on each tick with configurable interval.
- CPU% calculation requires two consecutive readings of /proc/<pid>/stat and computing delta over elapsed time.
- smaps_rollup may not exist on older kernels; fall back to /proc/<pid>/status VmRSS.
- cgroup v2 net accounting may not be available; treat as optional, emit nil if unavailable.
- Tests need a real OS PID to validate /proc reads; test process should be a spawned Port or System.cmd subprocess.
- EXOCOMP-55 is stuck in Needs Human; EXOCOMP-56 should not depend on it.

Recommended next focus: feature.
---
<!-- COMMENTS:END -->
