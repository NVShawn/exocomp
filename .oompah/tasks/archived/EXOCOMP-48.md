---
id: EXOCOMP-48
type: task
status: Archived
priority: null
title: Define A2A 1.0 protocol type structs and task-state enum
parent: EXOCOMP-8
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T20:35:55.059812Z'
updated_at: '2026-07-31T04:20:12.927978Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 19c8b067-3df0-4536-9ca8-69cf50454024
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 1132635
  total_output_tokens: 49444
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1132635
      output_tokens: 49444
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
  - profile: deep
    model: unknown
    input_tokens: 100
    output_tokens: 37597
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:14:38.633115+00:00'
  - profile: auditor
    model: unknown
    input_tokens: 26
    output_tokens: 6022
    cost_usd: 0.0
    recorded_at: '2026-07-31T04:20:10.440696+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-d46d87702794: '2026-07-31T04:20:02.424343+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-3f0cb0e79439
    project_id: proj-c260b117
    task_id: EXOCOMP-48
    target_state: Archived
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 0dc3bb85f98d60b6d5153e0e5f616fe0e7bbefbe663897dfaf0b91ea139311b2
    attempts:
    - version: 1
      attempt_id: attempt-f93eaca2c0eb
      target_state: Archived
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 0dc3bb85f98d60b6d5153e0e5f616fe0e7bbefbe663897dfaf0b91ea139311b2
      created_at: '2026-07-31T04:15:16.573099+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-07-31T04:15:16.573099+00:00'
      branch_key: epic-EXOCOMP-1
      failure_classification: infrastructure_error
      ended_at: '2026-07-31T04:15:20.481354+00:00'
      failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-1'
      next_retry_at: '2026-07-31T04:15:30.481321+00:00'
    - version: 1
      attempt_id: attempt-d46d87702794
      target_state: Archived
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 0dc3bb85f98d60b6d5153e0e5f616fe0e7bbefbe663897dfaf0b91ea139311b2
      created_at: '2026-07-31T04:17:56.974806+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-07-31T04:17:56.974806+00:00'
      branch_key: epic-EXOCOMP-1
      candidate_rotation_count: 1
      verdict: pass
      completed_at: '2026-07-31T04:20:02.424176+00:00'
      ended_at: '2026-07-31T04:20:02.424176+00:00'
    requested_by:
      version: 1
      identity: oompah
      source: auto_archive
    previous_state: Merged
    created_at: '2026-07-31T04:12:34.895577+00:00'
    updated_at: '2026-07-31T04:20:02.424176+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-f93eaca2c0eb
    target_state: Archived
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 0dc3bb85f98d60b6d5153e0e5f616fe0e7bbefbe663897dfaf0b91ea139311b2
    created_at: '2026-07-31T04:15:16.573099+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-07-31T04:15:16.573099+00:00'
    branch_key: epic-EXOCOMP-1
    failure_classification: infrastructure_error
    ended_at: '2026-07-31T04:15:20.481354+00:00'
    failure_reason: 'git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-1'
    next_retry_at: '2026-07-31T04:15:30.481321+00:00'
  - version: 1
    attempt_id: attempt-d46d87702794
    target_state: Archived
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 0dc3bb85f98d60b6d5153e0e5f616fe0e7bbefbe663897dfaf0b91ea139311b2
    created_at: '2026-07-31T04:17:56.974806+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-07-31T04:17:56.974806+00:00'
    branch_key: epic-EXOCOMP-1
    candidate_rotation_count: 1
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
author: oompah
created: 2026-07-23 20:53
---
Retrying (attempt #2, agent: deep)
---
author: oompah
created: 2026-07-23 20:53
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:06
---
Duplicate screening complete: No duplicate found. Reviewed all tasks under EXOCOMP-8 parent epic. EXOCOMP-48 (type structs) is uniquely distinct from EXOCOMP-49 (codecs) and EXOCOMP-51 (fixtures/tests). The done list (EXOCOMP-7, EXOCOMP-41) covers scaffolding and unrelated work. No archived tasks cover A2A type definitions. This is a unique, standalone implementation task. Proceeding with implementation (note: previous Duplicate Investigator agents completed correctly but did not successfully add label/handoff, causing orchestrator to escalate).
---
author: oompah
created: 2026-07-23 21:06
---
Implementation: Creating all A2A 1.0 type struct modules under apps/exocomp_core/lib/exocomp/a2a/. Merged EXOCOMP-7 scaffold (epic-EXOCOMP-1) into working branch to get the Elixir umbrella structure. Implementing 12 struct modules + 11 error modules + TaskState enum.
---
author: oompah
created: 2026-07-23 21:13
---
Verification: All quality gates pass. make test: 66 tests in exocomp_core (all pass, 0 failures), make lint: clean, make fmt-check: clean. Also fixed a Podman rootless container permission issue in the Makefile (added --userns=keep-id) that was preventing any quality gate from running.
---
author: oompah
created: 2026-07-23 21:14
---
Completion: Delivered all A2A 1.0 protocol type struct modules and smoke tests.

Files created (14 modules + 11 test files):
- apps/exocomp_core/lib/exocomp/a2a/: task_state.ex, agent_capabilities.ex, agent_skill.ex, agent_card.ex, text_part.ex, data_part.ex, file_content.ex, file_part.ex, message.ex, artifact.ex, task_status.ex, task.ex, error.ex, errors.ex
- apps/exocomp_core/test/exocomp/a2a/: 11 test files, 66 tests total

Also fixed Podman rootless container permission issue in Makefile (added --userns=keep-id).

Quality gates: make test (68 tests, 0 failures) + make lint + make fmt-check all pass.

Branch epic-EXOCOMP-8 pushed to origin. EXOCOMP-49 (codecs) can now proceed.
---
author: oompah
created: 2026-07-23 21:14
---
Implemented all A2A 1.0 protocol type structs (14 modules) and smoke tests (66 ExUnit tests). All quality gates pass (make test, make lint, make fmt-check). Also fixed Podman --userns=keep-id issue in Makefile.
---
author: oompah
created: 2026-07-23 21:14
---
Agent completed successfully in 1248s (37697 tokens)
---
author: oompah
created: 2026-07-23 21:14
---
Run #3 [attempt=3, profile=deep, role=deep -> Claude/default]
- Turns: 174, Tool calls: 118
- Tokens: 100 in / 37.6K out [37.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 20m 48s
- Log: EXOCOMP-48__20260723T205748Z.jsonl
---
author: oompah
created: 2026-07-31 04:12
---
Queued Archived audit: Aged Merged auto-archive (closed 7 days ago). An auditor will review before the task is retired.
---
author: oompah
created: 2026-07-31 04:15
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-07-31 04:15
---
Run #1 [attempt=1, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 3s
---
author: oompah
created: 2026-07-31 04:15
---
Auditor attempt ended: git worktree add failed: fatal: invalid reference: origin/epic-EXOCOMP-1. A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-07-31 04:17
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-07-31 04:18
---
Focus: Completion Auditor
---
author: oompah
created: 2026-07-31 04:20
---
Audit PASS — Archived

[REDACTED]

Safe evidence:
- commit_sha: f231c41148f86644e9fb74eceaa5ddd30b27892d
- commit_date: 2026-07-23T21:13:59Z
- commit_author: NVShawn <shedwards@nvidia.com>
- source_modules_count: 14
- test_files_count: 11
- working_tree_status: clean
- branch: epic-EXOCOMP-8--task-EXOCOMP-48
- previous_state: Merged
- downstream_tasks_landed: EXOCOMP-49, EXOCOMP-51
---
author: oompah
created: 2026-07-31 04:20
---
Run #2 [attempt=2, profile=auditor, role=auditor -> Claude/sonnet]
- Turns: 55, Tool calls: 38
- Tokens: 26 in / 6.0K out [6.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 13s
- Log: EXOCOMP-48__20260731T041803Z.jsonl
---
<!-- COMMENTS:END -->
