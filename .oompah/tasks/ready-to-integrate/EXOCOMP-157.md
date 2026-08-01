---
id: EXOCOMP-157
type: task
status: Ready to Integrate
priority: 2
title: Group related incidents deterministically
parent: EXOCOMP-131
children: []
blocked_by:
- EXOCOMP-154
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:15:42.626270Z'
updated_at: '2026-08-01T15:14:52.813338Z'
work_branch: epic-EXOCOMP-131--task-EXOCOMP-157
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 60e13a034173ec19764a3b705480fc7b6e53f9c2be98d31ebc428ce7f94b9ed7
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:58:11.892031+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: EXOCOMP-154 covers incident persistence, fingerprints,\
    \ and lifecycle\u2014not deterministic related-incident grouping or query helpers.\
    \ The remaining matching material is only the Mission Control plan specification."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: e3287d4b-05e3-4674-be5e-446c54b26a50
oompah.work_branch: epic-EXOCOMP-131--task-EXOCOMP-157
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: epic-EXOCOMP-131--task-EXOCOMP-157
  head_sha: 4f0fb39c88994c605a8afa7d8fa79a167da07d11
  submitted_at: '2026-08-01T15:14:41.866158+00:00'
  updated_at: '2026-08-01T15:14:41.866158+00:00'
oompah.task_costs:
  total_input_tokens: 568972
  total_output_tokens: 4159
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 568972
      output_tokens: 4159
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 568972
    output_tokens: 4159
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:58:11.888551+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-157__20260801T145623Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-131--task-EXOCOMP-157
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:58:11.900890+00:00'
---
## Summary

Plan: plans/mission-control.md, Fleet Status and Incidents.

Deliverables:
- Add a pure grouping module using alert type, service, software version, and configured time window.
- Return group keys and display summaries without changing incident identity or state.
- Add query helpers for fetching related open/recent incidents within an organization.

Acceptance:
- Tests cover matching/nonmatching attributes, window boundaries, missing version/service, organization isolation, and deterministic ordering.
- No central inference call or causal claim is introduced.

Out of scope: incident UI and model-generated summaries.
Quality gate: focused grouping tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:56
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:56
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:58
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 17
- Tokens: 569.0K in / 4.2K out [573.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 55s
- Log: EXOCOMP-157__20260801T145623Z.jsonl
---
author: oompah
created: 2026-08-01 14:59
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 14:59
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 15:00
---
Understanding: implement a pure, deterministic incident-grouping module keyed by alert type, service, software version, and configured time window; preserve incident identity/state; add organization-scoped open/recent related-incident query helpers; cover attribute matching, boundaries, missing values, isolation, and ordering without causal/model inference.
---
author: oompah
created: 2026-08-01 15:08
---
Implementation: fast-forwarded onto EXOCOMP-154's incident store, added optional service/software_version metadata without changing fingerprint identity, introduced pure Grouping key/related/group/summary functions with inclusive windows and stable ordering, and added organization-scoped open/recent/related query helpers. Focused tests cover the requested grouping and query behavior.
---
author: oompah
created: 2026-08-01 15:14
---
Verification: direct ExUnit harness ran the dependency incident tests plus grouping/query tests: 21 tests, 0 failures. New modules compile with elixirc --warnings-as-errors; local mix format --check-formatted and git diff --check pass. make fmt-check and make lint reached the pinned Podman builder but were blocked by the environment's read-only /run/user/1000/libpod configuration; no code failure was reported.
---
author: oompah
created: 2026-08-01 15:14
---
Completion: delivered commit 4f0fb39c and pushed branch epic-EXOCOMP-131--task-EXOCOMP-157. The pure grouping projection, deterministic summaries, optional grouping metadata, and organization-scoped open/recent/related queries are covered by focused tests; identity and lifecycle state remain unchanged.
---
author: oompah
created: 2026-08-01 15:14
---
Add deterministic incident grouping, summaries, and organization-scoped related/open/recent queries with focused coverage.
---
author: oompah
created: 2026-08-01 15:14
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 107
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 15m 2s
- Log: EXOCOMP-157__20260801T145956Z.jsonl
---
<!-- COMMENTS:END -->
