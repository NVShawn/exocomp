---
id: EXOCOMP-79
type: task
status: Backlog
priority: null
title: Bounded in-memory task registry GenServer
parent: EXOCOMP-12
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T23:04:29.432001Z'
updated_at: '2026-07-23T23:04:29.432001Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

### Goal
Implement Exocomp.Node.TaskRegistry, a GenServer that tracks A2A task lifecycle with bounded in-memory storage, state-machine transitions, concurrency limits, and age+count eviction.

### Context
The A2A protocol requires tasks to progress through states: submitted → working → completed | failed | canceled. The registry must be bounded to prevent unbounded memory growth. This GenServer is used by the A2A endpoint wiring task (EXOCOMP-12 child D).

### Relevant files
- apps/exocomp_node/lib/exocomp/node/ — create task_registry.ex here
- apps/exocomp_core/lib/exocomp/a2a/task.ex — Task struct
- apps/exocomp_core/lib/exocomp/a2a/task_state.ex — TaskState enum (:submitted, :working, :completed, :failed, :canceled)
- apps/exocomp_core/lib/exocomp/a2a/task_status.ex — TaskStatus struct

### Implementation

### Module: Exocomp.Node.TaskRegistry

State: map of task_id → {A2A.Task, inserted_at_monotonic}

#### Configuration (read via Application.get_env)
- :max_tasks (default 1000): maximum tasks in registry (active + history)
- :max_concurrent_tasks (default 10): maximum tasks in :working state at once
- :history_ttl_ms (default 3_600_000): evict completed/failed/canceled tasks older than this
- :eviction_interval_ms (default 60_000): how often to run the age-based eviction sweep

#### Public API
- start_link(opts) :: GenServer.on_start()
- submit(message, skill_id) :: {:ok, task_id} | {:error, :at_capacity}
  — creates a new Task with state :submitted, UUID task_id, stores it; returns error if max_concurrent_tasks already working
- get(task_id) :: {:ok, A2A.Task.t()} | {:error, :not_found}
- list() :: [A2A.Task.t()] (all tasks, active + recent history)
- transition(task_id, new_state, result_or_error \\ nil) :: :ok | {:error, :not_found | :invalid_transition}
  — advances state machine; :working→:completed | :failed; :submitted→:canceled | :working; :working→:canceled
- cancel(task_id) :: {:ok, A2A.Task.t()} | {:error, :not_found | :not_cancelable}
  — only :submitted or :working tasks are cancelable; :completed/:failed already terminal
- register_worker(task_id, worker_pid) :: :ok
  — stores the pid of the async worker for a :working task so cancel can send it a shutdown signal

#### Eviction logic
On each eviction sweep and on submit when at max_tasks:
1. Evict terminal tasks (completed/failed/canceled) older than history_ttl_ms
2. If still over max_tasks, evict oldest terminal tasks by inserted_at
3. Never evict active (submitted/working) tasks by age

#### Task state machine
Valid transitions:
- :submitted → :working (on skill dispatch start)
- :submitted → :canceled (on cancel request)
- :working → :completed (on skill success)
- :working → :failed (on skill error/timeout)
- :working → :canceled (on cancel request; must also signal worker process)

#### Wire into supervision tree
Add TaskRegistry to Exocomp.Node.Application children.

### Tests
- submit/1 creates task with :submitted state, returns task_id
- get/1 returns task by id
- list/0 returns all tasks
- transition: all valid state changes succeed
- transition: invalid transition returns {:error, :invalid_transition}
- cancel: :submitted task → :canceled
- cancel: :working task → :canceled, worker receives :shutdown signal
- cancel: :completed task → {:error, :not_cancelable}
- at_capacity: submit returns {:error, :at_capacity} when max_concurrent_tasks working
- eviction: tasks over history_ttl_ms are evicted
- eviction: max_tasks count triggers eviction of oldest terminal tasks

### Quality gate
mix test apps/exocomp_node (focused)

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

