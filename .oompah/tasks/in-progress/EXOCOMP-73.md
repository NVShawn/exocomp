---
id: EXOCOMP-73
type: task
status: In Progress
priority: null
title: Implement PolicyContext and eligibility-filter pipeline
parent: EXOCOMP-22
children: []
blocked_by:
- EXOCOMP-21
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T22:50:44.926199Z'
updated_at: '2026-07-24T00:52:20.315220Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 9185326d-4d21-445a-8bc1-8a114b3ab8b4
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 336204
  total_output_tokens: 2075
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 336204
      output_tokens: 2075
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 336204
    output_tokens: 2075
    cost_usd: 0.0
    recorded_at: '2026-07-24T00:52:10.243401+00:00'
---
## Summary

Implement the first stage of the EXOCOMP-22 policy engine: a PolicyContext struct and an eligibility filter pipeline that takes a Proposal, a list of ActionDefinition structs, a list of Evidence structs, and a PolicyContext, and returns the set of eligible candidates with auditable deny reasons for each rejected action.

### Context

This task depends on EXOCOMP-21 (Safety type system: Done, branch origin/EXOCOMP-21). All types referenced below — Proposal, ActionDefinition, Evidence, RiskRank, ValidatorResult, DataClassification — are defined in Exocomp.Node.Safety.* on that branch. Wire this work against the epic branch epic-EXOCOMP-3 which will receive the merged EXOCOMP-21 types.

Key source files from EXOCOMP-21:
- apps/exocomp_node/lib/exocomp/node/safety/action_definition.ex
- apps/exocomp_node/lib/exocomp/node/safety/evidence.ex
- apps/exocomp_node/lib/exocomp/node/safety/proposal.ex
- apps/exocomp_node/lib/exocomp/node/safety/risk_rank.ex
- apps/exocomp_node/lib/exocomp/node/safety/validator_result.ex

### Deliverable

Create Exocomp.Node.Safety.PolicyContext and Exocomp.Node.Safety.PolicyEngine.Filter (or inline filter functions in PolicyEngine).

### PolicyContext struct

```elixir
%PolicyContext{
  # Action IDs permitted by the node operator allow-list
  authorized_action_ids: MapSet.t(String.t()),
  # Map of {action_id, target_id} => last_executed_at :: DateTime.t()
  cooldown_state: %{{String.t(), String.t()} => DateTime.t()},
  # Map of {action_id, target_id} => consecutive_failure_count :: non_neg_integer()
  retry_counts: %{{String.t(), String.t()} => non_neg_integer()},
  # Current wall-clock time for evidence staleness checks (injectable for tests)
  now: DateTime.t()
}
```

### Eligibility filter checks (in order)

1. **Unauthorized** — proposal.action_id not in context.authorized_action_ids → deny, reason: "action not authorized"
2. **Inapplicable** — proposal.action_id not in the catalog (no matching ActionDefinition) → deny, reason: "action not in catalog"
3. **Unsafe data classification** — ActionDefinition.data_classification is :protected_user_data and action_class is :deletion → deny, reason: "user data deletion ineligible" (this should be caught by ActionDefinition.build/1 but also checked here)
4. **Missing evidence** — any collector id in ActionDefinition.required_evidence has no matching Evidence.collector in the evidence list → deny, reason: "missing required evidence: <collector>"
5. **Stale evidence** — any evidence where DateTime.diff(context.now, evidence.observed_at, :second) > ActionDefinition.max_evidence_age_secs → deny, reason: "stale evidence: <evidence_id>"
6. **Cooldown** — Map.get(context.cooldown_state, {action_id, target_id}) is set and DateTime.diff(context.now, last_executed_at, :second) < ActionDefinition.cooldown_secs → deny, reason: "action on cooldown"
7. **Retry exhausted** — Map.get(context.retry_counts, {action_id, target_id}, 0) >= ActionDefinition.max_retries and max_retries > 0 → deny, reason: "retry limit exhausted"

Each check that fails produces a rejection reason. Validator errors (e.g. nil/unexpected input) produce deny, not permissive fallback.

### Filter output type

```elixir
%PolicyEngine.FilterResult{
  eligible: [ActionDefinition.t()],
  rejected: [{ActionDefinition.t(), String.t()}]  # {definition, deny_reason}
}
```

### Tests

Write unit tests in apps/exocomp_node/test/ covering:
- Each filter type individually (authorized, catalog lookup, data class, evidence presence, evidence staleness, cooldown, retry exhaustion)
- Multiple candidates where some pass and some fail
- Empty catalog → deny
- Empty evidence list → deny if evidence required
- Evidence for wrong target_id → treated as missing
- Nil/invalid context fields → deny (fail closed)
- All candidates rejected → FilterResult with empty eligible list

### Quality gate

Run make test and make lint before handoff.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 00:50
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 00:50
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 00:50
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 00:50
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 00:51
---
Understanding: screening EXOCOMP-73 for duplication before implementation. I will search existing tasks and project plans for PolicyContext, eligibility filtering, and policy-engine work, inspect plausible candidates in full, then archive only if the same deliverable is already covered; otherwise I will hand off to implementation.
---
author: oompah
created: 2026-07-24 00:51
---
Discovery: duplicate screening found no duplicate. Repository/tracker-state search for PolicyContext, eligibility filtering, PolicyEngine, authorization/evidence/cooldown/retry deny reasons matched only EXOCOMP-73, its parent EXOCOMP-22, and sibling EXOCOMP-74. Full records confirm EXOCOMP-21 only defines prerequisite safety types; EXOCOMP-22 is the parent epic; EXOCOMP-74 is a distinct second-stage consumer that depends on this filter pipeline. plans/milestone-3-safety-validation.md specifies the broader engine but is not a separate implementation task.
---
author: oompah
created: 2026-07-24 00:51
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-73 is the unique first-stage policy-engine task and should proceed to implementation.

Evidence: Searched tracker state and docs/plans for PolicyContext, eligibility-filter, PolicyEngine, eligible candidates, authorization, required evidence, cooldown, and retry-exhaustion terms. Reviewed full task records for EXOCOMP-22, EXOCOMP-21, and EXOCOMP-74. EXOCOMP-21 supplies ActionDefinition/Evidence/Proposal/etc.; EXOCOMP-22 is the decomposed parent; EXOCOMP-74 explicitly depends on EXOCOMP-73 and owns only risk-ordered selection/evaluation. The closest design reference is plans/milestone-3-safety-validation.md.

Remaining work/risks: Implement PolicyContext and fail-closed ordered filtering with FilterResult plus focused tests for every rejection path, mixed/all-rejected candidates, target-specific evidence, and invalid context fields. Verify exact field shapes from the merged EXOCOMP-21 types before coding; run make test and make lint.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 00:52
---
Agent completed successfully in 77s (338279 tokens)
---
author: oompah
created: 2026-07-24 00:52
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 10
- Tokens: 336.2K in / 2.1K out [338.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 17s
- Log: EXOCOMP-73__20260724T005054Z.jsonl
---
author: oompah
created: 2026-07-24 00:52
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
<!-- COMMENTS:END -->
