---
id: EXOCOMP-167
type: task
status: Open
priority: 2
title: Build the incident inbox and detail LiveViews
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-164
- EXOCOMP-156
- EXOCOMP-157
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:01.826681Z'
updated_at: '2026-08-01T15:23:54.093602Z'
work_branch: epic-EXOCOMP-133--task-EXOCOMP-167
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 042bbe211e5d1da761f0db322eab554f23801783fbc87fc2363f87df7bf1abfc
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T15:23:47.138257+00:00'
  matched_identifiers: []
  evidence: "Based on my comprehensive investigation, I can now provide my verdict\
    \ on whether EXOCOMP-167 is a duplicate.\n\n## Investigation Summary\n\n**What\
    \ I searched for:**\n1. Existing tasks or code related to \"incident inbox\",\
    \ \"incident detail view\", \"LiveView\"\n2. Related tasks mentioned in coordination\
    \ messages (EXOCOMP-156, EXOCOMP-157, EXOCOMP-164, EXOCOMP-165, EXOCOMP-166, EXOCOMP-168,\
    \ EXOCOMP-169, EXOCOMP-170)\n3. Mission control documentation to understand the\
    \ scope\n\n**What I found:**\n- **EXOCOMP-157** (dependency, already submitted):\
    \ \"Add deterministic incident grouping, summaries, and organization-scoped related/open/recent\
    \ queries\" \u2014 This is **backend work** (database queries), not UI\n- **mission-control.md\
    \ plan**: Describes the complete Mission Control system including a \"Incident\
    \ inbox\" UI component but does NOT show any other active task building this same\
    \ view\n- **No evidence** of another task also building incident inbox or detail\
    \ LiveViews in the active codebase\n- The epic siblings (EXOCOMP-165, EXOCOMP-166,\
    \ EXOCOMP-168, EXOCOMP-169, EXOCOMP-170) appear to cover different components\
    \ based on coordination patterns\n\n**Clear distinction:**\n- EXOCOMP-167 is **frontend/UI\
    \ work** (incident inbox and detail LiveViews with filters, pagination, operator\
    \ controls)\n- EXOCOMP-157 (completed dependency) is **backend work** (incident\
    \ queries and grouping)\n- These are complementary, not duplicative\n\nNo active\
    \ duplicate task was identified during this investigation.\n\n---\n\nFocus handoff:\
    \ duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\nMatches:\
    \ none\n\nEvidence: Comprehensive search found no other active task building incident\
    \ inbox or detail LiveViews. EXOCOMP-157 (completed dependency) covers backend\
    \ incident queries\u2014a different component. Mission-control.md plan describes\
    \ the UI requirements but shows no evidence of parallel work on these same views.\
    \ The task EXOCOMP-167 appears to be the single implementation task for these\
    \ UI components."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 34d5ee76-e05a-4435-b363-39379c173dfd
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-167
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-167
  base_branch: epic-EXOCOMP-133
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T15:21:04.450968+00:00'
oompah.task_costs:
  total_input_tokens: 194
  total_output_tokens: 7614
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 194
      output_tokens: 7614
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 194
    output_tokens: 7614
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:23:47.135229+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-167__20260801T152107Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-133--task-EXOCOMP-167
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T15:23:47.149193+00:00'
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Add severity/status/cluster/label filters and pagination to the incident inbox.
- Add an incident timeline/detail view with evidence and related incidents.
- Add operator controls for acknowledge, assignment, snooze, and manual resolution with required reason.

Acceptance:
- LiveView tests cover filters, pagination, real-time open/reopen/resolve, each mutation, invalid transition, stale form, viewer denial, and organization isolation.
- Snoozed incidents remain queryable and display the wake time.

Out of scope: notifications and chat UI.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:21
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:21
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 15:23
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 70, Tool calls: 32
- Tokens: 194 in / 7.6K out [7.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 46s
- Log: EXOCOMP-167__20260801T152107Z.jsonl
---
<!-- COMMENTS:END -->
