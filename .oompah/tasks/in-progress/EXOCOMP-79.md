---
id: EXOCOMP-79
type: task
status: In Progress
priority: null
title: Bounded in-memory task registry GenServer
parent: EXOCOMP-12
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T23:04:29.432001Z'
updated_at: '2026-07-24T01:16:25.649121Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 740ab4f6-c6b9-4f44-ba1f-13339901ecb7
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 491106
  total_output_tokens: 2870
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 491106
      output_tokens: 2870
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 491106
    output_tokens: 2870
    cost_usd: 0.0
    recorded_at: '2026-07-24T00:52:04.639873+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 00:50
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 00:50
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 00:50
---
Understanding: Screening EXOCOMP-79 for duplication before any implementation. I will search task records and project docs for existing TaskRegistry/A2A lifecycle work, inspect plausible task descriptions and comments in full, then archive only if the same underlying work is already covered; otherwise I will hand off to implementation focus.
---
author: oompah
created: 2026-07-24 00:51
---
Discovery: No duplicate found. The closest reviewed tasks are EXOCOMP-12 (parent epic that intentionally decomposes bounded task history into EXOCOMP-79), EXOCOMP-81 (endpoint wiring that explicitly depends on EXOCOMP-79), EXOCOMP-48 (A2A Task/TaskStatus/TaskState type definitions only), and EXOCOMP-13 (milestone integration verification only). Repository search found the bounded registry requirement only in plans/milestone-1-node-agent.md and found no existing TaskRegistry implementation or matching commit. These scopes are complementary, not duplicate.
---
author: oompah
created: 2026-07-24 00:51
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no confirmed duplicate; EXOCOMP-79 is the unique implementation task for the bounded in-memory node TaskRegistry.

Evidence: Searched .oompah/tasks (not materialized in this worktree), docs, plans, README, WORKFLOW, repository source, and git history for TaskRegistry, bounded task lifecycle, concurrency, TTL, and eviction terms. Reviewed full tracker records for EXOCOMP-12, EXOCOMP-81, EXOCOMP-13, EXOCOMP-8, and EXOCOMP-48. EXOCOMP-12 is the parent epic; EXOCOMP-81 consumes this registry; EXOCOMP-48 supplies protocol structs; EXOCOMP-13 only verifies the milestone. No TaskRegistry implementation or prior matching commit exists.

Relevant files: plans/milestone-1-node-agent.md; apps/exocomp_node/lib/exocomp/node/ (new task_registry.ex); apps/exocomp_core/lib/exocomp/a2a/{task,task_state,task_status}.ex; Exocomp.Node.Application supervision tree.

Remaining work/risks: Implement the GenServer, lifecycle rules, worker cancellation, concurrency bounds, TTL/count eviction, supervision wiring, and focused ExUnit coverage. Confirm the existing A2A struct field conventions before construction/update. No code was changed during duplicate screening.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 00:52
---
Agent completed successfully in 89s (493976 tokens)
---
author: oompah
created: 2026-07-24 00:52
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 15
- Tokens: 491.1K in / 2.9K out [494.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 29s
- Log: EXOCOMP-79__20260724T005038Z.jsonl
---
author: oompah
created: 2026-07-24 00:52
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 01:16
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 01:16
---
Focus: Epic Planner
---
<!-- COMMENTS:END -->
