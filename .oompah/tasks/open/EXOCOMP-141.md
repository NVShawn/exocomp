---
id: EXOCOMP-141
type: task
status: Open
priority: 1
title: Enforce viewer, operator, and admin authorization
parent: EXOCOMP-129
children: []
blocked_by:
- EXOCOMP-140
- EXOCOMP-138
start_blocked_by: []
labels:
- focus-complete:frontend
- needs:feature
assignee: null
created_at: '2026-07-30T14:14:23.272282Z'
updated_at: '2026-08-01T11:58:32.775320Z'
work_branch: epic-EXOCOMP-129--task-EXOCOMP-141
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: e870e84d569c131f18582cc1b814f0f986b0048b3c84c378caefe54253873b4a
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T11:53:47.766090+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active EXOCOMP-138, EXOCOMP-140, EXOCOMP-156,\
    \ EXOCOMP-162, EXOCOMP-164, EXOCOMP-171, and related parent/UI tasks. They cover\
    \ scoping, OIDC login, feature mutations, UI guards, or audit storage; none duplicates\
    \ EXOCOMP-141\u2019s role-binding and context authorization scope."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: df691d74-4689-4b06-a5ca-07d06f7fd3c8
oompah.work_branch: epic-EXOCOMP-129--task-EXOCOMP-141
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-129--task-EXOCOMP-141
  base_branch: epic-EXOCOMP-129
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T11:56:54.972943+00:00'
oompah.task_costs:
  total_input_tokens: 392651
  total_output_tokens: 4736
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 392651
      output_tokens: 4736
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 392325
    output_tokens: 4671
    cost_usd: 0.0
    recorded_at: '2026-08-01T11:53:47.765349+00:00'
  - profile: default
    model: haiku
    input_tokens: 326
    output_tokens: 65
    cost_usd: 0.0
    recorded_at: '2026-08-01T11:55:51.936316+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-141__20260801T115045Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-129--task-EXOCOMP-141
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T11:53:47.776528+00:00'
---
## Summary

Plan: plans/mission-control.md, Organization and Operator Identity.

Deliverables:
- Add operator identity and role-binding schemas scoped to organization_id.
- Map configured OIDC claims/groups to viewer, operator, or admin.
- Add plugs/on_mount hooks and context-level authorization functions for read, operate, and administer actions.
- Add a helper that records the stable OIDC subject and correlation ID for mutations.

Acceptance:
- A role matrix test covers every allowed and denied operation.
- Removing a UI control does not bypass context authorization.
- Cross-organization role bindings fail closed.

Out of scope: feature-specific mutations and admin pages.
Quality gate: focused authorization tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 11:50
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 11:50
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 11:53
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 2, Tool calls: 18
- Tokens: 392.3K in / 4.7K out [397.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 10s
- Log: EXOCOMP-141__20260801T115045Z.jsonl
---
author: oompah
created: 2026-08-01 11:54
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 11:54
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 11:55
---
## Understanding & Initial Assessment

**Interpretation:** EXOCOMP-141 requires implementing authorization enforcement for a Mission Control system with three role levels (viewer, operator, admin) scoped to organizations. The deliverables include:
1. Database schemas for operator identity and role bindings
2. OIDC claims/groups to role mapping logic
3. Authorization plugs and context-level enforcement functions
4. Audit logging for mutations (OIDC subject, correlation ID)

**Task Classification Issue:** This task was dispatched to Frontend Developer role, but the work is primarily backend authorization logic (Elixir/Phoenix):
- No Mission Control app exists yet; must scaffold it
- Database schema design is backend work
- OIDC integration is backend work
- Authorization plugs/hooks are backend enforcement (not UI)
- Context functions are backend business logic

The frontend aspect mentioned in acceptance criteria ("Removing a UI control does not bypass context authorization") means the UI should NOT be the only authorization boundary—it's a test of backend enforcement, not frontend work.

**Recommendation:** This should be handed off to a backend/feature focus agent to:
- Create the mission_control app structure
- Implement schemas and database migrations
- Add OIDC authentication and role mapping
- Implement context-level authorization functions
- Write comprehensive role matrix tests

The Frontend Developer role is not the right fit for the core implementation. Request dispatch to backend-capable focus.
---
author: oompah
created: 2026-08-01 11:56
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 0, Tool calls: 15
- Tokens: 326 in / 65 out [391 total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 38s
- Log: EXOCOMP-141__20260801T115422Z.jsonl
---
author: oompah
created: 2026-08-01 11:56
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-08-01 11:56
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 11:57
---
Understanding: I will locate the Mission Control organization/authentication foundations and plan, then implement organization-scoped role resolution and context enforcement with a complete authorization matrix. I will preserve fail-closed behavior across organizations and verify via focused tests plus repository quality gates.
---
author: oompah
created: 2026-08-01 11:57
---
Discovery: The current umbrella contains coordinator/node applications only; no Mission Control or Phoenix app exists in this worktree. The plan defines the authorization contract but no implementation boundary yet. I am checking dependency task interfaces before adding the foundational authorization modules.
---
author: oompah
created: 2026-08-01 11:58
---
Focus handoff: frontend\n\nOutcome: No frontend work is actionable. EXOCOMP-141 is a backend authorization foundation and the current umbrella has no Mission Control/Phoenix application or OIDC/UI code.\n\nEvidence:  defines only exocomp_node and exocomp_coordinator releases;  contains exocomp_core, exocomp_node, exocomp_coordinator, and bench. The required contract is in  under Organization and Operator Identity (lines 105-125) and Persistence and Retention (lines 322-338).\n\nRemaining work/risks: create the Mission Control app and persistence boundary, add organization/operator/role schemas, OIDC role resolver, Plug/LiveView guards, context-level checks, mutation audit attribution, and the full role/cross-org matrix. UI visibility must remain only a presentation concern.\n\nRecommended next focus: feature (backend Phoenix/Ecto authorization).
---
author: oompah
created: 2026-08-01 11:58
---
Focus handoff: frontend

Outcome: No frontend work is actionable. EXOCOMP-141 is a backend authorization foundation and the current umbrella has no Mission Control/Phoenix application or OIDC/UI code.

Evidence: the root mix.exs defines only exocomp_node and exocomp_coordinator releases; apps contains exocomp_core, exocomp_node, exocomp_coordinator, and bench. The required contract is in plans/mission-control.md under Organization and Operator Identity (lines 105-125) and Persistence and Retention (lines 322-338).

Remaining work/risks: create the Mission Control app and persistence boundary, add organization/operator/role schemas, OIDC role resolver, Plug/LiveView guards, context-level checks, mutation audit attribution, and the full role/cross-org matrix. UI visibility must remain only a presentation concern.

Recommended next focus: feature (backend Phoenix/Ecto authorization).
---
author: oompah
created: 2026-08-01 11:58
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/gpt-5.6-terra]
- Turns: 0, Tool calls: 26
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 1m 40s
- Log: EXOCOMP-141__20260801T115658Z.jsonl
---
<!-- COMMENTS:END -->
