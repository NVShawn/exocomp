---
id: EXOCOMP-81
type: task
status: Open
priority: null
title: Wire A2A message endpoints to TaskRegistry and skill dispatch
parent: EXOCOMP-12
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T23:05:17.322742Z'
updated_at: '2026-07-24T00:48:33.593918Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

### Goal
Complete the A2A HTTP endpoint wiring: connect POST /message:send, GET /tasks/:id, GET /tasks, and POST /tasks/:id:cancel to the TaskRegistry and skill Dispatcher. Replace the stub handlers from EXOCOMP-78 with real A2A request/response logic.

### Prerequisites
- EXOCOMP-78: A2ARouter scaffold exists with stub handlers
- EXOCOMP-79: TaskRegistry GenServer is implemented
- EXOCOMP-80: Skill Dispatcher + all three skill handlers are implemented

### Relevant files
- apps/exocomp_node/lib/exocomp/node/a2a_router.ex — add real handlers
- apps/exocomp_node/lib/exocomp/node/task_registry.ex — submit/get/list/cancel API
- apps/exocomp_node/lib/exocomp/node/skills/dispatcher.ex — route to skill handlers
- apps/exocomp_core/lib/exocomp/a2a/ — types for encoding/decoding

### Implementation

### POST /message:send
1. Decode JSON body as A2A Message struct (role, parts, messageId optional)
2. Extract skill_id from message parts (look for TextPart or DataPart with skill key; validate it is one of the three supported skills)
3. Extract skill params from message parts (DataPart data map)
4. Call TaskRegistry.submit(message, skill_id) → {:ok, task_id} | {:error, :at_capacity}
5. If at_capacity → return 429 with InternalError
6. If ok → spawn async worker: Task.start(fn → run_skill_async(task_id, skill_id, params) end)
7. Return 202 with A2A Task JSON (status: submitted)

#### Async skill execution (run_skill_async/3)
1. TaskRegistry.transition(task_id, :working) — registers worker pid
2. Call Skills.Dispatcher.dispatch(skill_id, params)
3. On success: TaskRegistry.transition(task_id, :completed, artifact)
4. On error: TaskRegistry.transition(task_id, :failed, error)
5. Enforce per-skill timeout via Task.await with timeout

### GET /tasks/:id
1. Call TaskRegistry.get(task_id)
2. Not found → 404 with TaskNotFoundError JSON
3. Found → 200 with A2A Task JSON

### GET /tasks
1. Call TaskRegistry.list()
2. Return 200 with JSON array of A2A Task objects

### POST /tasks/:id:cancel
Note: Plug Router pattern for this route is "/tasks/:id:cancel" or use path params carefully.
1. Call TaskRegistry.cancel(task_id)
2. Not found → 404 with TaskNotFoundError JSON
3. Not cancelable → 400 with TaskNotCancelableError JSON
4. Canceled → 200 with updated A2A Task JSON

### JSON encoding/decoding helpers
Create Exocomp.Node.A2A.Codec (or add to A2ARouter) with:
- decode_message/1 — parse JSON map to Message struct; return {:error, InvalidParamsError} on bad input
- encode_task/1 — Task struct → JSON map (handle TaskStatus, Artifact, DataPart)
- encode_error/1 — A2A error struct → JSON-RPC-style %{error: %{code:, message:, data:}}

### A2A error response format
All error responses use Content-Type: application/a2a+json with body:
```json
{"error": {"code": -32001, "message": "Task not found"}}
```

### Tests
- POST /message:send: valid message → 202 with task in submitted state
- POST /message:send: invalid JSON body → 400 InvalidRequestError
- POST /message:send: unknown skill → 400 InvalidParamsError
- POST /message:send: at_capacity → 429
- GET /tasks/:id: known task → 200 with task JSON
- GET /tasks/:id: unknown id → 404 TaskNotFoundError
- GET /tasks: returns list including at least the submitted task
- POST /tasks/:id:cancel: submitted task → 200 with canceled task
- POST /tasks/:id:cancel: completed task → 400 TaskNotCancelableError
- POST /tasks/:id:cancel: unknown id → 404
- Async skill execution: success → task transitions to :completed with artifact
- Async skill execution: skill error → task transitions to :failed

### Quality gate
mix test apps/exocomp_node (focused)

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

