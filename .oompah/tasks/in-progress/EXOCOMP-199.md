---
id: EXOCOMP-199
type: task
status: In Progress
priority: 1
title: Correlate Ceph topology with coordinator inventory nodes
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-189
- EXOCOMP-197
- EXOCOMP-198
labels: []
assignee: null
created_at: '2026-07-30T21:38:23.958273Z'
updated_at: '2026-08-01T18:39:09.151982Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-199
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 8866e61026aca03ffd41b1ff7c3aff9c96ceb6301d0967ce43c4b023751eb487
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:12:18.723028+00:00'
  matched_identifiers: []
  evidence: 'Based on my comprehensive investigation, I''ve searched for existing
    tasks and code that might overlap with EXOCOMP-199 ("Correlate Ceph topology with
    coordinator inventory nodes"). Here''s what I found:


    ## Investigation Summary


    **Searches Performed:**

    - Searched `.oompah/tasks` for Ceph, topology, inventory, coordinator, daemon,
    reconciliation, mapping, and correlation keywords

    - Searched `plans/` directory for similar architecture or design docs

    - Searched `test/` directory for related test coverage

    - Searched `apps/` directory for existing implementation patterns

    - Checked `mission-control.md` (the referenced plan) to understand the architectural
    context

    - Checked Makefile for Ceph-related build targets


    **Results:**

    1. **No existing Ceph-related code** in the repository

    2. **No topology reconciliation or node mapping logic** found

    3. **No terminal-state tasks** covering similar work

    4. **No active duplicate tasks** identified


    **Evidence:**

    - The Exocomp repository is a cluster management and coordination system in its
    Milestone 7 phase (Mission Control control plane)

    - EXOCOMP-199 is a child task of the EXOCOMP-186 epic and part of a coordinated
    set of related tasks

    - The mission-control.md plan describes the overall architecture but does not
    implement specific Ceph integrations yet

    - This is a brand-new feature implementation for correlating Ceph daemon topology
    with coordinator inventory nodes


    ---


    **Focus handoff: duplicate_detector**


    **Duplicate preflight verdict: no_duplicate**


    **Matches: none**


    **Evidence:** Exhaustive search across .oompah/tasks, plans, documentation, and
    codebase found no active tasks or implementations addressing Ceph topology correlation.
    EXOCOMP-199 is a new feature task within the Milestone 7 Mission Control epic.
    No active duplicate exists.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 12f295fc-a215-4a76-9696-4470a1fbcb8a
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-199
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-199
  base_branch: epic-EXOCOMP-186
  base_sha: a929517cafea443b9d66d601bfd7d7e439e5aaec
  updated_at: '2026-08-01T18:38:39.238291+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 277
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 277
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 277
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:12:18.722253+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-199__20260801T141007Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-186--task-EXOCOMP-199
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:12:18.752804+00:00'
---
## Summary

Plan: plans/mission-control.md, Ceph topology reconciliation.

Deliverable: Map authoritative Ceph daemon topology to node discoveries using stable inventory hostnames and reported daemon identities.

Acceptance criteria:
- Produce one deterministic mapping or a structured missing, ambiguous, conflicting-FSID, or orphan-daemon result.
- Nodes that support the profile but contain no Ceph units remain valid non-members.
- Older nodes that cannot inspect the declared profile degrade coverage explicitly.
- Derived daemon services enter the shared desired-service resolver with source cluster:ceph.

Tests: Cover exact and case-normalized hostname matches, missing hosts, duplicate matches, FSID mismatch, orphan local units, non-member nodes, and unsupported nodes; run make test.

Out of scope: Health severity, incident creation, credentials, and recovery.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:10
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:10
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:12
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 45, Tool calls: 19
- Tokens: 10 in / 277 out [287 total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 16s
- Log: EXOCOMP-199__20260801T141007Z.jsonl
---
author: oompah
created: 2026-08-01 18:38
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 18:38
---
Focus: Callback Auth Validation Specialist
---
author: oompah
created: 2026-08-01 18:39
---
Understanding: correlate authoritative Ceph topology with inventory node discoveries using deterministic exact/case-normalized host identity and daemon identity checks, preserving valid Ceph non-members and explicit unsupported coverage. I’ll inspect the post-EXOCOMP-198 discovery models and shared desired-service resolver, add structured reconciliation outcomes plus focused tests, then run make test.
---
<!-- COMMENTS:END -->
