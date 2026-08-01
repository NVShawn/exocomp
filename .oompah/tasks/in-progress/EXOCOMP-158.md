---
id: EXOCOMP-158
type: task
status: In Progress
priority: 1
title: Store bounded conversations, messages, and evidence references
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-138
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:16.513296Z'
updated_at: '2026-08-01T12:45:50.193729Z'
work_branch: epic-EXOCOMP-132--task-EXOCOMP-158
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 832bcb18a7b711dada0dc827d18c063664c39661f8fd3d7af6aeb2fdcdfa7532
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:36:41.115911+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active EXOCOMP-132, 138, 159, 160, 161, 168, 171, and 175.
    EXOCOMP-160, the closest match, explicitly depends on EXOCOMP-158 and covers command
    delivery/replies rather than conversation storage. Other tasks cover chat skill,
    proposals, UI, audit, retention, or organization foundations.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: c6f3b776-ef79-4a71-bfcc-8c95d7ef594a
oompah.work_branch: epic-EXOCOMP-132--task-EXOCOMP-158
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-132--task-EXOCOMP-158
  base_branch: epic-EXOCOMP-132
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:37:02.959416+00:00'
oompah.task_costs:
  total_input_tokens: 897761
  total_output_tokens: 4536
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 897761
      output_tokens: 4536
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 897761
    output_tokens: 4536
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:36:41.115660+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-158__20260801T123446Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-132--task-EXOCOMP-158
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:36:41.119316+00:00'
---
## Summary

Plan: plans/mission-control.md, Conversations and Cluster-Local Reasoning.

Deliverables:
- Add organization-scoped conversations, memberships, ordered messages, and structured evidence-reference schemas.
- Support incident-attached and ad hoc cluster conversations.
- Enforce 16 KiB per message and a newest-50-messages-or-64-KiB context selector.
- Track queued, delivered, reasoning, completed, failed, and expired states.

Acceptance:
- Tests cover ordering, limits, context truncation, state transitions, incident membership, cluster membership, and organization isolation.
- Arbitrary file attachments and raw-log blobs are rejected.

Out of scope: transport and model calls.
Quality gate: focused context tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:34
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:34
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:36
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 30
- Tokens: 897.8K in / 4.5K out [902.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 2s
- Log: EXOCOMP-158__20260801T123446Z.jsonl
---
author: oompah
created: 2026-08-01 12:36
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:37
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 12:37
---
Understanding: add organization-scoped conversations, memberships, ordered bounded messages, structured evidence references, context selection, and lifecycle states per plans/mission-control.md; reject attachments/raw-log blobs and cover all acceptance cases with focused tests. I will first inspect existing domain/persistence patterns, then implement and run the Makefile quality gates.
---
author: oompah
created: 2026-08-01 12:40
---
Discovery: this branch predates the separate exocomp_mission_control app, but completed Mission Control foundation branches establish that namespace. I will add a standalone dependency-light domain app with pure schemas and a GenServer-backed conversation store; conversations require a cluster, optionally carry an incident, auto-record cluster membership, and enforce organization checks on every read/write.
---
author: oompah
created: 2026-08-01 12:45
---
Implementation: added the standalone exocomp_mission_control app with Conversation, Membership, Message, EvidenceReference schemas and Conversations GenServer context. Messages are UTF-8 byte-bounded at 16 KiB, references are whitelist-only, context is newest-first bounded then restored to chronological order, and message transitions record state history.
---
<!-- COMMENTS:END -->
