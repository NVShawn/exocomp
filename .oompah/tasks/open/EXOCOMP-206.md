---
id: EXOCOMP-206
type: task
status: Open
priority: 2
title: Qualify three-path monitoring and Ceph safe restart in VMs
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-194
- EXOCOMP-204
- EXOCOMP-205
- EXOCOMP-155
- EXOCOMP-166
labels: []
assignee: null
created_at: '2026-07-30T21:38:38.730648Z'
updated_at: '2026-08-01T16:30:23.913905Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-206
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 7fc75c750443fd7bdaa314519d5f0f6f6909f7086dd125a5f6b394535b03b490
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T16:30:20.837416+00:00'
  matched_identifiers: []
  evidence: 'Based on my thorough investigation, I can now provide my assessment.


    ## Investigation Summary


    I''ve searched the repository extensively for any existing tasks or qualification
    scenarios that might duplicate EXOCOMP-206. Here''s what I found:


    **Understanding EXOCOMP-206:**

    - Title: "Qualify three-path monitoring and Ceph safe restart in VMs"

    - It''s a qualification/testing task focused on a disposable VM scenario

    - Requirements: three-node Ceph cluster discovery, manual/automatic/cluster-derived
    service expectations, safe daemon restart, audit timeline

    - Deliverable: Make target + qualification evidence


    **Related Infrastructure Tasks (Already Completed):**

    - EXOCOMP-195: Static cluster-profile behavior/registry

    - EXOCOMP-196: Ceph startup validation

    - EXOCOMP-198: Ceph daemon discovery (traditional and cephadm)

    - EXOCOMP-201: Profile-action helper (Ceph v1)

    - EXOCOMP-202: Profile-action helper packaging audit (amd64/arm64)


    **Search Results:**

    - No existing tests or Make targets for "Ceph qualification scenario"

    - No references to "three-path monitoring" or "three-node Ceph" qualification

    - No other tasks covering VM-based Ceph cluster qualification

    - Existing qualification frameworks (M4 fixture service, M5 performance gate,
    M6 release qualification) are distinct and do not cover Ceph-specific scenarios


    **Distinction:**

    - The completed EXOCOMP tasks (195, 196, 198, 201, 202) provide **infrastructure**
    (profiles, helpers, discovery code)

    - EXOCOMP-206 is a **qualification test** that **uses** this infrastructure to
    validate a complete Ceph cluster scenario

    - No active task currently covers this specific qualification scenario


    ---


    **Focus handoff: duplicate_detector**


    **Duplicate preflight verdict: no_duplicate**


    **Matches: none**


    **Evidence:** After searching repository plans, documentation (docs/ and plans/),
    test files, and Makefile targets, no active or terminal task was found covering
    a Ceph three-node cluster qualification scenario with manual/automatic e'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 99bfbc6c-9522-435b-a1a9-60e7a58f381b
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-206
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-206
  base_branch: epic-EXOCOMP-186
  base_sha: 9bd56928c896865de00d10a1f168bcbbaa9abdc9
  updated_at: '2026-08-01T16:27:11.211583+00:00'
oompah.task_costs:
  total_input_tokens: 226
  total_output_tokens: 5530
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 226
      output_tokens: 5530
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 226
    output_tokens: 5530
    cost_usd: 0.0
    recorded_at: '2026-08-01T16:30:20.831533+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-206__20260801T162716Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-186--task-EXOCOMP-206
    source_sha: 9bd56928c896865de00d10a1f168bcbbaa9abdc9
    completed_at: '2026-08-01T16:30:20.845003+00:00'
---
## Summary

Plan: plans/mission-control.md, desired-state and Ceph qualification.

Deliverable: Add a disposable VM qualification scenario covering manual, automatic, and cluster-derived service expectations plus one safe failed Ceph daemon restart.

Acceptance criteria:
- Declare the Ceph profile once on the coordinator and do not maintain per-node Ceph service lists.
- Discover roles across a three-node Ceph cluster and report complete coverage.
- Demonstrate manual and automatic expectations composing with Ceph-derived expectations.
- Fail one expected daemon, open one deduplicated incident, restart exactly once, verify stable Ceph health, and record the full audit timeline.
- Exercise disconnect/replay without duplicate incidents or actions and qualify shipped helper artifacts on amd64 and arm64.

Tests: Add a Make target for the scenario and publish bounded qualification evidence using existing release conventions.

Out of scope: Performance soak and broad Ceph repair operations.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 16:27
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 16:27
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 16:30
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 57, Tool calls: 27
- Tokens: 226 in / 5.5K out [5.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 13s
- Log: EXOCOMP-206__20260801T162716Z.jsonl
---
<!-- COMMENTS:END -->
