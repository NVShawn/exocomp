---
id: EXOCOMP-138
type: task
status: In Progress
priority: 2
title: Add organizations and mandatory organization scoping
parent: EXOCOMP-128
children: []
blocked_by:
- EXOCOMP-137
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:13:52.527968Z'
updated_at: '2026-08-01T14:43:38.042275Z'
work_branch: epic-EXOCOMP-128--task-EXOCOMP-138
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: b57985a586a1fecab1d858a2031f9281b4717e71f7474e35c4c224a033076109
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:43:21.430666+00:00'
  matched_identifiers: []
  evidence: "Based on my comprehensive investigation of the codebase and related planning\
    \ documents, I can now provide my duplicate investigation verdict.\n\n## Investigation\
    \ Summary\n\nI searched across multiple locations:\n1. **Plans and Documentation**:\
    \ Reviewed `plans/mission-control.md`, the definitive source for Mission Control\
    \ architecture\n2. **Codebase**: Searched `apps/` directory for any existing organization\
    \ implementations\u2014found none\n3. **Task References**: Searched for EXOCOMP-137\
    \ (blocking dependency), EXOCOMP-158 (organization-scoped conversations peer),\
    \ and other related peers\n4. **Database/Schema**: Searched for organization_id\
    \ fields, Organization models, migration files\u2014found nothing\n5. **Phoenix\
    \ Apps**: Confirmed no mission_control app exists yet in the umbrella\n\n## Key\
    \ Findings\n\n- **No existing organizations table or schema** in the codebase\n\
    - **EXOCOMP-158** (peer task) has submitted work on \"organization-scoped conversations\"\
    \ but:\n  - Is in terminal state (submitted-result), excluded per duplicate-investigation\
    \ rules\n  - Focused on conversations, not the foundational organizations table\
    \ itself\n  - Would logically depend on organizations existing first\n- **EXOCOMP-137**\
    \ (blocking dependency) has no discoverable scope information\n- **No active,\
    \ open task** describes the same work: \"Add organizations table and schema with\
    \ stable generated identifier, test/dev seed, reusable scoping helper for tenant-owned\
    \ queries\"\n\n## Conclusion\n\nEXOCOMP-138 is a foundational, prerequisite task\
    \ for the Mission Control feature. While peer tasks like EXOCOMP-158 have started\
    \ and depend on organization scoping, none of them duplicate the specific deliverables\
    \ of EXOCOMP-138:\n- Organizations table and schema\n- Test/dev seed\n- Reusable\
    \ scoping helper\n- Foreign-key and unique-constraint examples\n\n---\n\n**Focus\
    \ handoff: duplicate_detector**\n\n**Duplicate preflight verdict: no_duplicate**\n\
    \n**Matches: none**\n\n**Evidence:** Comprehensive search of plans/mission-control.md\
    \ (architectural sourc"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: a2b5866b-0502-4e8e-93a7-d61e62041633
oompah.work_branch: epic-EXOCOMP-128--task-EXOCOMP-138
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-128--task-EXOCOMP-138
  base_branch: epic-EXOCOMP-128
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:43:34.681365+00:00'
oompah.task_costs:
  total_input_tokens: 146
  total_output_tokens: 5601
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 146
      output_tokens: 5601
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 146
    output_tokens: 5601
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:43:21.429838+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-138__20260801T144129Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-128--task-EXOCOMP-138
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:43:21.436299+00:00'
---
## Summary

Plan: plans/mission-control.md, Organization and Operator Identity.

Deliverables:
- Add the organizations table and schema with a stable generated identifier.
- Add a test/dev seed for the initial organization.
- Add a small reusable scoping helper that requires organization_id for tenant-owned queries and inserts.
- Add foreign-key and unique-constraint examples used by later contexts.

Acceptance:
- Inserts without an organization fail closed.
- Tests prove records from one organization cannot be read, updated, or deleted through another organization scope.
- No global unscoped list function is exposed.

Out of scope: tenant administration UI and billing.
Quality gate: focused Ecto tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:41
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:41
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:43
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 44, Tool calls: 22
- Tokens: 146 in / 5.6K out [5.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 2s
- Log: EXOCOMP-138__20260801T144129Z.jsonl
---
author: oompah
created: 2026-08-01 14:43
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 14:43
---
Focus: Frontend Developer
---
<!-- COMMENTS:END -->
