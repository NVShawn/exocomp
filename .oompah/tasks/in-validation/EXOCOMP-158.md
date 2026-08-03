---
id: EXOCOMP-158
type: task
status: In Validation
priority: 1
title: Store bounded conversations, messages, and evidence references
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-138
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:16.513296Z'
updated_at: '2026-08-03T18:06:15.723769Z'
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
oompah.agent_run_id: null
oompah.work_branch: epic-EXOCOMP-132--task-EXOCOMP-158
oompah.integration:
  version: 2
  state: integrated
  attempts: 1
  task_branch: epic-EXOCOMP-132--task-EXOCOMP-158
  base_branch: epic-EXOCOMP-132
  base_sha: 24f84e9459c72cb9354dc47e6f531118e14fcfaa
  head_sha: a435774fc3b9b1a2b9ec17c0ea7a07a4236bd701
  integrated_sha: a435774fc3b9b1a2b9ec17c0ea7a07a4236bd701
  submitted_at: '2026-08-03T17:55:17.991706+00:00'
  updated_at: '2026-08-03T18:06:05.744023+00:00'
oompah.task_costs:
  total_input_tokens: 5527536
  total_output_tokens: 23059
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 897761
      output_tokens: 4536
      cost_usd: 0.0
    sonnet:
      input_tokens: 4629775
      output_tokens: 18523
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 897761
    output_tokens: 4536
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:36:41.115660+00:00'
  - profile: standard
    model: sonnet
    input_tokens: 4629775
    output_tokens: 18523
    cost_usd: 0.0
    recorded_at: '2026-08-03T17:57:40.262886+00:00'
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
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-0d7f234f2aad
    project_id: proj-c260b117
    task_id: EXOCOMP-158
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: ec221113667b4616c94d4c5b1cf32216419747483a36db8339151849b73daed2
    attempts: []
    requested_by:
      version: 1
      identity: oompah-integration
      source: service
    previous_state: Ready to Integrate
    created_at: '2026-08-03T18:06:11.414709+00:00'
  attempt_history: []
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
author: oompah
created: 2026-08-01 12:50
---
Verification update: focused conversation tests pass (8 tests, 0 failures) under a direct ExUnit runner because host Mix rejects the declared Elixir 1.20.2 on local Elixir 1.18.3. Syntax validation passes. make init cannot access the pinned builder because Docker is unavailable; I will still attempt make test, make fmt-check, and make lint and record their results.
---
author: oompah
created: 2026-08-01 12:52
---
Verification: focused conversation suite passes 8 tests with 0 failures after final malformed-evidence handling fix; host syntax and formatter idempotence checks pass. Offline builder checks pass (13 structural/fixture checks). Required container-backed make test/fmt-check/lint remain environment-blocked by the read-only libpod runtime configuration.
---
author: oompah
created: 2026-08-01 12:52
---
Completion: delivered organization-scoped incident/ad hoc cluster conversations, memberships, ordered 16 KiB-bounded messages, structured evidence references, newest-50/64 KiB context selection, lifecycle states, isolation checks, and focused tests in commit b8776d44. Branch pushed and clean; container-backed gates are pending an available builder runtime.
---
author: oompah
created: 2026-08-01 12:52
---
Implemented bounded organization-scoped Mission Control conversations, memberships, ordered messages, evidence references, context selection, lifecycle transitions, validation, and focused tests. Commit b8776d44 pushed; container quality gates are environment-blocked by unavailable Docker/libpod runtime.
---
author: oompah
created: 2026-08-01 12:52
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 106
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 15m 49s
- Log: EXOCOMP-158__20260801T123706Z.jsonl
---
author: oompah
created: 2026-08-03 17:44
---
Integration found a rebase conflict on `epic-EXOCOMP-132--task-EXOCOMP-158`. Resolve it against `epic-EXOCOMP-132`, run the required tests, push the same private branch, and `oompah task submit` it again.
---
author: oompah
created: 2026-08-03 17:45
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-08-03 17:45
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-03 17:55
---
Coordination reviewed before submission: EXOCOMP-146 overlap is limited to Mission Control.Application supervision; Conversations and ClusterSessions are independent children and the interface boundary was sent to EXOCOMP-146. EXOCOMP-173 was notified to consume the existing Conversations API. Verification rerun on clean a435774f: make test and make lint both passed all offline checks (38 checks total) before the container-backed Mix steps were blocked by the managed read-only libpod runtime (cannot chmod /run/user/1000/libpod); make fmt-check was blocked at that same container startup point. No code or formatting failure was reported.
---
author: oompah
created: 2026-08-03 17:55
---
Submitted a435774f after reconciling the Mission Control supervision overlap. Delivers organization-scoped bounded conversations, memberships, ordered messages, evidence references, context selection, lifecycle transitions, and supervision integration. Container-backed Mix gates are environment-blocked by read-only libpod; all offline checks passed.
---
author: oompah
created: 2026-08-03 17:57
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/gpt-5.6-terra]
- Turns: 0, Tool calls: 104
- Tokens: 4.6M in / 18.5K out [4.6M total]
- Cost: $0.0000
- Exit: terminated, Duration: 12m 9s
- Log: EXOCOMP-158__20260803T174549Z.jsonl
---
author: oompah
created: 2026-08-03 18:06
---
Queued for terminal transition to Done. An auditor will review and apply the terminal status.
---
<!-- COMMENTS:END -->
