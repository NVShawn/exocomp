---
id: EXOCOMP-204
type: task
status: In Progress
priority: 1
title: Verify Ceph daemon recovery and enforce cooldown
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-203
labels: []
assignee: null
created_at: '2026-07-30T21:38:35.429036Z'
updated_at: '2026-08-02T00:50:36.195693Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-204
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 3e99057735e10ebc0c5d1b5ea865ae72cb710621461de11f8556886ec883f18f
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:24:56.605158+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector  \nDuplicate preflight verdict: no_duplicate\
    \  \nMatches: none  \nEvidence: Reviewed active task records EXOCOMP-186, EXOCOMP-195\u2013\
    206, and related recovery/Mission Control tasks. EXOCOMP-203 covers restart authorization/execution;\
    \ EXOCOMP-200 covers health reduction; EXOCOMP-206 covers qualification. None\
    \ duplicates post-action verification and cooldown enforcement. No files or tracker\
    \ state were modified."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: f2a6a29e-3621-46b2-a34c-f572f5e5c75a
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-204
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-204
  base_branch: epic-EXOCOMP-186
  base_sha: c6a135bf82581e11696de8b4d0e32946ec563677
  updated_at: '2026-08-02T00:50:31.566391+00:00'
oompah.task_costs:
  total_input_tokens: 554238
  total_output_tokens: 5017
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 554238
      output_tokens: 5017
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 554238
    output_tokens: 5017
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:24:56.604381+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-204__20260801T142307Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-186--task-EXOCOMP-204
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:24:56.610408+00:00'
---
## Summary

Plan: plans/mission-control.md, Ceph recovery verification.

Deliverable: Add post-action verification and terminal audit behavior for the safe Ceph daemon restart.

Acceptance criteria:
- Recollect systemd and Ceph evidence after execution and across the configured stability window.
- Complete only when the daemon is running, mapped to the same topology identity, and cluster evidence is no worse.
- Verification failure enters cooldown and cannot trigger a second automatic restart in the same episode.
- Node or coordinator restart reconciles durable execution state without repeating the action.
- Emit correlated completed, failed, verification_failed, and cooldown evidence.

Tests: Cover successful recovery, systemd-only recovery, worsened Ceph health, identity change, flapping, process restart, cooldown expiry, and audit failure; run make test.

Out of scope: Mission Control rendering and additional Ceph repair actions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:22
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:23
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:24
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 26
- Tokens: 554.2K in / 5.0K out [559.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 58s
- Log: EXOCOMP-204__20260801T142307Z.jsonl
---
author: oompah
created: 2026-08-02 00:50
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-02 00:50
---
Focus: Callback Auth Validation Specialist
---
<!-- COMMENTS:END -->
