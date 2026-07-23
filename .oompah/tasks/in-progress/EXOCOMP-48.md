---
id: EXOCOMP-48
type: task
status: In Progress
priority: null
title: Define A2A 1.0 protocol type structs and task-state enum
parent: EXOCOMP-8
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T20:35:55.059812Z'
updated_at: '2026-07-23T20:53:26.257619Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: c1a476cc-d6e9-4f54-ba5d-d1abaede751d
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 1132509
  total_output_tokens: 5825
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1132509
      output_tokens: 5825
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 688594
    output_tokens: 3305
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:51:45.187360+00:00'
  - profile: standard
    model: unknown
    input_tokens: 443915
    output_tokens: 2520
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:53:23.697142+00:00'
---
## Summary

Goal: Define all A2A 1.0 protocol type structs and enumerations in apps/exocomp_core/lib/exocomp/a2a/ as the foundational layer for EXOCOMP-8.

Context: The EXOCOMP-7 scaffold landed apps/exocomp_core with a stub Exocomp.Protocol module (version string only). This task adds the type layer that later codec and test tasks build on.

A2A 1.0 spec reference: https://google.github.io/A2A/ (version 1.0 HTTP+JSON binding). The relevant types are documented at https://google.github.io/A2A/specification/#types.

Types to define (as Elixir defstruct modules under Exocomp.A2A.*):
- Exocomp.A2A.AgentCard — name, description, url, version, capabilities, skills list, defaultInputModes, defaultOutputModes
- Exocomp.A2A.AgentCapabilities — streaming (bool), pushNotifications (bool), stateTransitionHistory (bool)
- Exocomp.A2A.AgentSkill — id, name, description, inputModes, outputModes
- Exocomp.A2A.Message — role (enum: user|agent), parts (list of Part), messageId, taskId, contextId, timestamp
- Exocomp.A2A.Task — id, contextId, status (TaskStatus), history (list of Message), artifacts (list of Artifact), metadata, created_at, updated_at
- Exocomp.A2A.TaskStatus — state (TaskState enum), message (optional Message), timestamp
- Exocomp.A2A.TaskState — enum module with values: :submitted, :working, :input_required, :completed, :canceled, :failed, :unknown
- Exocomp.A2A.TextPart — type (always 'text'), text, metadata
- Exocomp.A2A.DataPart — type (always 'data'), data (map), metadata
- Exocomp.A2A.FilePart — type (always 'file'), file (FileContent), metadata
- Exocomp.A2A.FileContent — name, mimeType, uri (optional), bytes (optional base64)
- Exocomp.A2A.Artifact — artifactId, name (optional), description (optional), parts (list of Part), index, append (bool), lastChunk (bool), metadata

Standard A2A error type structs (returned as JSON in error responses):
- Exocomp.A2A.Error — base struct: code (integer), message (string), data (optional)
- Standard errors as modules (each with a fixed code matching the A2A spec):
  - JSONParseError (code -32700)
  - InvalidRequestError (code -32600)
  - MethodNotFoundError (code -32601)
  - InvalidParamsError (code -32602)
  - InternalError (code -32603)
  - TaskNotFoundError (code -32001)
  - TaskNotCancelableError (code -32002)
  - PushNotificationNotSupportedError (code -32003)
  - UnsupportedOperationError (code -32004)
  - ContentTypeNotSupportedError (code -32005)

Implementation notes:
- Place all modules under apps/exocomp_core/lib/exocomp/a2a/
- Add @typespecs for each struct field
- Add @moduledoc for each module explaining which A2A 1.0 spec section it corresponds to
- Use nil as the default for optional fields; required fields have no default (enforced in the codec layer)
- No encode/decode logic in this task — pure type definitions only

Testing for this task:
- Add a brief ExUnit test for each module confirming it can be constructed with expected fields (smoke test)
- Tests live in apps/exocomp_core/test/exocomp/a2a/

Quality gate: make test && make lint && make fmt-check must pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:50
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:51
---
Agent completed successfully in 108s (691899 tokens)
---
author: oompah
created: 2026-07-23 20:51
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 13
- Tokens: 688.6K in / 3.3K out [691.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 48s
- Log: EXOCOMP-48__20260723T205000Z.jsonl
---
author: oompah
created: 2026-07-23 20:51
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-8`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 20:52
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 20:52
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:53
---
Agent completed successfully in 81s (446435 tokens)
---
author: oompah
created: 2026-07-23 20:53
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 11
- Tokens: 443.9K in / 2.5K out [446.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 21s
- Log: EXOCOMP-48__20260723T205204Z.jsonl
---
author: oompah
created: 2026-07-23 20:53
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-8`. Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
<!-- COMMENTS:END -->
