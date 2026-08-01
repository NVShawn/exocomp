---
id: EXOCOMP-172
type: task
status: In Progress
priority: 1
title: Store encrypted webhook endpoint configuration
parent: EXOCOMP-134
children: []
blocked_by:
- EXOCOMP-141
- EXOCOMP-171
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:36.185587Z'
updated_at: '2026-08-01T13:07:09.271441Z'
work_branch: epic-EXOCOMP-134--task-EXOCOMP-172
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 1457c029666336ab9687f1ee0b0ae7d6403cab50c3b23df4fd2f63d1543a99b7
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:06:48.494024+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active tasks EXOCOMP-134, EXOCOMP-170, EXOCOMP-171, EXOCOMP-173,
    and EXOCOMP-181. They cover parent orchestration, UI, audit/redaction, delivery,
    and security testing respectively; none duplicates encrypted organization-scoped
    endpoint configuration. Terminal tasks were excluded.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 49bafc99-8503-4487-a8b6-c7d173dffa86
oompah.work_branch: epic-EXOCOMP-134--task-EXOCOMP-172
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-134--task-EXOCOMP-172
  base_branch: epic-EXOCOMP-134
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:07:06.008369+00:00'
oompah.task_costs:
  total_input_tokens: 336036
  total_output_tokens: 2464
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 336036
      output_tokens: 2464
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 336036
    output_tokens: 2464
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:06:48.492536+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-172__20260801T130549Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-134--task-EXOCOMP-172
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:06:48.497734+00:00'
---
## Summary

Plan: plans/mission-control.md, Webhooks.

Deliverables:
- Add organization-scoped webhook endpoints with URL, subscribed event types, enabled state, encrypted HMAC secret, and timestamps.
- Generate a secret, show it once, and encrypt it using a configured deployment master key.
- Add admin-only create, update subscriptions, disable, and rotate-secret context functions.

Acceptance:
- Tests cover encryption round-trip, missing/wrong master key, HTTPS URL validation, disallowed/private destinations per configured policy, secret one-time display, rotation, roles, and organization isolation.
- Plaintext secrets are absent from database/log inspection.

Out of scope: HTTP delivery.
Quality gate: focused webhook-context tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:05
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:05
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:06
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 8
- Tokens: 336.0K in / 2.5K out [338.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 6s
- Log: EXOCOMP-172__20260801T130549Z.jsonl
---
author: oompah
created: 2026-08-01 13:07
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 13:07
---
Focus: Security Auditor
---
<!-- COMMENTS:END -->
