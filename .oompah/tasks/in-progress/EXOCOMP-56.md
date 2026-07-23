---
id: EXOCOMP-56
type: task
status: In Progress
priority: null
title: Implement host sampler with per-process/cgroup attribution
parent: EXOCOMP-35
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T20:37:21.728642Z'
updated_at: '2026-07-23T21:55:53.191775Z'
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
<!-- COMMENTS:END -->
