---
id: EXOCOMP-198
type: task
status: Open
priority: 1
title: Discover local traditional and cephadm daemon units
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-195
labels: []
assignee: null
created_at: '2026-07-30T21:38:22.833355Z'
updated_at: '2026-08-01T14:09:51.729048Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-198
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: a1c4524f266cfc8ab1e3d92da119a2446f06f3b64a73bc80984d16d2539a6b6f
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:09:48.231219+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector  \nDuplicate preflight verdict: no_duplicate\
    \  \nMatches: none  \n\nEvidence: Reviewed active task records EXOCOMP-195, EXOCOMP-196,\
    \ EXOCOMP-197, EXOCOMP-199\u2013206 and backlog EXOCOMP-207. Closest tasks cover\
    \ profile registry, Ceph CLI collection, topology correlation, and recovery; none\
    \ covers local systemd daemon-unit discovery. No files or tracker state were modified."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 28ffff43-d892-43db-aef1-7e4c0f44aad6
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-198
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-198
  base_branch: epic-EXOCOMP-186
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:08:25.469099+00:00'
oompah.task_costs:
  total_input_tokens: 469226
  total_output_tokens: 3487
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 469226
      output_tokens: 3487
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 469226
    output_tokens: 3487
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:09:48.229609+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-198__20260801T140828Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-186--task-EXOCOMP-198
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:09:48.242280+00:00'
---
## Summary

Plan: plans/mission-control.md, Ceph node discovery.

Deliverable: Implement the Ceph branch of exocomp.profile.inspect using fixed systemd queries.

Acceptance criteria:
- Recognize shipped patterns for traditional and cephadm monitor, manager, OSD, MDS, and gateway units.
- Return daemon kind, daemon ID, unit, FSID when available, enablement, load state, active state, and substate.
- A supported node with no Ceph installation reports not_member rather than an error.
- Strict parsing, timeouts, and output bounds prevent arbitrary unit or command injection.

Tests: Use fixtures for traditional units, cephadm units, mixed installations, no installation, malformed names, timeout, and truncated output; run make test.

Out of scope: Coordinator topology matching, cluster health policy, and action execution.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:08
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:08
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:09
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 29
- Tokens: 469.2K in / 3.5K out [472.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 27s
- Log: EXOCOMP-198__20260801T140828Z.jsonl
---
<!-- COMMENTS:END -->
