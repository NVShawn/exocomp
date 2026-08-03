---
id: EXOCOMP-243
type: bug
status: In Progress
priority: 2
title: Remove peer-completion race from discovery polling test
parent: null
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-08-03T17:22:52.388724Z'
updated_at: '2026-08-03T17:32:28.734544Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 08c45398fd051cf1c3ffd50d5d7fb3fc0141712ef7815a361d42df4eb09927d0
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T17:29:18.210867+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: Reviewed the supplied task corpus. EXOCOMP-121 and EXOCOMP-15\
    \ are related but terminal (Archived), so neither qualifies as an active duplicate.\
    \ No clear active duplicate was present.\nFocus handoff: duplicate_detector  \n\
    Duplicate preflight verdict: no_duplicate  \nMatches: none  \n\nEvidence: Reviewed\
    \ the supplied task corpus. EXOCOMP-121 and EXOCOMP-15 are related but terminal\
    \ (Archived), so neither qualifies as an active duplicate. No clear active duplicate\
    \ was present."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: c3bae8fe-2d92-45cc-b6a3-f0681659abd4
oompah.task_costs:
  total_input_tokens: 48318
  total_output_tokens: 582
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 48318
      output_tokens: 582
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 48318
    output_tokens: 582
    cost_usd: 0.0
    recorded_at: '2026-08-03T17:29:18.209314+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-243__20260803T172843Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: EXOCOMP-243
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T17:29:18.218435+00:00'
---
## Summary

Triggered by: EXOCOMP-92

The full make test gate is nondeterministic in apps/exocomp_coordinator/test/exocomp/coordinator/multi_node_discovery_polling_test.exs. The test 'unreachable node retains previously verified addresses and increments failure counter' waits only for the unreachable echo result, then immediately asserts that independently scheduled foxtrot is healthy. Under valid task interleavings foxtrot remains :unknown for that instant and the gate fails. Synchronize on the peer outcome (or complete poller drain) before asserting it, while retaining assertions that the unreachable node preserves its verified address and increments its failure counter. Reproduce with repeated focused runs and verify make test and make lint pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 17:26
---
Operator workaround is validated and published in merge commit 24f84e9459c72cb9354dc47e6f531118e14fcfaa on epic-EXOCOMP-132. The test now waits for the independently scheduled peer result before asserting it. The focused case passed 50 repeat-until-failure runs; full make test passed 682 tests plus release smoke tests, and make lint passed. Permanent repair still belongs on the authoritative parent/main path, so this task is being returned to Open for normal server implementation/integration.
---
author: oompah
created: 2026-08-03 17:28
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 17:28
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 17:29
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 0
- Tokens: 48.3K in / 582 out [48.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 41s
- Log: EXOCOMP-243__20260803T172843Z.jsonl
---
author: oompah
created: 2026-08-03 17:29
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-03 17:29
---
Focus: Test Engineer
---
author: oompah
created: 2026-08-03 17:30
---
Understanding: This is a nondeterministic test in multi_node_discovery_polling_test.exs. The test 'unreachable node retains previously verified addresses and increments failure counter' has a race condition where it waits only for the unreachable echo result, then immediately asserts that the independently scheduled foxtrot peer is healthy. Under valid task interleavings, foxtrot may remain :unknown, causing intermittent failures. The fix is to synchronize on the peer outcome before asserting, while preserving assertions about the unreachable node's state. Previous work on epic-EXOCOMP-132 successfully validated this fix with 50 repeat runs and full test gate passage. I'll locate the test, apply the synchronization fix, and verify with repeated test runs.
---
author: oompah
created: 2026-08-03 17:32
---
Discovery: Found the test 'unreachable node retains previously verified addresses and increments failure counter' in apps/exocomp_coordinator/test/exocomp/coordinator/multi_node_discovery_polling_test.exs. The race condition exists on lines 425-428. After waiting for echo to become :unreachable via eventually block, the test immediately fetches foxtrot and asserts it's healthy WITHOUT waiting for foxtrot's probe to complete. With concurrency: 3, foxtrot's probe runs in parallel with echo's, and foxtrot may still be :unknown when the assertion runs, causing intermittent failures. Fix: Add eventually block to wait for foxtrot (or all pollers) to complete before asserting.
---
<!-- COMMENTS:END -->
