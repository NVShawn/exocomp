---
id: EXOCOMP-222
type: task
status: Open
priority: 1
title: Validate and atomically cache policy in the coordinator
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-219
- EXOCOMP-221
labels: []
assignee: null
created_at: '2026-08-03T14:25:16.130462Z'
updated_at: '2026-08-03T15:39:22.573400Z'
work_branch: epic-EXOCOMP-210--task-EXOCOMP-222
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 0297af041b74041ff78584c2abeb940314b7710947edbfa7348b6e5ad24424ba
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:39:17.287018+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: Duplicate preflight verdict: no_duplicate\nMatches: none\n\
    **Focus handoff: duplicate_detector**\n\n**Duplicate preflight verdict: no_duplicate**\n\
    \n**Matches: none**\n\n**Evidence:**\n\nAfter reviewing the complete authoritative\
    \ task corpus covering EXOCOMP-10 through EXOCOMP-123 (all in terminal states),\
    \ no active duplicate of EXOCOMP-222 exists. The current task's scope\u2014validating\
    \ and atomically caching signed cluster policy bundles with multi-faceted checks\
    \ (signature, identity, schema, monotonic version, expiry, lease bounds, replay\
    \ detection) and idempotent acknowledgement\u2014is distinct from all reviewed\
    \ tasks.\n\nThe closest related tasks are:\n- **EXOCOMP-16** (Archived): Coordinator\
    \ CA initialization and enrollment tokens\u2014focuses on PKI bootstrap and node-bound\
    \ token issuance, not cluster policy caching.\n- **EXOCOMP-119** (Archived): Production\
    \ coordinator PKI and enrollment services\u2014wires coordinator startup and enrollment\
    \ flow, not policy ingestion.\n- **EXOCOMP-14** (Archived): Coordinator scaffold\u2014\
    provides inventory, registry, and audit foundations used across coordinator subsystems,\
    \ but does not implement policy bundle handling.\n\nEXOCOMP-222's dependencies\
    \ list (EXOCOMP-210, 219\u2013224, 228) fall outside the provided corpus (higher-numbered,\
    \ likely not yet shown), so the assessment is based on the authoritative available\
    \ data. No terminal task contains overlapping policy-cache validation/installation\
    \ logic.\n\nThe task is ready for implementation under the appropriate focus specialist."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: c92b970d-2fb1-489d-a0b3-107206508a12
oompah.work_branch: epic-EXOCOMP-210--task-EXOCOMP-222
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-210--task-EXOCOMP-222
  base_branch: epic-EXOCOMP-210
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:37:12.055842+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 2222
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 2222
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2222
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:39:17.286169+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-222__20260803T153717Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-210--task-EXOCOMP-222
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:39:17.290715+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add coordinator ingestion and protected durable caching for signed cluster policy bundles.

Acceptance criteria:
- Validate signature, signing-key ID, organization/cluster identity, schema, monotonic version, issue time, expiry, and lease bounds before replacement.
- Install the complete bundle atomically; any failure retains the previous valid bundle.
- Restart reloads and revalidates the cache before use.
- Missing, corrupt, expired, replayed, wrong-cluster, or invalid policy resolves to observe with a structured audit reason.
- A valid install emits an idempotent acknowledgement.

Tests: Cover valid replacement, stale and duplicate version, wrong identity, tamper, partial write, fsync/rename failure, corrupt cache, restart, expiry, and acknowledgement retry; run make test, make fmt-check, and make lint.

Out of scope: Lease scheduling, execution permits, and broker calls.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:37
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:37
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:39
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 2.2K out [2.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 10s
- Log: EXOCOMP-222__20260803T153717Z.jsonl
---
<!-- COMMENTS:END -->
