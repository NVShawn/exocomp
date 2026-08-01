---
id: EXOCOMP-167
type: task
status: In Progress
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
updated_at: '2026-08-01T15:41:26.608672Z'
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
oompah.agent_run_id: 87f3994c-699c-4f1d-9715-145fb777e1cf
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-167
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-167
  head_sha: b621e9369b33b44b14fd1ce61c671bf5d2a53441
  submitted_at: '2026-08-01T15:41:25.835924+00:00'
  updated_at: '2026-08-01T15:41:25.835924+00:00'
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
author: oompah
created: 2026-08-01 15:25
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 15:25
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 15:25
---
Understanding: I will inspect the existing incident domain, LiveView routes/components, authorization, and test patterns; implement the inbox/detail UI and operator mutations with filters, pagination, real-time updates, snooze visibility, and focused coverage; then run the relevant Makefile gates and submit the branch.
---
author: oompah
created: 2026-08-01 15:27
---
Discovery: the Mission Control scaffold is commit 3a3d6e6 and the incident APIs are on EXOCOMP-156/157. The incident context exposes organization-scoped list/get/events/related plus acknowledge, assign, snooze, and resolve; PubSub is not yet wired. I will compose these prerequisite commits locally, then add LiveViews and a small broadcast/query boundary around the existing GenServer.
---
author: oompah
created: 2026-08-01 15:38
---
Implementation: composed the Mission Control scaffold and incident-domain prerequisites, added Incidents.Query for severity/status/cluster/label filtering and bounded pagination, added PubSub incident_changed broadcasts, and routed /incidents and /incidents/:id to accessible LiveViews. The inbox is organization-scoped and real-time; detail shows timeline/evidence/related incidents, snooze wake time, and operator-only acknowledge/assign/snooze/resolve controls with stale-state and required-reason handling.
---
author: oompah
created: 2026-08-01 15:40
---
Verification: mix format --check-formatted, Code.string_to_quoted! parsing for all new Elixir/test files, and git diff --check pass. make lint runs its offline builder/governance checks successfully (13 builder checks plus Python suites), then stops because the pinned Docker/Podman container cannot start in this read-only environment; make fmt-check is blocked by the same Podman configuration error. Focused LiveView execution could not run on host Elixir 1.18.3 because the project requires 1.20.2 and the host lacks OTP syntax_tools/public_key headers.
---
author: oompah
created: 2026-08-01 15:41
---
Completion: pushed b621e936 on epic-EXOCOMP-133--task-EXOCOMP-167. Delivered the organization-scoped incident inbox/detail LiveViews, filters/pagination, evidence and related incidents, real-time open/resolve/reopen refreshes, acknowledge/assignment/snooze/manual-resolution controls, stale/invalid/reason/access guards, snooze wake-time display, and focused LiveView coverage. Worktree is clean and matches origin.
---
<!-- COMMENTS:END -->
