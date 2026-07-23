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
- focus-complete:frontend
assignee: null
created_at: '2026-07-23T20:37:21.728642Z'
updated_at: '2026-07-23T22:10:43.613187Z'
work_branch: epic-EXOCOMP-5
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: f2f3aebe-1961-4f8f-a0a1-c45a050fbee0
oompah.work_branch: epic-EXOCOMP-5
oompah.task_costs:
  total_input_tokens: 3455262
  total_output_tokens: 36937
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 3455262
      output_tokens: 36937
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 34
    output_tokens: 8075
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:58:42.203489+00:00'
  - profile: standard
    model: unknown
    input_tokens: 25
    output_tokens: 7613
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:01:43.948156+00:00'
  - profile: standard
    model: unknown
    input_tokens: 3455203
    output_tokens: 21249
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:10:38.952560+00:00'
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
author: oompah
created: 2026-07-23 21:58
---
Agent completed successfully in 182s (8109 tokens)
---
author: oompah
created: 2026-07-23 21:58
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 69, Tool calls: 50
- Tokens: 34 in / 8.1K out [8.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 2s
- Log: EXOCOMP-56__20260723T215542Z.jsonl
---
author: oompah
created: 2026-07-23 21:58
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:58
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:58
---
Focus: Frontend Developer
---
author: oompah
created: 2026-07-23 22:00
---
Understanding (Frontend Developer): This task requires implementing Bench.HostSampler, a backend Elixir GenServer that reads Linux /proc and cgroup v1/v2 files to collect per-process CPU/memory/IO metrics. There is no UI, HTML, CSS, or JavaScript component. This is outside the Frontend Developer focus area and requires a feature/backend Elixir specialist. Initiating handoff.
---
author: oompah
created: 2026-07-23 22:01
---
Focus handoff: frontend

Outcome: No frontend/UI work exists on this task. EXOCOMP-56 is 100% backend Elixir code. A feature specialist must implement this.

Relevant findings for the next agent:

**Branch state:**
- The worktree is currently on branch \`epic-EXOCOMP-35\` (NOT \`EXOCOMP-56\` — no such branch exists yet)
- The EXOCOMP-56 branch must be created from \`origin/EXOCOMP-54\` (commit 75dda39), the most recent completed bench task
- Create with: \`git checkout -b EXOCOMP-56 origin/EXOCOMP-54\`

**Key files from EXOCOMP-54 (already done):**
- \`apps/bench/lib/bench/sample.ex\`: Bench.Sample struct with fields: timestamp, source (atom: :beam/:host/:node/:coordinator/:llama), metric_name (string), value (number), unit (string)
- \`apps/bench/lib/bench/sampler/behaviour.ex\`: Bench.Sampler.Behaviour with callbacks init/1, collect/1, terminate/1
- \`apps/bench/mix.exs\`: deps are {:jason, '~> 1.4'}, {:nimble_options, '~> 1.1'} — no additional deps needed
- Umbrella structure: apps/bench is a Mix app in an Elixir umbrella (build_path ../../_build, deps_path ../../deps)

**IMPORTANT — Bench.Sample value field:**
- Currently typed as \`value: number()\` with \`is_number(value)\` guard in from_map
- Issue requires emitting samples with \`value: nil\` and metric tag \`:missing\` for missing PIDs
- The struct and its from_map/to_map must be updated to allow \`nil\` values, OR emit a separate metadata field
- Easiest path: add optional \`tags\` field to Bench.Sample and relax value type to \`number() | nil\`

**Implementation target:**
- New file: \`apps/bench/lib/bench/host_sampler.ex\` as \`Bench.HostSampler\` GenServer
- API: start_link/1 (opts with targets keyword list [{:node, os_pid}, {:coordinator, os_pid}, {:llama, os_pid}]), stop/1, flush/1
- Reads /proc/<pid>/stat (CPU%, page faults), /proc/<pid>/status or /proc/<pid>/smaps_rollup (RSS/PSS), /proc/<pid>/fd count (open FDs), /proc/<pid>/io (disk I/O bytes), optional cgroup v2 net_cls for network I/O
- CPU% requires two consecutive readings with time delta (store previous stat in GenServer state)
- Missing PID: emit sample with value nil and tag :missing — do not crash
- Sampling interval: configurable (default ~1000ms), collect on tick via Process.send_after

**Tests:**
- New file: \`apps/bench/test/bench/host_sampler_test.exs\`
- Test CPU% increases under tight loop (spawn a port running \`yes > /dev/null\` or similar)
- Test RSS increases after allocation
- Test missing PID produces :missing samples (not exception)
- Test attribution tags (:node/:coordinator/:llama) preserved in sample.source
- Use System.cmd or Port.open to spawn a real OS process for a valid PID

**Quality gates:**
- \`make test\` (runs mix test in umbrella)
- \`make lint\` (credo)
- \`make fmt-check\` (mix format --check-formatted)

**Risks:**
- smaps_rollup not available on older kernels — fall back to VmRSS from /proc/<pid>/status
- cgroup v2 net accounting may not be available — emit nil, do not crash
- EXOCOMP-55 (BeamSampler) is in Needs Human; do not depend on it

Recommended next focus: feature.
---
author: oompah
created: 2026-07-23 22:01
---
Agent completed successfully in 175s (7638 tokens)
---
author: oompah
created: 2026-07-23 22:01
---
Run #1 [attempt=1, profile=standard, role=standard -> Claude/default]
- Turns: 47, Tool calls: 33
- Tokens: 25 in / 7.6K out [7.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 55s
- Log: EXOCOMP-56__20260723T215852Z.jsonl
---
author: oompah
created: 2026-07-23 22:01
---
Focus handoff from `frontend` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 22:01
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:01
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-23 22:10
---
Agent completed successfully in 528s (3476452 tokens)
---
author: oompah
created: 2026-07-23 22:10
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 36
- Tokens: 3.5M in / 21.2K out [3.5M total]
- Cost: $0.0000
- Exit: normal, Duration: 8m 48s
- Log: EXOCOMP-56__20260723T220154Z.jsonl
---
author: oompah
created: 2026-07-23 22:10
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-35`. Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
---
<!-- COMMENTS:END -->
