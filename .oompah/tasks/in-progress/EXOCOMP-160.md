---
id: EXOCOMP-160
type: task
status: In Progress
priority: 1
title: Deliver conversation commands and evidence-linked replies
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-158
- EXOCOMP-159
- EXOCOMP-149
- EXOCOMP-150
- EXOCOMP-151
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:18.620833Z'
updated_at: '2026-08-01T12:56:35.142594Z'
work_branch: epic-EXOCOMP-132--task-EXOCOMP-160
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: afb9c231849f2a633a8619e19e400dad474643c8f297ea056bba78b73614d7eb
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:51:53.470083+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active EXOCOMP-158, 159, 150, 151, 149, 161, and 168. The closest
    tasks are distinct: 158 stores conversations, 159 implements the chat skill, 150
    provides generic command outbox delivery, and 151 handles generic command execution
    idempotency. EXOCOMP-160 uniquely integrates operator commands with persisted
    evidence-linked replies.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: ccd48f0d-362d-4a4a-a556-0adf03dfbe35
oompah.work_branch: epic-EXOCOMP-132--task-EXOCOMP-160
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-132--task-EXOCOMP-160
  base_branch: epic-EXOCOMP-132
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:52:10.861454+00:00'
oompah.task_costs:
  total_input_tokens: 471102
  total_output_tokens: 8860
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 471102
      output_tokens: 8860
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 471102
    output_tokens: 8860
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:51:53.465907+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-160__20260801T123843Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-132--task-EXOCOMP-160
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:51:53.478679+00:00'
---
## Summary

Plan: plans/mission-control.md, Conversations and Cluster-Local Reasoning.

Deliverables:
- Translate an operator message into a durable server command addressed to one connected cluster.
- Handle coordinator conversation.reply results and persist Markdown plus structured evidence IDs, node identities, and observation timestamps.
- Update delivery/reasoning/terminal states only from committed command and event transitions.
- Mark unsupported or stale claims explicitly.

Acceptance:
- Tests cover online delivery, offline queue display, reconnect, duplicate reply, failed reasoning, expired command, invalid citation, and organization/cluster mismatch.
- UI-facing state never labels an unacknowledged command delivered.

Out of scope: LiveView rendering and proposals.
Quality gate: focused context/transport tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:38
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:38
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:51
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 3, Tool calls: 121
- Tokens: 471.1K in / 8.9K out [480.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 13m 19s
- Log: EXOCOMP-160__20260801T123843Z.jsonl
---
author: oompah
created: 2026-08-01 12:52
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:52
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 12:54
---
## Understanding and Plan

**Task Summary:** Implement the conversation command flow - translating operator messages to durable cluster commands, handling coordinator replies, and managing delivery state with evidence citations.

**Key Dependencies Ready:**
- EXOCOMP-158: Message model with state transitions (queued→delivered→reasoning→completed/failed/expired)
- EXOCOMP-159: ClusterChat skill for coordinator-side reasoning
- EXOCOMP-150: Command outbox for durability
- EXOCOMP-151: Command result reporting
- EXOCOMP-149: Event ingestion

**Frontend Developer Focus (no LiveView rendering):**
1. Create command/reply data models in exocomp_mission_control
2. Implement ConversationCommands context for initiating operator messages → cluster commands
3. Implement event handlers for conversation.reply events
4. Persist replies with evidence citations and state transitions
5. Validation: evidence citations, organization/cluster matching, command expiry
6. Comprehensive test coverage: online delivery, offline queue, reconnect, duplicates, failures

**Approach:**
- Add Command model with required/optional fields and validation
- Add Conversations context methods for creating/updating commands and replies
- Add event handler for conversation.reply to update message state
- Implement evidence citation validation
- Write focused tests covering acceptance criteria

**Out of Scope:** UI rendering, proposals
---
author: oompah
created: 2026-08-01 12:56
---
## Discovery: Dependency Infrastructure In Place

**Merged dependencies:**
- EXOCOMP-149: ClusterEventIngestor handles authenticated event delivery with transactional durable cursors, deduplication, and gap-aware acknowledgements
- EXOCOMP-150: CommandOutbox with validated payloads, session-aware delivery, idempotent acknowledgement, expiry (five min TTL default)
- EXOCOMP-151: CommandProcessor handles result reporting, validates, acks, expires commands
- EXOCOMP-158: Message/Conversation/EvidenceReference models with state lifecycle (queued→delivered→reasoning→completed/failed/expired) and context bounds (50 messages, 64 KiB)
- EXOCOMP-159: ClusterChat skill with bounded context, evidence citation validation, Markdown + optional typed proposals

**Implementation needed for EXOCOMP-160:**
1. ConversationCommands context: send_message(org, conv, text, evidence_refs) → creates operator Message, enqueues Command, marks Message delivered
2. Event handler for conversation.reply: find operator Message by command_id, update to reasoning/completed, store reply as cluster Message with evidence refs
3. Validation: evidence citations must match org/cluster/timestamp bounds, commands expiry handling, invalid citations explicit
4. Tests: online delivery, offline queue, reconnect, duplicate reply, failed reasoning, expired command, invalid citation, mismatch

**Key design questions resolved:**
- Command/Message linking: command.payload contains message_id (to be added)
- Reply storage: separate Message with sender_type: :cluster
- State transitions: delivered (command enqueued) → reasoning (command acked) → completed (reply arrives)
---
<!-- COMMENTS:END -->
