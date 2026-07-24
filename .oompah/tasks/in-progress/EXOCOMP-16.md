---
id: EXOCOMP-16
type: feature
status: In Progress
priority: 1
title: Implement coordinator CA initialization and enrollment tokens
parent: EXOCOMP-2
children:
- EXOCOMP-75
- EXOCOMP-76
- EXOCOMP-77
blocked_by:
- EXOCOMP-9
- EXOCOMP-14
labels:
- focus-complete:duplicate_detector
- focus-complete:epic_planner
assignee: null
created_at: '2026-07-23T19:09:29.953540Z'
updated_at: '2026-07-24T01:31:35.769469Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: b0cdd68c-7f2c-4051-9f56-d42fc55cc4a9
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 1178921
  total_output_tokens: 11681
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1178921
      output_tokens: 11681
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 731302
    output_tokens: 3656
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:51:10.284714+00:00'
  - profile: standard
    model: unknown
    input_tokens: 20
    output_tokens: 4594
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:53:13.807167+00:00'
  - profile: standard
    model: unknown
    input_tokens: 447599
    output_tokens: 3431
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:58:01.883876+00:00'
---
## Summary

Plan: [Milestone 2 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-2-coordinator.md)

Goal
Implement coordinator CA initialization and enrollment tokens.

Implementation
Add coordinator-local initialization that creates a protected offline root export, online intermediate, coordinator leaf identity, and separate approval-signing key; implement ten-minute one-use enrollment tokens bound to inventory node IDs; enforce key permissions and explicit backup output.

Testing
Test initialization idempotency, secure permissions, missing/corrupt key material, token expiry, node mismatch, token replay, and secrets absent from logs.

