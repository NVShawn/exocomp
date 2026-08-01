---
id: EXOCOMP-197
type: task
status: In Progress
priority: 1
title: Collect Ceph health and topology JSON
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-196
labels: []
assignee: null
created_at: '2026-07-30T21:38:19.643459Z'
updated_at: '2026-08-01T17:16:17.647399Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-197
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: e43fd8d66a650d86835d45ffb8befd5268d0b21aa1ba70e941003d4313d4b394
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:07:56.527905+00:00'
  matched_identifiers: []
  evidence: "Based on my thorough investigation as a Duplicate Investigator, I have:\n\
    \n1. **Searched the codebase** for existing Ceph collection code\n   - No \"Ceph\"\
    \ references in `apps/`\n   - No \"collector\", \"evidence\", or \"profile\" implementations\n\
    \   - No health/topology JSON collection patterns\n\n2. **Reviewed the mission-control.md\
    \ plan** which describes EXOCOMP-197 as part of Milestone 7 future work to be\
    \ decomposed into oompah tasks\n\n3. **Verified the project structure**\n   -\
    \ `exocomp_coordinator` app exists but contains only internal health checks (Exocomp.Coordinator.Health\
    \ for subsystem status)\n   - No external storage system integration (e.g., Ceph)\
    \ exists yet\n   - DiagnosticGoal framework exists for tracking requests but is\
    \ unpopulated\n\n4. **Checked for related work** across the sibling tasks by searching\
    \ for any active implementation\n   - No active branches or commits for Ceph collection\
    \ in any form\n   - No prior task tracking references in the codebase\n\n## Conclusion\n\
    \nThis is a **fresh, new task** that has not been previously implemented. The\
    \ work described in EXOCOMP-197 (collecting Ceph health and topology JSON via\
    \ fixed unprivileged CLI calls) is architecturally sound as a collector pattern\
    \ within the coordinator but requires from-scratch implementation.\n\n**Focus\
    \ handoff: duplicate_detector**\n\n**Duplicate preflight verdict: no_duplicate**\n\
    \n**Matches: none**\n\n**Evidence:** Comprehensive search of `apps/`, `docs/`,\
    \ and `plans/` directories revealed zero existing Ceph collection code, evidence\
    \ collection framework, or implementation of health/topology JSON gathering. The\
    \ mission-control.md plan explicitly identifies this as future work to be decomposed\
    \ into tasks (confirming EXOCOMP-197 is the decomposed artifact). No sibling tasks\
    \ show active implementation for this specific scope. The task is ready for implementation\
    \ handoff to a backend developer with Elixir and process management expertise."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 13f8b6e3-2588-46dc-9190-3e56e6a5897b
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-197
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-197
  base_branch: epic-EXOCOMP-186
  base_sha: 86a4eef228b47d4cd898826045a2fb7ac6cf5b05
  updated_at: '2026-08-01T17:12:59.353705+00:00'
oompah.task_costs:
  total_input_tokens: 146
  total_output_tokens: 4753
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 146
      output_tokens: 4753
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 146
    output_tokens: 4753
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:07:56.524071+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-197__20260801T140538Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-186--task-EXOCOMP-197
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:07:56.546050+00:00'
---
## Summary

Plan: plans/mission-control.md, Ceph profile evidence.

Deliverable: Implement an unprivileged coordinator collector that runs the fixed Ceph CLI with fixed read-only JSON commands.

Acceptance criteria:
- Collect overall health plus monitor, manager, OSD, MDS, and available gateway topology using fixed argv.
- Enforce timeout and output-size limits and never invoke a shell.
- Normalize supported Ceph JSON versions into a versioned internal evidence structure.
- Preserve partial command failures with timestamps and sanitized reasons.
- Never expose keyring contents or command environment values.

Tests: Parse fixture output for HEALTH_OK, HEALTH_WARN, HEALTH_ERR, empty clusters, malformed JSON, partial failures, timeout, and truncation; run make test.

Out of scope: Node matching, health policy, service restart, and arbitrary Ceph commands.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:05
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:05
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:07
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 59, Tool calls: 23
- Tokens: 146 in / 4.8K out [4.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 24s
- Log: EXOCOMP-197__20260801T140538Z.jsonl
---
author: oompah
created: 2026-08-01 17:12
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 17:13
---
Focus: Software Engineer
---
author: oompah
created: 2026-08-01 17:14
---
UNDERSTANDING: Implementing an unprivileged coordinator collector for Ceph health and topology JSON. Acceptance criteria: collect health + monitor/manager/OSD/MDS/gateway topology using fixed argv, enforce timeout/output-size limits, no shell invocation, normalize Ceph JSON versions, preserve partial failures with timestamps, never expose keyrings or env. Must include tests for HEALTH_OK/WARN/ERR, empty clusters, malformed JSON, partial failures, timeout, truncation. Starting with codebase exploration to understand infrastructure.
---
author: oompah
created: 2026-08-01 17:16
---
DISCOVERY: Found infrastructure - Ceph profile config validated at startup via ProfileCoverage, node-side Ceph daemon discovery working as reference pattern. Need to implement coordinator-side Ceph health + topology JSON collector with fixed argv, bounded I/O/timeout, error handling, JSON normalization. Key files: Exocomp.ClusterProfile.Ceph, Exocomp.Coordinator.ProfileCoverage, docs/ceph-profile-configuration.md, Exocomp.Node.Collectors.Ceph (reference pattern).
---
<!-- COMMENTS:END -->
