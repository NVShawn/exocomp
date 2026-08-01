---
id: EXOCOMP-200
type: task
status: In Progress
priority: 1
title: Reduce Ceph evidence into cluster and daemon health
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-199
labels: []
assignee: null
created_at: '2026-07-30T21:38:25.539449Z'
updated_at: '2026-08-01T21:49:04.906363Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-200
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 946d42eaaec9825a35a0c808c9ec0e3b5b6a93248a8f532288781895a6061bdc
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:14:18.422397+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active EXOCOMP-195, 196, 197, 198, 199,\
    \ 201\u2013206, 155, 163, 166, 177, 178, 182, 185, 186, 191, and 194. Closest\
    \ tasks separately cover Ceph collection, topology mapping, daemon discovery,\
    \ profile registry/configuration, recovery, and incident reduction; none covers\
    \ reducing evidence into cluster and daemon health. Terminal tasks were excluded."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 5eb9d376-8230-40be-92a6-80d42f095781
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-200
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-200
  base_branch: epic-EXOCOMP-186
  base_sha: 0314c58199acb476c7384be42e88291af1beea95
  updated_at: '2026-08-01T21:42:18.900556+00:00'
oompah.task_costs:
  total_input_tokens: 606833
  total_output_tokens: 4046
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 606833
      output_tokens: 4046
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 606833
    output_tokens: 4046
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:14:18.421787+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-200__20260801T141247Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-186--task-EXOCOMP-200
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:14:18.427696+00:00'
---
## Summary

Plan: plans/mission-control.md, Ceph cluster health.

Deliverable: Convert fresh Ceph CLI evidence, topology mappings, and node observations into profile, coverage, and daemon health states.

Acceptance criteria:
- HEALTH_OK maps to healthy, HEALTH_WARN to degraded, and HEALTH_ERR to critical.
- Missing credentials, stale evidence, incomplete coverage, and ambiguous topology have distinct reasons.
- Required daemon units are healthy only when their expected systemd state and applicable profile evidence pass.
- Results contain bounded evidence references and deterministic severity.

Tests: Add table-driven tests for health levels, stale and partial evidence, missing daemons, unreachable nodes, unsupported profile versions, and recovery to healthy; run make test.

Out of scope: Mission Control incident records, UI, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:12
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:12
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:14
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 13
- Tokens: 606.8K in / 4.0K out [610.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 39s
- Log: EXOCOMP-200__20260801T141247Z.jsonl
---
author: oompah
created: 2026-08-01 21:42
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 21:42
---
Focus: Callback Auth Validation Specialist
---
author: oompah
created: 2026-08-01 21:43
---
UNDERSTANDING: Task is to reduce Ceph CLI evidence, topology mappings, and node observations into health states. Acceptance criteria: map HEALTH_OK/WARN/ERR to healthy/degraded/critical; distinguish reasons for stale/missing evidence; validate daemon units against systemd state and profile evidence; bounded evidence references with deterministic severity. Approach: explore existing code from integrated dependencies, identify what health reduction logic is needed, implement with table-driven tests covering health levels, stale evidence, partial evidence, missing daemons, unreachable nodes, unsupported profiles, and recovery scenarios.
---
author: oompah
created: 2026-08-01 21:49
---
DISCOVERY: Found integrated dependencies including Ceph evidence collector (EXOCOMP-197), topology correlation (EXOCOMP-199), and profile infrastructure. Existing code provides: raw CLI evidence collection, topology-to-inventory mapping, profile coverage tracking, and basic health_reduction in ClusterProfile.Ceph. Task requires implementing a comprehensive health reduction system that: (1) converts Ceph status (HEALTH_OK/WARN/ERR) to severity states (healthy/degraded/critical); (2) tracks stale/missing evidence and coverage gaps; (3) validates daemon units against systemd and profile evidence; (4) bounds evidence references. Plan to create CephHealthReducer module with table-driven tests covering health levels, partial evidence, missing daemons, unreachable nodes, and profile version issues.
---
<!-- COMMENTS:END -->
