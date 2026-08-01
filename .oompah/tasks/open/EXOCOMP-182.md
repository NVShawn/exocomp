---
id: EXOCOMP-182
type: task
status: Open
priority: 1
title: Build the two-cluster Mission Control qualification scenario
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-169
- EXOCOMP-173
- EXOCOMP-180
- EXOCOMP-181
start_blocked_by: &id001
- EXOCOMP-206
labels: []
assignee: null
created_at: '2026-07-30T14:18:50.264411Z'
updated_at: '2026-08-01T13:23:44.371790Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-182
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 12d5f82dfa36562bf0e8044aaa77f565d83f36c10a7b2bb36e9af3cdb60223fc
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:23:40.524438+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active EXOCOMP-180, EXOCOMP-184, EXOCOMP-186,\
    \ EXOCOMP-206, and related Mission Control tasks. Their scopes cover reconnect\
    \ testing, release qualification, or Ceph safe restart; none duplicates EXOCOMP-182\u2019\
    s complete two-cluster workflow. Terminal tasks were excluded."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: bec8aea6-86d2-471b-83d0-7fca90f92b44
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-182
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-182
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:19:52.554108+00:00'
oompah.task_costs:
  total_input_tokens: 302448
  total_output_tokens: 6980
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 302448
      output_tokens: 6980
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 302448
    output_tokens: 6980
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:23:40.523339+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-182__20260801T131955Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-182
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:23:40.530654+00:00'
---
## Summary

Plan: plans/mission-control.md, Test Strategy.

Deliverables:
- Automate the planned two-cluster scenario: connect and report nodes; open/deduplicate a failed-service incident; converse with the cluster-local model; receive a cited typed proposal; approve once; revalidate, execute once, verify, and report the audit timeline.
- Force disconnect/reconnect during the scenario.
- Capture machine-readable results and raw evidence.

Acceptance:
- No duplicate incident, message, approval, or execution appears.
- Every timeline item shares the expected correlation chain.
- Failure at any step exits nonzero with the failed phase and retained evidence path.

Out of scope: 100-cluster load and release publication.
Quality gate: a dedicated noninteractive Make qualification target.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: incorporate the VM-qualified EXOCOMP-206 path so the two-cluster scenario includes composed service expectations, one coordinator-declared Ceph profile, a deduplicated failed-daemon incident, exactly-once safe restart, stable verification, and reconnect replay.
---
author: oompah
created: 2026-08-01 13:19
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:19
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:23
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 2, Tool calls: 61
- Tokens: 302.4K in / 7.0K out [309.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 52s
- Log: EXOCOMP-182__20260801T131955Z.jsonl
---
<!-- COMMENTS:END -->
