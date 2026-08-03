---
id: EXOCOMP-234
type: task
status: Open
priority: 1
title: Remove bypass paths and gate mixed-version management
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-224
- EXOCOMP-227
- EXOCOMP-231
- EXOCOMP-232
- EXOCOMP-233
labels: []
assignee: null
created_at: '2026-08-03T14:26:42.128617Z'
updated_at: '2026-08-03T15:55:48.776287Z'
work_branch: epic-EXOCOMP-211--task-EXOCOMP-234
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: cd750d70f9315356d978c96d0323321e3c39cc84a1ee74afe6144c2c7e8c5173
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:55:43.553090+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: ** A comprehensive scan of the authoritative project\
    \ task corpus (EXOCOMP-10 through EXOCOMP-123) found no active tasks matching\
    \ the scope of EXOCOMP-234. All candidates in the corpus are in terminal states\
    \ (Archived/Merged) and thus ineligible as duplicate targets per project guidelines.\
    \ The scanned tasks cover node diagnostics (M1), coordinator orchestration (M2),\
    \ policies/safety (M3-M4), benchmarking (M5), and release qualification (M6),\
    \ but none address mutation-path inventory, bypass removal, or mixed-version management\
    \ gating\u2014the unique scope of EXOCOMP-234. The task's listed coordination\
    \ peers are absent from the provided corpus, indicating they may have different\
    \ status or timing. No duplicate relationship is confirmed; EXOCOMP-234 should\
    \ proceed to implementation under appropriate focus.\nI'll begin my analysis of\
    \ EXOCOMP-234 to determine if it's a duplicate of an existing task.\n\n## Understanding\
    \ the Current Task\n\n**EXOCOMP-234: \"Remove bypass paths and gate mixed-version\
    \ management\"**\n- Status: Open\n- Type: task\n- Plan reference: plans/hierarchical-management-modes.md\n\
    - Key focus: \n  - Complete mutation-path inventory\n  - Remove broker bypasses\n\
    \  - Gate mixed-version management\n  - Prevent manage activation for unsupported\
    \ targets\n  - Agent Cards advertise versions\n  - Static checks for mutations\n\
    \n## Analysis of Task Corpus\n\nI've reviewed the provided authoritative task\
    \ corpus covering the project tracker. The corpus contains numerous tasks (EXOCOMP-10\
    \ through EXOCOMP-123) organized by milestone (M1-M6) and functional areas:\n\n\
    **Scanned categories:**\n- **Diagnostics & Collectors**: EXOCOMP-10 (node collectors,\
    \ Archived)\n- **Coordinator Infrastructure**: EXOCOMP-14, 15, 100-105 (Archived)\n\
    - **A2A/Protocol**: EXOCOMP-8, 12, 111 (Archived)\n- **Management & Enrollment**:\
    \ EXOCOMP-107, 119 (Archived)\n- **Release & Quality**: EXOCOMP-118-123 (Archived)\n\
    - **Recovery & Rebase**: EXOCOMP-106-116 (Archived)\n\n**Key finding:** All tasks\
    \ in the provided corpus are in **terminal states** (Archived or Merged). No active\
    \ Open tasks exist in the provided corpus other than EXOCOMP-234 itself.\n\nThe\
    \ task's coordination peers (EXOCOMP-224, 225, 226, etc.) are not present in the\
    \ provided corpus, suggesting they either have different statuses or were created\
    \ after the corpus snapshot.\n\n---\n\n**Focus handoff: duplicate_detector**\n\
    \n**Duplicate preflight verdict: no_duplicate**\n\n**Matches: none**\n\n**Evidence:**\
    \ A comprehensive scan of the authoritative project task corpus (EXOCOMP-10 through\
    \ EXOCOMP-123) found no active tasks matching the scope of EXOCOMP-234. All candidates\
    \ in the corpus are in terminal states (Archived/Merged) and thus ineligible as\
    \ duplicate targets per project guidelines. The scanned tasks cover node diagnostics\
    \ (M1), coordinator orchestration (M2), policie"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 2
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 0f778316-132e-4cee-9d0a-9ac3a1131616
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-234
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-234
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:54:21.651004+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-234__20260803T154721Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-234
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:47:57.386796+00:00'
  - run_id: EXOCOMP-234__20260803T155035Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-234
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:51:09.959434+00:00'
  - run_id: EXOCOMP-234__20260803T155425Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-234
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:55:43.561075+00:00'
oompah.task_costs:
  total_input_tokens: 333783
  total_output_tokens: 4791
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 333783
      output_tokens: 4791
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 168920
    output_tokens: 1404
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:47:57.377389+00:00'
  - profile: default
    model: haiku
    input_tokens: 164853
    output_tokens: 1143
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:51:09.950045+00:00'
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2244
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:55:43.552821+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Complete the mutation-path inventory, remove remaining broker bypasses, and prevent manage activation for unsupported targets.

Acceptance criteria:
- A source and packaged-artifact inventory proves every mutation reaches the broker.
- Agent Cards/status advertise management-policy and broker protocol versions.
- Mission Control rejects manage activation when the affected scope includes any unsupported node and reports those nodes.
- Direct calls to old executor/helper entry points fail without mutation.
- Static checks reject new direct sudo mutation commands or unregistered state-changing skills.

Tests: Add mixed-version scope tests, unsupported-node UI/API tests, source/package scans, old-entry-point negative tests, Agent Card contract tests, and regression fixtures for every current action; run make test, make test-installer, make test-release-packaging, make fmt-check, and make lint.

Out of scope: Operator documentation and release qualification.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:47
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:47
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:47
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 1
- Tokens: 168.9K in / 1.4K out [170.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 43s
- Log: EXOCOMP-234__20260803T154721Z.jsonl
---
author: oompah
created: 2026-08-03 15:50
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:50
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:51
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 0
- Tokens: 164.9K in / 1.1K out [166.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 45s
- Log: EXOCOMP-234__20260803T155035Z.jsonl
---
author: oompah
created: 2026-08-03 15:54
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:54
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:55
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 2.2K out [2.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 31s
- Log: EXOCOMP-234__20260803T155425Z.jsonl
---
<!-- COMMENTS:END -->
