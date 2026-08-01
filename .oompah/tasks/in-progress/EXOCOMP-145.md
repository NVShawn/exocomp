---
id: EXOCOMP-145
type: task
status: In Progress
priority: 1
title: Add optional Mission Control coordinator configuration
parent: EXOCOMP-130
children: []
blocked_by:
- EXOCOMP-139
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:01.267951Z'
updated_at: '2026-08-01T12:15:55.279679Z'
work_branch: epic-EXOCOMP-130--task-EXOCOMP-145
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 30ddb9d816071439d009ad0069001d7e1303da35f2e4e0d737ab3be8cb53c5d5
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:10:57.090526+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active EXOCOMP-139, EXOCOMP-144, EXOCOMP-146,\
    \ EXOCOMP-147, EXOCOMP-148, EXOCOMP-149, EXOCOMP-150, and EXOCOMP-151. Their scopes\
    \ cover protocol, PKI renewal, transport, runtime backoff, persistence, ingestion,\
    \ and commands respectively; none duplicates EXOCOMP-145\u2019s configuration\
    \ and supervision scope."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 78c3ce40-8d49-4542-b20c-d428a58e515c
oompah.work_branch: epic-EXOCOMP-130--task-EXOCOMP-145
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-130--task-EXOCOMP-145
  base_branch: epic-EXOCOMP-130
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:11:09.556205+00:00'
oompah.task_costs:
  total_input_tokens: 744316
  total_output_tokens: 4014
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 744316
      output_tokens: 4014
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 744316
    output_tokens: 4014
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:10:57.089805+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-145__20260801T120915Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-130--task-EXOCOMP-145
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:10:57.105971+00:00'
---
## Summary

Plan: plans/mission-control.md, Rollout and Connection Protocol.

Deliverables:
- Add a versioned coordinator configuration block for Mission Control URL, trust root, client certificate/key paths, heartbeat interval, reconnect bounds, and outbox path.
- Validate paths, TLS settings, and numeric bounds at startup.
- Start the Mission Control client supervision subtree only when the block is present and enabled.

Acceptance:
- Existing coordinator behavior is unchanged when configuration is absent.
- Invalid partial configuration fails with actionable bounded errors.
- Tests prove Mission Control disablement cannot stop local inventory, diagnostics, or recovery.

Out of scope: network connections and enrollment.
Quality gate: focused configuration/supervision tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:09
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:09
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:10
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 13
- Tokens: 744.3K in / 4.0K out [748.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 49s
- Log: EXOCOMP-145__20260801T120915Z.jsonl
---
author: oompah
created: 2026-08-01 12:11
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:11
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 12:11
---
Understanding: Adding optional Mission Control coordinator configuration. Plan: 1) Extend Config module to add versioned mission_control block (URL, trust root, cert/key paths, heartbeat interval, reconnect bounds, outbox path). 2) Validate paths exist, TLS settings are valid, and numeric bounds are reasonable at startup. 3) Create a supervision subtree for Mission Control client (supervisor, connection handler, outbox manager) that only starts when config is present and enabled. 4) Ensure existing coordinator behavior is unchanged when config absent. 5) Write focused tests for config validation and supervision tree behavior.
---
author: oompah
created: 2026-08-01 12:15
---
Discovery: Extended Config module to support optional Mission Control configuration block with versioned schema (v1). Config includes URL, trust root, client cert/key paths, heartbeat interval, reconnect bounds, and outbox path. Validation handles: required field checks when enabled, file path existence, numeric bounds (heartbeat > 0, min_backoff > 0, max_backoff >= min_backoff), and directory writable checks. All 518 existing tests still pass. Now creating supervision tree for optional Mission Control client.
---
<!-- COMMENTS:END -->
