---
id: EXOCOMP-73
type: task
status: Backlog
priority: null
title: Implement PolicyContext and eligibility-filter pipeline
parent: EXOCOMP-22
children: []
blocked_by:
- EXOCOMP-21
labels: []
assignee: null
created_at: '2026-07-23T22:50:44.926199Z'
updated_at: '2026-07-23T22:51:22.015480Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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

