---
id: EXOCOMP-130
type: epic
status: Done
priority: 1
title: 'M7C: Cluster transport and durable delivery'
parent: EXOCOMP-127
children:
- EXOCOMP-145
- EXOCOMP-146
- EXOCOMP-147
- EXOCOMP-148
- EXOCOMP-149
- EXOCOMP-150
- EXOCOMP-151
- EXOCOMP-240
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:12:18.299606Z'
updated_at: '2026-08-04T00:42:32.590492Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    infrastructure-exhausted-audit-a19b69af12f0-3: '2026-08-04T00:09:38.527854+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-130
    target_state: Done
    evidence_fingerprint: 699247d4044180bc8742a91ac0dabd380d76d676f802dd6608ad24e2c7790af7
    audit_ids:
    - audit-a19b69af12f0
    kind: result
    applied: true
    retired_at: '2026-08-04T00:09:38.527866+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-130
    audit_id: audit-a19b69af12f0
    attempt_id: infrastructure-exhausted-audit-a19b69af12f0-3
    target_state: Done
    evidence_fingerprint: 699247d4044180bc8742a91ac0dabd380d76d676f802dd6608ad24e2c7790af7
    status: Needs Human
    audit_ids:
    - audit-a19b69af12f0
    applied: true
    created_at: '2026-08-04T00:09:38.527882+00:00'
    applied_at: '2026-08-04T00:09:41.538037+00:00'
  oompah.terminal_override_records:
  - version: 1
    override_id: override-aebbaf30a479
    project_id: proj-c260b117
    task_id: EXOCOMP-130
    target_state: Done
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 699247d4044180bc8742a91ac0dabd380d76d676f802dd6608ad24e2c7790af7
    authorized_by:
      version: 1
      identity: oompah-cli
      source: api
    reason: All EXOCOMP-130 child implementation is complete and the canonical origin/epic-EXOCOMP-130
      branch exists at verified head 7bf5506c. Audit attempts failed before launch
      only because the resolver tried the nonexistent origin/EXOCOMP-130 ref; OOMPAH-746
      tracks that bug. OOMPAH-747 tracks the remaining rebased-child landing-evidence
      defect before automatic review.
    created_at: '2026-08-04T00:42:27.713915+00:00'
    applied: false
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-a19b69af12f0
    project_id: proj-c260b117
    task_id: EXOCOMP-130
    target_state: Done
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 699247d4044180bc8742a91ac0dabd380d76d676f802dd6608ad24e2c7790af7
    attempts:
    - version: 1
      attempt_id: attempt-ad5c3b41bcee
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 699247d4044180bc8742a91ac0dabd380d76d676f802dd6608ad24e2c7790af7
      created_at: '2026-08-04T00:04:58.759038+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-04T00:04:58.759038+00:00'
      branch_key: EXOCOMP-130
      failure_classification: infrastructure_error
      ended_at: '2026-08-04T00:05:16.882694+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-130 (tried: origin/EXOCOMP-130)'
      next_retry_at: '2026-08-04T00:05:26.882667+00:00'
    - version: 1
      attempt_id: attempt-23bb5354f832
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 699247d4044180bc8742a91ac0dabd380d76d676f802dd6608ad24e2c7790af7
      created_at: '2026-08-04T00:05:52.477641+00:00'
      provider_id: prov-651d553c
      model: sonnet
      started_at: '2026-08-04T00:05:52.477641+00:00'
      branch_key: EXOCOMP-130
      candidate_rotation_count: 1
      failure_classification: infrastructure_error
      ended_at: '2026-08-04T00:06:18.641214+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-130 (tried: origin/EXOCOMP-130)'
      next_retry_at: '2026-08-04T00:06:38.641188+00:00'
    - version: 1
      attempt_id: attempt-bd99dc3e6d26
      target_state: Done
      request_state: pending
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 699247d4044180bc8742a91ac0dabd380d76d676f802dd6608ad24e2c7790af7
      created_at: '2026-08-04T00:07:03.283231+00:00'
      provider_id: prov-651d553c
      model: haiku
      started_at: '2026-08-04T00:07:03.283231+00:00'
      branch_key: EXOCOMP-130
      candidate_rotation_count: 2
      failure_classification: infrastructure_error
      ended_at: '2026-08-04T00:07:10.991496+00:00'
      failure_reason: 'terminal audit evidence has no safely resolvable revision for
        EXOCOMP-130 (tried: origin/EXOCOMP-130)'
      next_retry_at: '2026-08-04T00:07:50.991468+00:00'
    - version: 1
      attempt_id: infrastructure-exhausted-audit-a19b69af12f0-3
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: 699247d4044180bc8742a91ac0dabd380d76d676f802dd6608ad24e2c7790af7
      verdict: needs_human
      failure_classification: infrastructure_error
      created_at: '2026-08-04T00:09:38.527743+00:00'
      completed_at: '2026-08-04T00:09:38.527743+00:00'
    requested_by:
      version: 1
      identity: orchestrator
    previous_state: Open
    created_at: '2026-08-04T00:03:58.412726+00:00'
    updated_at: '2026-08-04T00:09:38.527743+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-ad5c3b41bcee
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 699247d4044180bc8742a91ac0dabd380d76d676f802dd6608ad24e2c7790af7
    created_at: '2026-08-04T00:04:58.759038+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-04T00:04:58.759038+00:00'
    branch_key: EXOCOMP-130
    failure_classification: infrastructure_error
    ended_at: '2026-08-04T00:05:16.882694+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-130 (tried: origin/EXOCOMP-130)'
    next_retry_at: '2026-08-04T00:05:26.882667+00:00'
  - version: 1
    attempt_id: attempt-23bb5354f832
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 699247d4044180bc8742a91ac0dabd380d76d676f802dd6608ad24e2c7790af7
    created_at: '2026-08-04T00:05:52.477641+00:00'
    provider_id: prov-651d553c
    model: sonnet
    started_at: '2026-08-04T00:05:52.477641+00:00'
    branch_key: EXOCOMP-130
    candidate_rotation_count: 1
    failure_classification: infrastructure_error
    ended_at: '2026-08-04T00:06:18.641214+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-130 (tried: origin/EXOCOMP-130)'
    next_retry_at: '2026-08-04T00:06:38.641188+00:00'
  - version: 1
    attempt_id: attempt-bd99dc3e6d26
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: 699247d4044180bc8742a91ac0dabd380d76d676f802dd6608ad24e2c7790af7
    created_at: '2026-08-04T00:07:03.283231+00:00'
    provider_id: prov-651d553c
    model: haiku
    started_at: '2026-08-04T00:07:03.283231+00:00'
    branch_key: EXOCOMP-130
    candidate_rotation_count: 2
    failure_classification: infrastructure_error
    ended_at: '2026-08-04T00:07:10.991496+00:00'
    failure_reason: 'terminal audit evidence has no safely resolvable revision for
      EXOCOMP-130 (tried: origin/EXOCOMP-130)'
    next_retry_at: '2026-08-04T00:07:50.991468+00:00'
