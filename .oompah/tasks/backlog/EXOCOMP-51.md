---
id: EXOCOMP-51
type: task
status: Backlog
priority: null
title: Pin A2A 1.0 fixture files and add comprehensive protocol test suite
parent: EXOCOMP-8
children: []
blocked_by:
- EXOCOMP-49
labels: []
assignee: null
created_at: '2026-07-23T20:36:38.184380Z'
updated_at: '2026-07-23T20:36:49.935471Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Goal: Vendor official A2A 1.0 valid fixture JSON files and add a comprehensive ExUnit test suite covering all acceptance criteria for EXOCOMP-8.

Depends on: EXOCOMP-49 (codecs and version handling must exist first).

Context: The EXOCOMP-8 acceptance criteria require that: official valid fixtures round-trip without semantic loss; malformed/unsupported input returns the correct bounded A2A error; A2A-Version values other than 1.0 fail as designed; and all shared protocol tests pass.

Fixture files:
- Create a test fixtures directory at apps/exocomp_core/test/fixtures/a2a/
- Add the following minimal valid JSON fixture files derived from the A2A 1.0 specification examples:
  - agent_card_minimal.json — minimal valid AgentCard
  - agent_card_full.json — AgentCard with all optional fields populated
  - message_user_text.json — user Message with a TextPart
  - message_agent_data.json — agent Message with a DataPart
  - task_submitted.json — Task in submitted state
  - task_completed_with_artifact.json — Task in completed state with an Artifact containing a TextPart
  - task_failed.json — Task in failed state with status message
  - artifact_text.json — standalone Artifact with TextPart
  - error_invalid_request.json — standard InvalidRequestError JSON
  - error_task_not_found.json — standard TaskNotFoundError JSON
- All fixtures must be valid A2A 1.0 JSON that the codec (EXOCOMP-49) can decode without error
- Fixtures are static files checked into the repo; they should not be auto-generated

Test module: Exocomp.A2A.FixtureTest (apps/exocomp_core/test/exocomp/a2a/fixture_test.exs)
- Round-trip tests: for each fixture, read the JSON file, decode it to the appropriate struct, re-encode to a map, and verify the result equals the original parsed JSON (no semantic loss)
- Include a helper that loads and parses fixture files using File.read! and Jason.decode!

Test module: Exocomp.A2A.InvalidPayloadTest (apps/exocomp_core/test/exocomp/a2a/invalid_payload_test.exs)
- Missing required field: decode a Message without 'role' -> InvalidParamsError (code -32602)
- Missing required field: decode a Task without 'id' -> InvalidParamsError (code -32602)
- Unknown Part type: decode a Part with type 'video' -> UnsupportedOperationError (code -32004)
- Completely invalid JSON structure (passing a string where a map is expected) -> InvalidRequestError (code -32600)
- AgentCard missing 'name' -> InvalidParamsError

Test module: Exocomp.A2A.VersionNegotiationTest (apps/exocomp_core/test/exocomp/a2a/version_negotiation_test.exs)
- A2A-Version: '1.0' -> :ok
- A2A-Version: '2.0' -> {:error, %UnsupportedOperationError{code: -32004}}
- A2A-Version: '0.9' -> {:error, %UnsupportedOperationError{code: -32004}}
- Missing A2A-Version header (nil) -> {:error, %UnsupportedOperationError{code: -32004}}
- Empty string A2A-Version -> {:error, %UnsupportedOperationError{code: -32004}}

Test module: Exocomp.A2A.MediaTypeTest (apps/exocomp_core/test/exocomp/a2a/media_type_test.exs)
- 'application/a2a+json' -> :ok
- 'application/json' -> {:error, %ContentTypeNotSupportedError{code: -32005}}
- 'text/plain' -> {:error, %ContentTypeNotSupportedError{code: -32005}}
- nil -> {:error, %ContentTypeNotSupportedError{code: -32005}}
- 'application/a2a+json; charset=utf-8' (with params) -> :ok (strip params before comparison)

Quality gate: make test && make lint && make fmt-check must pass. All new tests must be green. Verify the full test suite runs cleanly with no regressions against earlier Exocomp.Core and Exocomp.Protocol tests.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

