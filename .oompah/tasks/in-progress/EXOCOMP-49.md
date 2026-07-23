---
id: EXOCOMP-49
type: task
status: In Progress
priority: null
title: Implement A2A 1.0 JSON codecs, error mapping, and version handling
parent: EXOCOMP-8
children: []
blocked_by:
- EXOCOMP-48
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T20:36:17.846759Z'
updated_at: '2026-07-23T21:28:37.434368Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 3cb9fa95-5155-4f44-8b9a-9d356daeae66
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 4185482
  total_output_tokens: 26506
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 4185482
      output_tokens: 26506
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 369357
    output_tokens: 2354
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:16:04.020148+00:00'
  - profile: standard
    model: unknown
    input_tokens: 501532
    output_tokens: 2654
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:17:59.831577+00:00'
  - profile: default
    model: unknown
    input_tokens: 3314593
    output_tokens: 21498
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:27:15.769587+00:00'
---
## Summary

Goal: Implement HTTP+JSON encode/decode codecs for all A2A 1.0 types, required-field validation with proper A2A error returns, and A2A-Version header negotiation in apps/exocomp_core.

Depends on: EXOCOMP-48 (struct definitions must exist first).

Context: The A2A 1.0 spec uses application/a2a+json as the media type and requires an A2A-Version: 1.0 request header. The protocol uses JSON-RPC 2.0 style error codes for error responses. This task implements the encode/decode layer and version gating used by the node A2A server (EXOCOMP-12).

Codec module: Exocomp.A2A.Codec
- encode/1 — converts any A2A struct to a JSON-serializable map (keys as strings matching the spec's camelCase field names)
- decode/2 — takes a raw map (parsed JSON) and a target type, returns {:ok, struct} or {:error, Exocomp.A2A.Error}
- Required-field validation: return the appropriate standard A2A error struct (InvalidParamsError or InvalidRequestError) when a required field is absent or has the wrong type; do not raise exceptions
- Part dispatch: decode a Part based on the 'type' field value ('text', 'data', 'file'); unknown type returns UnsupportedOperationError
- TaskState string-to-atom mapping: 'submitted' -> :submitted, etc.; unrecognised state returns an error

Version handling module: Exocomp.A2A.Version
- supported_versions/0 — returns ['1.0']
- check_version/1 — takes a version string from the A2A-Version header; returns :ok for '1.0', {:error, %UnsupportedOperationError{}} for any other value (including nil/missing)
- parse_content_type/1 — validates that a Content-Type header equals 'application/a2a+json'; returns :ok or {:error, %ContentTypeNotSupportedError{}}

JSON serialisation:
- Use Jason (already a common Elixir JSON library) for JSON encoding/decoding; add it as a dependency in apps/exocomp_core/mix.exs if not already present
- Use the mix.lock in the umbrella root; do not pin an incompatible version
- All keys in encoded output must be camelCase strings matching the A2A 1.0 spec field names
- nil optional fields should be omitted from encoded output (do not include null keys)

Error representation:
- The codec returns Exocomp.A2A.Error structs (defined in EXOCOMP-48) — not Elixir exceptions
- Callers pattern-match on {:ok, struct} | {:error, %Error{}} — no exceptions cross module boundaries

Testing for this task:
- Unit tests in apps/exocomp_core/test/exocomp/a2a/codec_test.exs and version_test.exs
- Test each type's round-trip (encode then decode returns the original struct)
- Test decode of a map with a missing required field returns the correct error code
- Test decode of an unknown Part type returns UnsupportedOperationError
- Test Version.check_version('1.0') returns :ok
- Test Version.check_version('2.0') returns {:error, %UnsupportedOperationError{}}
- Test Version.check_version(nil) returns {:error, %UnsupportedOperationError{}}
- Test parse_content_type with correct and incorrect values

Quality gate: make test && make lint && make fmt-check must pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:14
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:14
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:16
---
Agent completed successfully in 74s (371711 tokens)
---
author: oompah
created: 2026-07-23 21:16
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 9
- Tokens: 369.4K in / 2.4K out [371.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 14s
- Log: EXOCOMP-49__20260723T211452Z.jsonl
---
author: oompah
created: 2026-07-23 21:16
---
Agent completed without closing this issue (74s (371711 tokens)). Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:16
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:16
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:17
---
Understanding: Duplicate screening for the A2A codec/version task. I searched the canonical task-state branch and project plans for A2A codec, media type, version negotiation, and error mapping work, then reviewed the complete records for EXOCOMP-8, EXOCOMP-48, and EXOCOMP-51. I will not implement during this focus.
---
author: oompah
created: 2026-07-23 21:17
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed. EXOCOMP-49 is the unique codec/version implementation child deliberately created by EXOCOMP-8.

Evidence: EXOCOMP-8 explicitly decomposes into EXOCOMP-48 types, EXOCOMP-49 codecs/version handling, and EXOCOMP-51 fixtures/compliance tests, with dependency chain EXOCOMP-48 -> EXOCOMP-49 -> EXOCOMP-51. EXOCOMP-48 is Done and expressly excludes encode/decode logic. EXOCOMP-51 depends on EXOCOMP-49 and only owns vendored fixtures plus broader protocol tests. Repository searches across task state, plans, docs, and README found no other codec implementation task.

Relevant files: apps/exocomp_core/lib/exocomp/a2a/ contains the structs delivered by EXOCOMP-48; planned implementation is codec.ex and version.ex with focused tests under apps/exocomp_core/test/exocomp/a2a/. make help confirms test, lint, and fmt-check quality gates.

Remaining work and risks: Implement the described codecs/version checks and focused tests. The runtime checkout reports branch epic-EXOCOMP-8 rather than the prompt-stated EXOCOMP-49; the implementation agent should verify routing before committing. No code or task files were changed during screening.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-23 21:18
---
Agent completed successfully in 96s (504186 tokens)
---
author: oompah
created: 2026-07-23 21:18
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 10
- Tokens: 501.5K in / 2.7K out [504.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 36s
- Log: EXOCOMP-49__20260723T211627Z.jsonl
---
author: oompah
created: 2026-07-23 21:18
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:18
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:18
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-23 21:27
---
Agent completed successfully in 548s (3336091 tokens)
---
author: oompah
created: 2026-07-23 21:27
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 66
- Tokens: 3.3M in / 21.5K out [3.3M total]
- Cost: $0.0000
- Exit: normal, Duration: 9m 8s
- Log: EXOCOMP-49__20260723T211809Z.jsonl
---
author: oompah
created: 2026-07-23 21:27
---
Agent completed without closing this issue (548s (3336091 tokens)). Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:27
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:27
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-23 21:28
---
Understanding: Implementing Exocomp.A2A.Codec and Exocomp.A2A.Version modules in apps/exocomp_core. EXOCOMP-48 structs are all in place (TextPart, DataPart, FilePart, FileContent, Message, Task, TaskStatus, TaskState, Artifact, AgentCard, AgentCapabilities, AgentSkill, Error types). Plan: (1) Add Jason dep to apps/exocomp_core/mix.exs, (2) Implement codec.ex with encode/1 and decode/2 for all types with required-field validation, (3) Implement version.ex with supported_versions/0, check_version/1, parse_content_type/1, (4) Write tests in codec_test.exs and version_test.exs, (5) Run make test && make lint && make fmt-check.
---
<!-- COMMENTS:END -->
