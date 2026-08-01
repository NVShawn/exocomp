---
id: EXOCOMP-173
type: task
status: In Progress
priority: 1
title: Sign, deliver, retry, and replay webhook events
parent: EXOCOMP-134
children: []
blocked_by:
- EXOCOMP-172
- EXOCOMP-171
- EXOCOMP-139
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:37.354425Z'
updated_at: '2026-08-01T13:10:21.476993Z'
work_branch: epic-EXOCOMP-134--task-EXOCOMP-173
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 974b8b6bcb879f8b26c495c04aeef6d73b48a9b586d101e81e47ecba2dfbe798
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:08:32.878248+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active EXOCOMP-172 (endpoint configuration), EXOCOMP-171 (audit/redaction),
    EXOCOMP-134 (parent epic), EXOCOMP-130/148/150 (cluster transport/outboxes), and
    EXOCOMP-170 (admin UI, explicitly excluding delivery attempts). Their scopes are
    distinct from webhook signing, delivery retries, and replay. Terminal tasks were
    excluded.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 9c6307eb-d099-420d-8349-5d6ed9836be8
oompah.work_branch: epic-EXOCOMP-134--task-EXOCOMP-173
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-134--task-EXOCOMP-173
  base_branch: epic-EXOCOMP-134
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:08:52.078073+00:00'
oompah.task_costs:
  total_input_tokens: 418683
  total_output_tokens: 3179
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 418683
      output_tokens: 3179
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 418683
    output_tokens: 3179
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:08:32.877347+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-173__20260801T130716Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-134--task-EXOCOMP-173
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:08:32.885707+00:00'
---
## Summary

Plan: plans/mission-control.md, Webhooks.

Deliverables:
- Add durable webhook events and delivery-attempt records.
- Sign event ID, delivery timestamp, and exact JSON body with HMAC-SHA256.
- Deliver with bounded timeouts and jittered exponential retry for up to 24 hours.
- Add admin inspection and manual replay that creates a new attempt for the retained event.

Acceptance:
- Tests cover signature vectors, successful delivery, duplicate-safe event ID, timeout, 4xx/5xx, retry schedule, terminal failure, disabled endpoint, rotation, replay, and redaction.
- Request bodies are byte-identical to the signed content.

Out of scope: native Slack/email/PagerDuty integrations.
Quality gate: focused delivery tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:07
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:07
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:08
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 7
- Tokens: 418.7K in / 3.2K out [421.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 27s
- Log: EXOCOMP-173__20260801T130716Z.jsonl
---
author: oompah
created: 2026-08-01 13:08
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 13:08
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 13:10
---
Understanding: Task is to implement webhook event signing, delivery, retry, and replay functionality for Mission Control. Deliverables include: (1) durable webhook event/delivery-attempt records, (2) HMAC-SHA256 signing of event ID, timestamp, and exact JSON body, (3) delivery with exponential retry up to 24 hours with bounded timeouts, (4) admin inspection and manual replay. Will explore current codebase state to determine what infrastructure exists from blocked dependencies.
---
<!-- COMMENTS:END -->
