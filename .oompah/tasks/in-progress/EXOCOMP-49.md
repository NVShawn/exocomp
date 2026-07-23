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
labels: []
assignee: null
created_at: '2026-07-23T20:36:17.846759Z'
updated_at: '2026-07-23T21:16:05.978527Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 2e1553fb-f45e-4b2b-902a-821ae4bc2631
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 369357
  total_output_tokens: 2354
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 369357
      output_tokens: 2354
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 369357
    output_tokens: 2354
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:16:04.020148+00:00'
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
<!-- COMMENTS:END -->