Acceptance Criteria
- [ ] PKI initialization produces valid separated root/intermediate material.
- [ ] Online state does not retain an unprotected root key.
- [ ] Enrollment tokens are node-bound, expiring, and single-use.
- [ ] Private material is protected and redacted.
- [ ] Focused PKI tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 22:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:49
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:51
---
Agent completed successfully in 108s (734958 tokens)
---
author: oompah
created: 2026-07-23 22:51
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 10
- Tokens: 731.3K in / 3.7K out [735.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 48s
- Log: EXOCOMP-16__20260723T224925Z.jsonl
---
author: oompah
created: 2026-07-23 22:51
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-2`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 22:51
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:51
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:53
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-16 is a unique task with no overlap in the existing task graph.

**Evidence reviewed:**
- EXOCOMP-9 (Done): Node-side config/identity/mTLS — different scope entirely (node agent setup, not coordinator PKI initialization)
- EXOCOMP-14 (Done): Coordinator inventory, registry, audit — foundational coordinator scaffold; no PKI/CA/enrollment token content
- EXOCOMP-15 (Open): DNS discovery and polling — no PKI overlap
- EXOCOMP-17 (Open): Node enrollment and renewal — node-side process that CONSUMES enrollment tokens issued by EXOCOMP-16; complementary, not duplicate
- EXOCOMP-18 (Open): Diagnostic task orchestration — no PKI overlap
- EXOCOMP-19, EXOCOMP-20: A2A service and M2 verification — no PKI overlap
- Searched plans/milestone-2-coordinator.md Bootstrap PKI section for task alignment

**Relevant files for feature agent:**
- plans/milestone-2-coordinator.md — Bootstrap PKI section (root/intermediate/leaf/approval-key design), enrollment token lifetime, CSR validation requirements
- apps/exocomp_coordinator/lib/exocomp/coordinator/application.ex — OTP supervisor to extend with PKI GenServer(s)
- apps/exocomp_coordinator/mix.exs — add PKI deps (x509 or :public_key for cert generation)
- Branch EXOCOMP-14 is merged; branch EXOCOMP-16 should be based on main/epic branch that includes EXOCOMP-14 work

**Work required (feature agent):**
1. Coordinator PKI initialization: generate root CA (RSA or ECDSA), export for offline backup, derive online intermediate, issue coordinator leaf cert, generate separate Ed25519 approval-signing key
2. Enforce key file permissions (600/no group/world readable)
3. Initialization idempotency (skip if already initialized, detect corrupt state)
4. Enrollment token API: generate 10-minute HMAC or signed tokens bound to inventory node IDs, single-use via ETS or persisted set, validate token on enrollment request
5. Integrate into coordinator OTP supervisor tree
6. Tests: init idempotency, secure permissions, missing/corrupt key material, token expiry, node ID mismatch, token replay, secrets absent from logs
7. Run make test && make lint && make fmt-check

**Risks:**
- Elixir's :public_key module covers X.509 cert generation but the API is complex; the x509 hex package provides a nicer interface — check if it's already a dependency
- Token replay prevention requires persistence across restarts (ETS is lost on restart); consider a bounded durable set or accept replay window equals restart window
- Root key offline export: must write to a clearly-named backup file and immediately delete the in-memory root private key from the online state directory
- EXOCOMP-17 (node enrollment/renewal) depends on the token API designed here; interface contract matters

**Recommended next focus:** feature
---
author: oompah
created: 2026-07-23 22:53
---
Agent completed successfully in 108s (4614 tokens)
---
author: oompah
created: 2026-07-23 22:53
---
Run #2 [attempt=2, profile=standard, role=standard -> Claude/default]
- Turns: 36, Tool calls: 26
- Tokens: 20 in / 4.6K out [4.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 48s
- Log: EXOCOMP-16__20260723T225127Z.jsonl
---
author: oompah
created: 2026-07-23 22:53
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 22:53
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:53
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 22:58
---
Agent completed successfully in 279s (451030 tokens)
---
author: oompah
created: 2026-07-23 22:58
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 7
- Tokens: 447.6K in / 3.4K out [451.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 4m 39s
- Log: EXOCOMP-16__20260723T225325Z.jsonl
---
author: oompah
created: 2026-07-23 22:58
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-2`. Escalating from 'standard' to 'deep'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 22:58
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-07-23 22:58
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-23 23:00
---
Understanding: Plan EXOCOMP-16 as three session-sized children covering (1) secure coordinator PKI bootstrap and state validation, (2) node-bound expiring single-use enrollment tokens, and (3) OTP/operator integration plus cross-cutting redaction and focused security verification. I will inspect existing children first, avoid duplicates, order dependencies, then return the parent epic to Backlog.
---
author: oompah
created: 2026-07-23 23:00
---
Discovery: EXOCOMP-16 has no existing children. The Bootstrap PKI design requires a root exported for offline storage, an online intermediate, coordinator leaf, separate Ed25519 approval key, protected state, and ten-minute one-use node-bound tokens. EXOCOMP-14 provides the inventory/audit/supervision foundation on origin/EXOCOMP-14 but is Done and not yet on origin/main; child implementations must base on that work. Key boundaries are apps/exocomp_coordinator/lib/exocomp/coordinator, its mix.exs, and focused coordinator tests.
---
author: oompah
created: 2026-07-23 23:02
---
Implementation: Created three high-priority child tasks. EXOCOMP-75 owns secure root/intermediate/coordinator/approval-key bootstrap and state validation; EXOCOMP-76 owns durable inventory-bound ten-minute single-use tokens; EXOCOMP-77 owns supervision, operator initialization, interface wiring, and cross-cutting security verification. Each description includes concrete contracts, failure behavior, tests, files, and quality gates.
---
author: oompah
created: 2026-07-23 23:02
---
Verification: Re-read the tracker-backed task files after creation. EXOCOMP-16 lists exactly EXOCOMP-75, EXOCOMP-76, and EXOCOMP-77 as children. Dependencies are recorded as 75 -> EXOCOMP-14; 76 -> EXOCOMP-75 and EXOCOMP-14; 77 -> EXOCOMP-75 and EXOCOMP-76. All children are high priority (priority 1), Backlog, and collectively cover every parent acceptance criterion. No repository code was changed, as required for epic planning.
---
author: oompah
created: 2026-07-23 23:02
---
Focus handoff: epic_planner

Outcome: EXOCOMP-16 is fully decomposed into three independently actionable children: EXOCOMP-75 secure PKI bootstrap/state validation, EXOCOMP-76 durable node-bound enrollment tokens, and EXOCOMP-77 coordinator/operator integration and end-to-end security checks.

Evidence and decisions: plans/milestone-2-coordinator.md Bootstrap PKI defines the root/intermediate/leaf/approval-key split and ten-minute one-use tokens. The coordinator implementation surface is apps/exocomp_coordinator; EXOCOMP-14 supplies inventory, audit, and supervision foundations. Token storage is specified as digest-only and durable across restart, with atomic consume and constant-time comparison. The approval key remains separate from CA and token purposes. Root private material is confined to an explicitly protected offline backup and forbidden from online state.

Dependencies: EXOCOMP-75 depends on EXOCOMP-14; EXOCOMP-76 depends on EXOCOMP-75 and EXOCOMP-14; EXOCOMP-77 depends on EXOCOMP-75 and EXOCOMP-76. EXOCOMP-17 already depends on the parent and will consume the resulting interface.

Risks: EXOCOMP-14 is Done on origin/EXOCOMP-14 but is not yet present on origin/main, so implementation branches must include that foundation. PKI library selection must preserve required algorithms and encrypted private-key handling. Enrollment persistence must fail closed on corruption and concurrency.

Recommended next focus: feature, beginning with EXOCOMP-75.
---
author: oompah
created: 2026-07-23 23:02
---
Run #2 [attempt=2, profile=deep, role=deep -> Codex/default]
- Turns: 0, Tool calls: 34
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 4m 18s
- Log: EXOCOMP-16__20260723T225820Z.jsonl
---
<!-- COMMENTS:END -->
