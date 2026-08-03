---
id: EXOCOMP-214
type: task
status: Open
priority: 1
title: Map systemd and profile targets to canonical service keys
parent: EXOCOMP-209
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-213
labels: []
assignee: null
created_at: '2026-08-03T14:24:11.664051Z'
updated_at: '2026-08-03T15:35:44.941078Z'
work_branch: epic-EXOCOMP-209--task-EXOCOMP-214
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 6c7da08549a6c621212b6b3d5f0b06918329b6042465d72aaf01e19d194e7015
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:35:37.798809+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: Reviewed all 31 tasks in the provided authoritative corpus\
    \ (EXOCOMP-10 through EXOCOMP-15, EXOCOMP-100-EXOCOMP-123). No task covers mapping\
    \ systemd units and profiles to canonical service keys. Closest related work is\
    \ EXOCOMP-10 (systemd service collection) and EXOCOMP-14 (coordinator infrastructure),\
    \ but both are orthogonal to service-key mapping. The epic-parent EXOCOMP-209\
    \ and coordination siblings (EXOCOMP-213, 215, 216, 217, 218) are not in the provided\
    \ corpus, but EXOCOMP-214's stated scope is unique within the available task graph.\n\
    I'll begin my duplicate investigation by carefully reviewing the provided task\
    \ corpus and searching for any existing tasks that address the same scope as EXOCOMP-214.\n\
    \n**Understanding EXOCOMP-214:**\n- Title: Map systemd and profile targets to\
    \ canonical service keys\n- Scope: Add a shared canonical service-key mapper that\
    \ normalizes systemd units (\u2192 `systemd:<unit>`) and profiles (\u2192 `ceph:mon`,\
    \ `ceph:mgr`, `ceph:osd`, etc.)\n- Key aspects: Deterministic mapping, error handling\
    \ for unknown profiles/malformed units, usable across coordinator/node/broker/fixtures\n\
    - Epic parent: EXOCOMP-209 (hierarchical-management-modes)\n- Coordination peers:\
    \ EXOCOMP-127, 213, 215, 216, 217, 218\n\n**Reviewing the provided corpus:**\n\
    \nI've examined all tasks in the provided authoritative task corpus (EXOCOMP-10\
    \ through EXOCOMP-15, EXOCOMP-100-EXOCOMP-123). None address the scope of mapping\
    \ systemd units and profiles to canonical service keys:\n\n- **EXOCOMP-10** (Archived):\
    \ Implements Linux/systemd diagnostic *collectors* (CPU, memory, disk, uptime,\
    \ systemd service state) \u2014 not service-key mapping\n- **EXOCOMP-12** (Archived):\
    \ Exposes diagnostic-only A2A service endpoints \u2014 not service-key mapping\n\
    - **EXOCOMP-14** (Archived): Scaffolds coordinator inventory/registry/audit \u2014\
    \ infrastructure, not service-key mapping\n- **EXOCOMP-100 through EXOCOMP-105**\
    \ (Archived): Coordinator goal store, orchestration, audit, restart recovery \u2014\
    \ all focused on diagnostic task orchestration, not service keys\n- **EXOCOMP-118\
    \ through EXOCOMP-123** (Archived): Release candidate qualification, bundle reproducibility,\
    \ PKI services \u2014 not service-key mapping\n\n**Observation:**\n\nThe provided\
    \ corpus is focused on foundation work for M1-M6 (node agents, coordinator infrastructure,\
    \ release). EXOCOMP-214 belongs to the hierarchical-management-modes epic (EXOCOMP-209),\
    \ which addresses a distinct domain: translating heterogeneous service identifiers\
    \ (systemd units, Ceph daemon profiles) into a canonical representation for policy"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 1
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 50c8a206-fa7d-4adc-ae0d-61c515dcd5ae
oompah.work_branch: epic-EXOCOMP-209--task-EXOCOMP-214
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-209--task-EXOCOMP-214
  base_branch: epic-EXOCOMP-209
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:33:36.854320+00:00'
oompah.task_costs:
  total_input_tokens: 430081
  total_output_tokens: 4329
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 430081
      output_tokens: 4329
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 430071
    output_tokens: 2160
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:30:58.836188+00:00'
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2169
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:35:37.786161+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-214__20260803T153000Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-209--task-EXOCOMP-214
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:30:58.865901+00:00'
  - run_id: EXOCOMP-214__20260803T153348Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-209--task-EXOCOMP-214
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:35:37.816989+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add the shared canonical service-key mapper used before policy resolution.

Acceptance criteria:
- Exact systemd units map to systemd:<unit> after existing strict unit validation.
- Shipped profiles map daemon instances to stable keys such as ceph:mon, ceph:mgr, and ceph:osd.
- Unknown profiles, malformed units, ambiguous mappings, and missing keys fail to observe with structured reasons.
- Mapping is deterministic across coordinator, node, broker, and serialized fixtures.

Tests: Cover ordinary and templated systemd units, every shipped Ceph role, multiple daemon instances, invalid names, unknown profiles, and fixture round trips; run make test, make fmt-check, and make lint.

Out of scope: Policy precedence, desired-service discovery, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:29
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:29
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:31
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 5
- Tokens: 430.1K in / 2.2K out [432.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 14s
- Log: EXOCOMP-214__20260803T153000Z.jsonl
---
author: oompah
created: 2026-08-03 15:33
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:33
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:35
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 2.2K out [2.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 11s
- Log: EXOCOMP-214__20260803T153348Z.jsonl
---
<!-- COMMENTS:END -->
