---
id: EXOCOMP-163
type: task
status: Ready to Integrate
priority: 1
title: Revalidate and execute approved remedies inside the cluster
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-162
- EXOCOMP-151
- EXOCOMP-145
start_blocked_by: &id001
- EXOCOMP-204
labels: []
assignee: null
created_at: '2026-07-30T14:16:22.081454Z'
updated_at: '2026-08-02T04:05:03.663117Z'
work_branch: epic-EXOCOMP-132--task-EXOCOMP-163
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 1173023bdda4fb86526e326c74b28a164e0f52226aa7a268a238fe0678df5fc9
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:01:14.889676+00:00'
  matched_identifiers: []
  evidence: 'The coordination message from EXOCOMP-162 indicates it''s implementing
    related work with a dependency relationship to EXOCOMP-163. This is consistent
    with the task''s documented blocker relationship and doesn''t change my assessment.


    Given that:

    1. EXOCOMP-163 was already pre-screened for duplicates and remains Open

    2. My investigation confirms no existing implementation of the coordinator-side
    approval handler, revalidation, or Mission Control integration

    3. The dependency relationship to EXOCOMP-162 is already documented and expected

    4. These are distinct tasks in the epic (epic-sibling per coordination)


    My duplicate verdict stands:


    ---


    **Focus handoff: duplicate_detector**


    **Duplicate preflight verdict: no_duplicate**


    **Matches: none**


    **Evidence:** Comprehensive codebase search found no handler for Mission Control
    approval commands, no revalidation infrastructure, and no code to sign approvals
    for external submission. RemediationLifecycle module handles internal A2A proposals
    only. Task was pre-screened for duplicates and remains Open. Coordination from
    EXOCOMP-162 (peer-started, dependency/epic-sibling) confirms expected distinct
    work with clear blocker relationships, not evidence of duplicate scope.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: null
oompah.work_branch: epic-EXOCOMP-132--task-EXOCOMP-163
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: epic-EXOCOMP-132--task-EXOCOMP-163
  head_sha: c4f02ab48cd40dfe22aa55dbb1fc3d2a77ff04b7
  submitted_at: '2026-08-02T04:04:44.061978+00:00'
  updated_at: '2026-08-02T04:04:44.061978+00:00'
oompah.task_costs:
  total_input_tokens: 18
  total_output_tokens: 931
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 18
      output_tokens: 931
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 18
    output_tokens: 931
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:01:14.889044+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-163__20260801T125829Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-132--task-EXOCOMP-163
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:01:14.902258+00:00'
---
## Summary

Plan: plans/mission-control.md, Typed Remedy Approval.

Deliverables:
- Handle the typed approval command in the coordinator.
- Recollect evidence, rerun deterministic local policy, and reject changed target, parameters, evidence, or policy.
- Sign the existing short-lived Ed25519 approval token locally and submit through existing node safety/idempotency boundaries.
- Report started, completed, failed, and verification-failed events with artifacts and correlation IDs.

Acceptance:
- Tests cover success, stale evidence, policy change, target/parameter mismatch, token expiry/replay, duplicate command, execution failure, verification failure, and restart recovery.
- Mission Control never receives the cluster approval key.

Out of scope: arbitrary actions and changing automatic failed-service recovery policy.
Quality gate: focused node/coordinator tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: profile remedies must remain typed and cluster-local. Integrate the verified Ceph safe-restart result from EXOCOMP-204 without allowing Mission Control to supply service allow-lists, profile commands, or arbitrary argv.
---
author: oompah
created: 2026-08-01 12:58
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:58
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:01
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 85, Tool calls: 41
- Tokens: 18 in / 931 out [949 total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 55s
- Log: EXOCOMP-163__20260801T125829Z.jsonl
---
author: oompah
created: 2026-08-02 03:33
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-02 03:33
---
Focus: Callback Auth Validation Specialist
---
author: oompah
created: 2026-08-02 03:34
---
Understanding: implement typed approval handling in the coordinator, revalidate fresh evidence and deterministic policy/target/parameters, sign short-lived Ed25519 approvals locally, execute through node safety/idempotency boundaries, and emit correlated lifecycle/verification events. I will preserve the existing failed-service recovery policy and cover the listed replay, mismatch, failure, and restart cases.
---
author: oompah
created: 2026-08-02 04:02
---
Verification: typed remediation suite compiled and exercised 12 scenarios in an isolated host harness with 0 failures: success/revalidation/signing, stale and mismatched evidence, policy/target/parameter drift, expiry, duplicate, denial, restart rehydration, execution failure, and verification failure. Local mix format check, syntax parsing, and git diff check pass. Official make test, make fmt-check, and make lint are blocked before execution by the host read-only Podman configuration; direct Mix is blocked by Elixir 1.18.3 versus pinned 1.20.2.
---
author: oompah
created: 2026-08-02 04:04
---
Verification update: after adding explicit execution_completed history and correlation-checked action_started/action_completed audit assertions, the isolated typed suite passes 13/13. Official gates remain environment-blocked as reported.
---
author: oompah
created: 2026-08-02 04:04
---
Completion: delivered typed proposal.approve/proposal.deny coordinator handling with strict payload/context validation, fresh evidence and policy revalidation, fail-closed binding checks, local Ed25519 signing, node adapter safety boundary, durable command idempotency/outbox integration, restart rehydration, and correlated lifecycle/artifact reporting. Commit c4f02ab4 is pushed; official container gates are blocked by host Podman configuration and direct Mix by the pinned-version mismatch.
---
author: oompah
created: 2026-08-02 04:04
---
Implemented typed approved-remedy execution with local Ed25519 signing, fail-closed revalidation, durable command boundaries, node safety integration, restart recovery, and correlated execution artifacts. Pushed c4f02ab4.
---
author: oompah
created: 2026-08-02 04:05
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 199
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 31m 22s
- Log: EXOCOMP-163__20260802T033344Z.jsonl
---
<!-- COMMENTS:END -->
