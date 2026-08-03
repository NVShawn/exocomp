---
id: EXOCOMP-236
type: task
status: Open
priority: null
title: Add broker and privilege-boundary security tests
parent: EXOCOMP-212
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-230
- EXOCOMP-234
labels: []
assignee: null
created_at: '2026-08-03T14:28:16.134826Z'
updated_at: '2026-08-03T15:55:05.857085Z'
work_branch: epic-EXOCOMP-212--task-EXOCOMP-236
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: e1e24cc1f1fdf59b4829e1cb1ace27917212d4e7a147bf55781aa99e0fe75e10
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:55:00.228526+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: Reviewed active peers EXOCOMP-230, EXOCOMP-234, EXOCOMP-235,\
    \ EXOCOMP-237, and EXOCOMP-239 with their full descriptions/comments. EXOCOMP-230\
    \ owns broker packaging and sudo migration; EXOCOMP-234 owns bypass-path inventory\
    \ and mixed-version gating; EXOCOMP-235 explicitly excludes installer privilege-boundary\
    \ tests. EXOCOMP-236 uniquely owns focused negative broker, installer, packaging,\
    \ fail-closed, and audit-leakage tests. No active duplicate confirmed.\nFocus\
    \ handoff: duplicate_detector  \nDuplicate preflight verdict: no_duplicate  \n\
    Matches: none  \n\nEvidence: Reviewed active peers EXOCOMP-230, EXOCOMP-234, EXOCOMP-235,\
    \ EXOCOMP-237, and EXOCOMP-239 with their full descriptions/comments. EXOCOMP-230\
    \ owns broker packaging and sudo migration; EXOCOMP-234 owns bypass-path inventory\
    \ and mixed-version gating; EXOCOMP-235 explicitly excludes installer privilege-boundary\
    \ tests. EXOCOMP-236 uniquely owns focused negative broker, installer, packaging,\
    \ fail-closed, and audit-leakage tests. No active duplicate confirmed."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: abdc34ed-8a52-4aa2-8833-dbfbbd288eb7
oompah.work_branch: epic-EXOCOMP-212--task-EXOCOMP-236
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-212--task-EXOCOMP-236
  base_branch: epic-EXOCOMP-212
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:53:05.551074+00:00'
oompah.task_costs:
  total_input_tokens: 710780
  total_output_tokens: 3058
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 710780
      output_tokens: 3058
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 710780
    output_tokens: 3058
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:55:00.227492+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-236__20260803T155310Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-212--task-EXOCOMP-236
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:55:00.243951+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable:
Add automated negative tests proving that untrusted processes cannot bypass the privileged broker or use malformed authorization data to mutate a node.

Acceptance criteria:
- Reject missing, expired, replayed, forged, wrongly scoped, and tampered policy bundles and action permits.
- Reject unknown actions, extra arguments, target mismatches, and requests whose resolved mode is observe.
- Verify package and sudo configuration exposes only the exact no-argument broker entry point required by the plan.
- Add a static or packaging check that detects newly introduced direct mutation sudo paths.
- Verify failures are fail-closed and emit useful audit records without leaking signing material.

Tests:
- Add focused broker, installer, and packaging negative tests.
- Run the applicable installer or packaging Makefile targets plus make test, make fmt-check, and make lint.

Out of scope:
- Implementing broker actions or operating the dual-architecture qualification environment.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:52
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:53
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:55
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 7
- Tokens: 710.8K in / 3.1K out [713.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 1s
- Log: EXOCOMP-236__20260803T155310Z.jsonl
---
<!-- COMMENTS:END -->
