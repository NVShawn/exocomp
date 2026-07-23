---
id: EXOCOMP-55
type: task
status: Open
priority: null
title: Implement BEAM telemetry sampler
parent: EXOCOMP-35
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T20:37:10.989869Z'
updated_at: '2026-07-23T20:46:48.569152Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

In apps/bench, implement Bench.BeamSampler — a GenServer that polls BEAM runtime metrics at a configurable interval and appends Bench.Sample entries to an accumulator. Metrics to collect via :erlang built-ins: scheduler utilisation (:erlang.statistics(:scheduler_wall_time)), total process count (:erlang.system_info(:process_count)), run queue length (:erlang.statistics(:run_queue)), mailbox depths for a named list of registered processes (Process.info(pid, :message_queue_len)), memory categories (:erlang.memory/0), and task-registry size (if accessible via Exocomp.Registry or similar). Implement: Bench.BeamSampler.start_link/1, Bench.BeamSampler.stop/1, Bench.BeamSampler.flush/1 (returns accumulated samples). Test: starts and stops cleanly, produces samples with expected metric names, mailbox depth increases when a process receives messages without flushing, scheduler utilisation is a float in [0.0, 1.0]. Reference: plans/milestone-5-performance.md (Measurement Architecture section).

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

