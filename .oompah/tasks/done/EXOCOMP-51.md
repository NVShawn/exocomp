---
id: EXOCOMP-51
type: task
status: Done
priority: null
title: Pin A2A 1.0 fixture files and add comprehensive protocol test suite
parent: EXOCOMP-8
children: []
blocked_by:
- EXOCOMP-49
labels: []
assignee: null
created_at: '2026-07-23T20:36:38.184380Z'
updated_at: '2026-07-23T21:50:42.835673Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 97bda7e8-7d76-43ca-904b-73e10b914126
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 1106283
  total_output_tokens: 34670
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1106283
      output_tokens: 34670
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 451016
    output_tokens: 2864
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:38:35.062815+00:00'
  - profile: standard
    model: unknown
    input_tokens: 655202
    output_tokens: 3914
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:40:53.385195+00:00'
  - profile: deep
    model: unknown
    input_tokens: 65
    output_tokens: 27892
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:50:39.253045+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:36
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:36
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:38
---
Agent completed successfully in 109s (453880 tokens)
---
author: oompah
created: 2026-07-23 21:38
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 17
- Tokens: 451.0K in / 2.9K out [453.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 49s
- Log: EXOCOMP-51__20260723T213650Z.jsonl
---
author: oompah
created: 2026-07-23 21:38
---
Agent completed without closing this issue (109s (453880 tokens)). Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:38
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:38
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:40
---
Agent completed successfully in 123s (659116 tokens)
---
author: oompah
created: 2026-07-23 21:40
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 18
- Tokens: 655.2K in / 3.9K out [659.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 3s
- Log: EXOCOMP-51__20260723T213853Z.jsonl
---
author: oompah
created: 2026-07-23 21:40
---
Agent completed without closing this issue (123s (659116 tokens)). Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
author: oompah
created: 2026-07-23 21:41
---
Retrying (attempt #2, agent: deep)
---
author: oompah
created: 2026-07-23 21:41
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:44
---
Understanding & Plan: This task adds A2A 1.0 fixture JSON files and 4 ExUnit test modules. EXOCOMP-49 (codec + version handling) is merged into the EXOCOMP-51 branch. Work plan: (1) create 10 fixture JSON files in apps/exocomp_core/test/fixtures/a2a/, (2) implement FixtureTest with round-trip tests, (3) implement InvalidPayloadTest for error handling, (4) implement VersionNegotiationTest, (5) implement MediaTypeTest. Note: Version.parse_content_type needs updating to strip params from content-type before matching (for 'application/a2a+json; charset=utf-8' test case). Will run make test + make lint + make fmt-check before committing.
---
author: oompah
created: 2026-07-23 21:50
---
Verification: make test (103 tests, all green), make lint (no warnings), make fmt-check (clean). Test breakdown: 10 fixture round-trips in FixtureTest, 5 invalid payload cases in InvalidPayloadTest, 5 version negotiation cases in VersionNegotiationTest, 5 media type cases in MediaTypeTest. All EXOCOMP-8 acceptance criteria covered.
---
author: oompah
created: 2026-07-23 21:50
---
Completion: Delivered on branch EXOCOMP-51 (built on top of EXOCOMP-49). Added 10 A2A 1.0 fixture JSON files (agent_card_minimal, agent_card_full, message_user_text, message_agent_data, task_submitted, task_completed_with_artifact, task_failed, artifact_text, error_invalid_request, error_task_not_found) and 4 ExUnit test modules (FixtureTest, InvalidPayloadTest, VersionNegotiationTest, MediaTypeTest). Also patched Version.parse_content_type/1 to strip media-type parameters, added /.mix/ to .gitignore. All 103 tests pass, no lint or format issues.
---
author: oompah
created: 2026-07-23 21:50
---
Added 10 A2A 1.0 fixture JSON files and 4 ExUnit test modules (FixtureTest, InvalidPayloadTest, VersionNegotiationTest, MediaTypeTest) covering all EXOCOMP-8 acceptance criteria. Updated parse_content_type to strip media-type params. All 103 tests pass.
---
author: oompah
created: 2026-07-23 21:50
---
Agent completed successfully in 552s (27957 tokens)
---
author: oompah
created: 2026-07-23 21:50
---
Run #3 [attempt=3, profile=deep, role=deep -> Claude/default]
- Turns: 126, Tool calls: 84
- Tokens: 65 in / 27.9K out [28.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 9m 12s
- Log: EXOCOMP-51__20260723T214128Z.jsonl
---
<!-- COMMENTS:END -->