---
## Summary

Plan section: Connection and Delivery Protocol.

Deliver the optional coordinator client, outbound mTLS WebSocket sessions, heartbeats, reconnect behavior, durable coordinator event outbox, idempotent server ingestion, sequence acknowledgements, and durable server command delivery. Local cluster operation must not depend on this connection.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 18:32
---
Operator queue-unblock workaround for OOMPAH-733: preserved old epic head 8400a54a under recovery/epic-EXOCOMP-130-pre-parent-sync-8400a54a, rebased the remaining unique plan and EventOutbox commits onto authoritative parent epic-EXOCOMP-127 at 2d08fde7, combined current invitation configuration with EventOutbox configuration in the only source conflicts, passed git diff --check and make fmt-check, and force-pushed with exact lease to 9663f4b2. Parent is an ancestor and local/remote heads match. Ready children may resume normal dependency-ordered integration.
---
author: oompah
created: 2026-08-04 00:04
---
Queued for terminal transition to Done. An auditor will review and apply the terminal status.
---
author: oompah
created: 2026-08-04 00:05
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-04 00:05
---
Run #1 [attempt=1, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 4s
---
author: oompah
created: 2026-08-04 00:05
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-130 (tried: origin/EXOCOMP-130). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-04 00:06
---
Auditor dispatched (attempt #2, candidate: prov-651d553c/sonnet)
---
author: oompah
created: 2026-08-04 00:06
---
Run #2 [attempt=2, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 5s
---
author: oompah
created: 2026-08-04 00:06
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-130 (tried: origin/EXOCOMP-130). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-04 00:07
---
Auditor dispatched (attempt #3, candidate: prov-651d553c/haiku)
---
author: oompah
created: 2026-08-04 00:07
---
Run #3 [attempt=3, profile=auditor, role=— -> unknown/unknown]
- Turns: 0, Tool calls: 0
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: error, Duration: 4s
---
author: oompah
created: 2026-08-04 00:07
---
Auditor attempt ended: terminal audit evidence has no safely resolvable revision for EXOCOMP-130 (tried: origin/EXOCOMP-130). A different independent auditor will be tried on the next scheduler tick.
---
author: oompah
created: 2026-08-04 00:09
---
Needs Human — Done audit requires operator input.

Independent auditor launches exhausted their retry budget because the audit workspace or transport failed before review began. Restore the audit infrastructure, then have a project owner rearm this terminal audit; do not reopen implementation work.
---
author: oompah
created: 2026-08-04 00:42
---
Override by oompah-cli: terminal transition to Done applied by project owner.

Reason: All EXOCOMP-130 child implementation is complete and the canonical origin/epic-EXOCOMP-130 branch exists at verified head 7bf5506c. Audit attempts failed before launch only because the resolver tried the nonexistent origin/EXOCOMP-130 ref; OOMPAH-746 tracks that bug. OOMPAH-747 tracks the remaining rebased-child landing-evidence defect before automatic review.
---
<!-- COMMENTS:END -->
