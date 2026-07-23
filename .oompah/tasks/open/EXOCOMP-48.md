---
id: EXOCOMP-48
type: task
status: Open
priority: null
title: Define A2A 1.0 protocol type structs and task-state enum
parent: EXOCOMP-8
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T20:35:55.059812Z'
updated_at: '2026-07-23T20:46:42.533114Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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

