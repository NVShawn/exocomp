---
id: EXOCOMP-187
type: task
status: Ready to Integrate
priority: 1
title: Integrate the three-path desired-state design into project plans
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T21:36:56.896701Z'
updated_at: '2026-08-01T13:40:22.222714Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-187
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 7ba81767a3816b7642f4cad590e60195b0783b20b33d3683145a36be9e467816
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:36:42.935019+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active tasks EXOCOMP-127, 131, 133, 134,\
    \ 152, 155, 166, 178, 185, 186, 188\u2013194, 205, and 207. They cover implementation,\
    \ Mission Control persistence/UI, operator documentation, or broader Ceph repairs;\
    \ none duplicates EXOCOMP-187\u2019s internal roadmap integration scope."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 0e98aea7-92e8-4111-a166-4c0b10dbc8f5
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-187
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-187
  head_sha: 6742aa13ef4dc7e3dafa1582cebb5e4550ba9a72
  submitted_at: '2026-08-01T13:40:19.872477+00:00'
  updated_at: '2026-08-01T13:40:19.872477+00:00'
oompah.task_costs:
  total_input_tokens: 377263
  total_output_tokens: 2599
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 377263
      output_tokens: 2599
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 377263
    output_tokens: 2599
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:36:42.934699+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-187__20260801T133536Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-185--task-EXOCOMP-187
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:36:42.939344+00:00'
---
## Summary

Plan: plans/mission-control.md.

Deliverable: Update the internal roadmap documents so manual host services, automatic enabled-service discovery, and coordinator-declared cluster profiles form one coherent design.

Acceptance criteria:
- plans/exocomp.md summarizes all three paths.
- Milestone 2 owns inventory, discovery, and reconciliation behavior.
- Milestone 4 owns profile-authorized safe recovery.
- Mission Control owns reporting, persistence, incidents, and UI but not desired-state authority.
- The documents state that broader Ceph repairs remain a separate roadmap.

Tests: Run make check-links and make test-compliance.

Out of scope: Source-code, configuration-template, or tracker changes beyond documenting the approved design.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:35
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:35
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:36
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 8
- Tokens: 377.3K in / 2.6K out [379.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 24s
- Log: EXOCOMP-187__20260801T133536Z.jsonl
---
author: oompah
created: 2026-08-01 13:36
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 13:36
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 13:37
---
Understanding: This task requires integrating three design paths for desired-state management into the project documentation. The three paths are: (1) Manual host services via static inventory, (2) Automatic enabled-service discovery and reconciliation, and (3) Coordinator-declared cluster profiles via Mission Control. Acceptance criteria require plans/exocomp.md to summarize all paths, with Milestone 2 owning inventory/discovery/reconciliation, Milestone 4 owning profile-authorized safe recovery, Mission Control owning reporting/persistence/incidents/UI (not desired-state authority), and a note about Ceph repairs being separate. Plan: Read existing plans, update exocomp.md to clearly document the three-path architecture, update milestone descriptions for clarity, and run make check-links and make test-compliance.
---
author: oompah
created: 2026-08-01 13:40
---
Implementation: Updated plans/exocomp.md to integrate the three-path desired-state design into a coherent roadmap. Changes include: (1) New 'Three-Path Desired-State Design' section documenting Path 1 (manual inventory), Path 2 (automatic reconciliation), Path 3 (Mission Control), (2) Updated Architecture section with Mermaid diagram showing three paths, (3) Reorganized Objectives to reflect path-specific goals, (4) Enhanced Safety Invariants to emphasize cluster-local policy authority, (5) Added Path Coverage table to Milestones section clarifying ownership, (6) Expanded Shared Acceptance section with explicit Mission Control boundaries and Ceph repair non-goals. All internal links validated. Trailing whitespace fixed. Commit: 6742aa13.
---
author: oompah
created: 2026-08-01 13:40
---
Verification: All acceptance criteria met. Tests: make check-links PASS (links validated), make test-compliance PASS (29/29 tests). Deliverable checklist: ✓ plans/exocomp.md summarizes all three paths (overview + detailed sections), ✓ Milestone 2 owns inventory/discovery/reconciliation behavior (M2-CRIT-1 through M2-CRIT-8), ✓ Milestone 4 owns profile-authorized safe recovery (recovery state machine + approval + verification), ✓ Mission Control owns reporting/persistence/incidents/UI (explicit boundaries documented), ✓ Documents state Ceph repairs remain separate roadmap (noted in Boundaries section). Branch: epic-EXOCOMP-185--task-EXOCOMP-187 pushed and ready for review.
---
author: oompah
created: 2026-08-01 13:40
---
Integrated three-path desired-state design into plans/exocomp.md with clear ownership boundaries: Path 1 (manual inventory via M2), Path 2 (automatic reconciliation via M2+M4), Path 3 (Mission Control fleet management via M7). Mission Control boundaries clearly defined as non-policy-authority. All acceptance criteria met, tests pass.
---
<!-- COMMENTS:END -->
