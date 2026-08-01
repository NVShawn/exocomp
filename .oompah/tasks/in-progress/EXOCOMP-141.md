---
id: EXOCOMP-141
type: task
status: In Progress
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
assignee: null
created_at: '2026-07-30T14:14:23.272282Z'
updated_at: '2026-08-01T12:18:48.054393Z'
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
oompah.agent_run_id: 386e0b92-b1f2-4bc4-96c5-a2d5b63dddb0
oompah.work_branch: epic-EXOCOMP-129--task-EXOCOMP-141
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-129--task-EXOCOMP-141
  base_branch: epic-EXOCOMP-129
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:00:10.348715+00:00'
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
author: oompah
created: 2026-08-01 12:00
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-08-01 12:00
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 12:00
---
Understanding: I am the Maintenance Engineer focus. Based on prior agent handoffs, this task requires implementing Phoenix/Ecto backend authorization for Mission Control: operator identity schemas, OIDC role mapping, authorization plugs/hooks, and a mutation audit helper. I will read the plan, explore the current app structure, and implement the required authorization modules with a complete role matrix test.
---
author: oompah
created: 2026-08-01 12:04
---
Discovery: No Mission Control app exists yet - the umbrella has only exocomp_core, exocomp_node, exocomp_coordinator, and bench. Elixir 1.20.2 is required (available in Docker via make targets). I will create apps/exocomp_mission_control with: (1) Identity.Operator and Identity.RoleBinding structs scoped to organization_id, (2) Auth.OIDCResolver mapping claims/groups to viewer/operator/admin roles, (3) Authorization module with can_read?/can_operate?/can_administer? context functions enforcing org scope, (4) Plug.RequireRole for HTTP requests, (5) LiveView.RequireRole on_mount hook, (6) Mutations.Attribution helper recording OIDC subject + correlation ID. Tests cover full role matrix and cross-org fail-closed semantics. No Phoenix or Ecto deps required - this is pure Elixir using only the already-locked plug and jason packages.
---
author: oompah
created: 2026-08-01 12:18
---
Implementation: Created apps/exocomp_mission_control with the following modules:

1. Identity.Operator — struct for authenticated operator principals: sub (stable OIDC subject), organization_id, display_name, role (:viewer/:operator/:admin), plus has_role_at_least?/2 and compare_roles/2 for hierarchy checks.

2. Identity.RoleBinding — struct for org-scoped role assignments; matches?/3 enforces cross-org isolation at the data layer.

3. Auth.OIDCResolver — maps configured OIDC claims to roles per organization. Supports group_claim mapping (takes highest-privilege role from multiple groups) and subject_role_map overrides. Falls back to {:error, :no_role} for unrecognized identities; {:error, :no_config} for unknown orgs. Loaded from application config :oidc_role_config.

4. Authorization — context-level enforcement (not UI). authorize/3 checks org scope first (cross-org → :cross_organization), then role (:read=viewer+, :operate=operator+, :administer=admin). authorize!/3 raises ForbiddenError. Convenience predicates: can_read?/2, can_operate?/2, can_administer?/2.

5. Authorization.ForbiddenError — exception carrying :reason and :action for audit.

6. Plug.RequireRole — HTTP plug; resolves org from path_params, assigns, or operator struct; halts with 403 + JSON body on denial.

7. LiveView.RequireRole — on_mount/4 hook; redirects to / with flash error on denial. Defers Phoenix.LiveView calls to avoid hard compile-time dep.

8. Mutations.Attribution — captures sub, display_name, organization_id, correlation_id (corr_ prefix + URL-safe base64), and timestamp for every mutation.
---
author: oompah
created: 2026-08-01 12:18
---
Verification: All quality gates pass.

make test: 511 passed (full suite), 128 passed (mission_control app, including full role matrix), 0 failures.

Role matrix coverage (18 test cases in authorization_test.exs):
- viewer/operator/admin × :read/:operate/:administer × same-org → all allowed/denied correctly
- viewer/operator/admin × :read/:operate/:administer × cross-org → all return {:error, :cross_organization}
- nil and non-operator operator → {:error, :unauthenticated} for all actions
- ForbiddenError carries reason and action on raise

OIDC resolver coverage: subject override, group claim, highest-privilege merge, multi-group, no-config, no-match, display name extraction, app env fallback.

Plug coverage: init/1 validation, allowed/denied requests via Plug.Test, 403 JSON body, cross-org denial, unauthenticated denial.

Attribution coverage: uniqueness, timestamp bounds, correlation ID format (URL-safe, no padding), to_map/1 JSON encoding.

make fmt-check: pass
make lint: pass (compliance: all checks passed)
---
<!-- COMMENTS:END -->
