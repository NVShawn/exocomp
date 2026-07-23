---
id: EXOCOMP-56
type: task
status: Backlog
priority: null
title: Implement host sampler with per-process/cgroup attribution
parent: EXOCOMP-35
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T20:37:21.728642Z'
updated_at: '2026-07-23T20:37:21.728642Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

In apps/bench, implement Bench.HostSampler — a GenServer that reads Linux /proc and optionally cgroup v1/v2 accounting to collect per-process resource usage at a configurable interval. The sampler must attribute metrics separately to three named targets: :node (exocomp_node process group), :coordinator (exocomp_coord process group), and :llama (llama-server process). Metrics per target: CPU usage (%), RSS/PSS bytes (from /proc/<pid>/status or /proc/<pid>/smaps_rollup), open file descriptors (from /proc/<pid>/fd count), cumulative disk I/O bytes (from /proc/<pid>/io), network I/O bytes (if cgroup v2 net accounting available), and page fault count (from /proc/<pid>/stat fields 9 and 10). Implement: Bench.HostSampler.start_link/1 (accepts [{:node, pid}, {:coordinator, pid}, {:llama, pid}]), Bench.HostSampler.stop/1, Bench.HostSampler.flush/1. If a PID is nil or the process has exited, emit a sample with value nil and metric tag :missing instead of crashing. Test: CPU usage increases when a test process runs a tight loop, RSS increases after allocation, missing PID produces :missing samples (not exceptions), attribution tags (:node/:coordinator/:llama) are preserved in sample source field. Reference: plans/milestone-5-performance.md (Measurement Architecture, Host sampling paragraph).

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

