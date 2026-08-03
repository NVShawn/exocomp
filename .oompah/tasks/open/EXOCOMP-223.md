---
id: EXOCOMP-223
type: task
status: Open
priority: 1
title: Renew policy leases and fall back to observe on expiry
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-222
labels: []
assignee: null
created_at: '2026-08-03T14:25:17.678179Z'
updated_at: '2026-08-03T15:43:09.435490Z'
work_branch: epic-EXOCOMP-210--task-EXOCOMP-223
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 4aa594617a73fcff8ea1298cd2434863dbcb70c2bcc95f33feb06fe8b164e5e1
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:43:01.952544+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: Duplicate preflight verdict: no_duplicate\nMatches: none\n\
    I'm investigating whether EXOCOMP-223 is a duplicate of an existing issue. Let\
    \ me analyze the task corpus.\n\n## Analysis\n\n**Current Task:** EXOCOMP-223\
    \ - \"Renew policy leases and fall back to observe on expiry\"\n- Focus: Policy\
    \ lease renewal, lease configuration validation, expiry atomicity, mandatory reconnect\n\
    - References: plans/hierarchical-management-modes.md\n- Related: Epic parent EXOCOMP-210,\
    \ siblings EXOCOMP-219/220/221/222/224, dependencies EXOCOMP-127/227\n\n**Corpus\
    \ Search Results:**\n\nI've reviewed all 40+ tasks in the provided corpus. The\
    \ tasks fall into these categories:\n1. **M1 Node Agent** (EXOCOMP-7 through EXOCOMP-13):\
    \ Diagnostic collectors, A2A service, llama.cpp supervision \u2014 no lease renewal\n\
    2. **M2 Coordinator Foundations** (EXOCOMP-14, EXOCOMP-15, EXOCOMP-88-92): Inventory,\
    \ DNS discovery, polling \u2014 no lease management\n3. **M2 Diagnostics** (EXOCOMP-100-105):\
    \ Task store, orchestration, cancellation, audit \u2014 no lease renewal\n4. **M2\
    \ PKI/Enrollment** (EXOCOMP-107, EXOCOMP-119): Node enrollment, credential management\
    \ \u2014 distinct from policy leases\n5. **Release & Qualification** (EXOCOMP-118,\
    \ EXOCOMP-120-123): Bundle hardening, performance gates \u2014 distinct scope\n\
    6. **Recovery & Rebasing** (EXOCOMP-106-116): Epic rebasing, work recovery \u2014\
    \ infrastructure, not policy\n\n**Key Finding:** No task in the corpus describes\
    \ policy lease renewal, lease configuration validation (60-3600s bounds), expiry\
    \ switching to observe mode, or the hierarchical management mode lease timer behavior.\n\
    \nThe closest task by topic is **EXOCOMP-119** (coordinator PKI/enrollment services),\
    \ but it covers enrollment certificate management and mTLS renewal \u2014 a distinct\
    \ subsystem from policy bundle lease renewal.\n\n---\n\n**Focus handoff: duplicate_detector**\n\
    \n**Duplicate preflight verdict: no_duplicate**\n\n**Matches: none**\n\n**Evidence:**\n\
    \nSearched all 40+ active and archived tasks in the corpus for \"lease\", \"renewal\"\
    , \"expiry\", \"observe mode\", \"policy\", or \"hierarchical management\". EXOCOMP-22"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 8255d19a-c0b8-4e45-9d14-1400c0ec5602
oompah.work_branch: epic-EXOCOMP-210--task-EXOCOMP-223
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-210--task-EXOCOMP-223
  base_branch: epic-EXOCOMP-210
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:41:25.369428+00:00'
oompah.task_costs:
  total_input_tokens: 317987
  total_output_tokens: 3397
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 317987
      output_tokens: 3397
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 317977
    output_tokens: 1520
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:38:55.648375+00:00'
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1877
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:43:01.045936+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-223__20260803T153747Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-210--task-EXOCOMP-223
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:38:55.670617+00:00'
  - run_id: EXOCOMP-223__20260803T154129Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-210--task-EXOCOMP-223
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:43:01.052578+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add Mission Control renewal and coordinator lease-timer behavior with a five-minute default and validated configuration.

Acceptance criteria:
- Lease configuration accepts 60 through 3600 seconds; renewal defaults to 60 seconds and must be below half the lease.
- Mission Control issues fresh signed bundles without changing policy version when only the lease changes.
- Coordinator timers use monotonic time while running and validated wall time after restart.
- Expiry atomically switches all effective policy to observe, invalidates pending execution, and writes durable audit state.
- Reconnect requires a fresh bundle before manage resumes.

Tests: Use injectable clocks for bounds, renewal, delayed delivery, disconnect, clock movement, restart before/after expiry, invalid configuration, pending-work invalidation, and reconnection; run make test, make fmt-check, and make lint.

Out of scope: Action execution and LiveView rendering.

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
created: 2026-08-03 15:38
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 3
- Tokens: 318.0K in / 1.5K out [319.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 24s
- Log: EXOCOMP-223__20260803T153747Z.jsonl
---
author: oompah
created: 2026-08-03 15:41
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:41
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:43
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 1.9K out [1.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 41s
- Log: EXOCOMP-223__20260803T154129Z.jsonl
---
<!-- COMMENTS:END -->
