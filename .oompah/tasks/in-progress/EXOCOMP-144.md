---
id: EXOCOMP-144
type: task
status: In Progress
priority: 1
title: Add cluster certificate renewal and revocation
parent: EXOCOMP-129
children: []
blocked_by:
- EXOCOMP-143
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:14:27.914202Z'
updated_at: '2026-08-01T12:11:48.942159Z'
work_branch: epic-EXOCOMP-129--task-EXOCOMP-144
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 7f788b690fe18007128498a1d78db1652371cfcd3f0f36c0dc220000f7316674
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T12:08:51.156614+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active EXOCOMP-143, EXOCOMP-146, EXOCOMP-170,\
    \ EXOCOMP-178, and EXOCOMP-181. EXOCOMP-143 explicitly excludes renewal and revocation;\
    \ the others cover transport, UI, documentation, or security tests. No active\
    \ task duplicates EXOCOMP-144\u2019s implementation scope."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: d8ac6fb9-a996-487e-b42a-b25f3df7da2a
oompah.work_branch: epic-EXOCOMP-129--task-EXOCOMP-144
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-129--task-EXOCOMP-144
  base_branch: epic-EXOCOMP-129
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:11:33.147330+00:00'
oompah.task_costs:
  total_input_tokens: 1573726
  total_output_tokens: 15273
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 1573726
      output_tokens: 15273
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 1573534
    output_tokens: 15224
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:08:51.155808+00:00'
  - profile: default
    model: haiku
    input_tokens: 192
    output_tokens: 49
    cost_usd: 0.0
    recorded_at: '2026-08-01T12:10:12.567101+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-144__20260801T115823Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-129--task-EXOCOMP-144
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T12:08:51.185286+00:00'
---
## Summary

Plan: plans/mission-control.md, Cluster Enrollment and Identity.

Deliverables:
- Add authenticated POST /api/v1/clusters/renew certificate renewal.
- Permit renewal after day 20 for a valid non-revoked cluster identity and rotate the certificate serial.
- Add admin context operations to revoke a cluster and its active certificate serials.
- Expose deterministic certificate status lookup for the connection gateway.

Acceptance:
- Tests cover early renewal, valid renewal, expired certificate, revoked cluster, identity mismatch, concurrent renewal, and signing failure.
- Revoked identities cannot renew.
- Private keys remain coordinator-local.

Out of scope: UI and active WebSocket disconnection.
Quality gate: focused PKI tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 11:58
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 11:58
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 12:08
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 3, Tool calls: 115
- Tokens: 1.6M in / 15.2K out [1.6M total]
- Cost: $0.0000
- Exit: normal, Duration: 10m 37s
- Log: EXOCOMP-144__20260801T115823Z.jsonl
---
author: oompah
created: 2026-08-01 12:09
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 12:09
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 12:09
---
Understanding: EXOCOMP-144 requires backend PKI implementation including:
1. Authenticated POST /api/v1/clusters/renew endpoint for certificate renewal
2. Certificate serial rotation and 20-day renewal eligibility logic
3. Admin operations to revoke clusters and their certificate serials
4. Deterministic certificate status lookup for the connection gateway

Tests needed for early/valid renewal, expired certs, revoked clusters, identity mismatches, concurrent renewal, signing failures.

However, this task is marked for Frontend Developer focus. The deliverables are backend API and PKI operations with UI explicitly out of scope. No LiveView or UI work is required here. This appears to be a focus mismatch - the work needs a backend specialist, not frontend expertise.
---
author: oompah
created: 2026-08-01 12:09
---
HANDOFF: This task requires backend implementation expertise, not frontend development. The deliverables are:
- API endpoint implementation (POST /api/v1/clusters/renew)
- PKI operations (certificate generation, serial rotation, revocation)
- Database operations (storing certificate serials, revocation status)
- Deterministic certificate lookup logic
- Comprehensive test coverage for PKI scenarios

The task explicitly states 'Out of scope: UI and active WebSocket disconnection,' confirming this is backend-only work. Task is blocked by EXOCOMP-143 (dependency). A backend specialist should take this to implement the certificate renewal/revocation logic in the coordinator app.
---
author: oompah
created: 2026-08-01 12:10
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 0, Tool calls: 11
- Tokens: 192 in / 49 out [241 total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 9s
- Log: EXOCOMP-144__20260801T120912Z.jsonl
---
author: oompah
created: 2026-08-01 12:11
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-08-01 12:11
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 12:11
---
Understanding: EXOCOMP-144 requires coordinator-side certificate renewal, revocation, and status lookup. UI and active WebSocket disconnection are explicitly out of scope. In this frontend-focused session I will verify whether a UI contribution exists, identify the owning backend areas, and hand off with evidence if none does.
---
<!-- COMMENTS:END -->
