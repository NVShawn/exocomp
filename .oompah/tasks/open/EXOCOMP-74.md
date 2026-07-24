---
id: EXOCOMP-74
type: task
status: Open
priority: null
title: Implement PolicyEngine risk-ordered selection and comprehensive policy tests
parent: EXOCOMP-22
children: []
blocked_by:
- EXOCOMP-73
labels: []
assignee: null
created_at: '2026-07-23T22:51:10.216409Z'
updated_at: '2026-07-24T00:53:18.085576Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Implement the second stage of the EXOCOMP-22 policy engine: deterministic risk-ordered candidate selection that takes the FilterResult from EXOCOMP-73 and produces an auditable ValidatorResult. Also add the comprehensive table/property tests specified in the issue.

### Context

Depends on EXOCOMP-73 (PolicyContext and eligibility-filter pipeline). Also depends on EXOCOMP-21 types (origin/EXOCOMP-21). The full policy engine is Exocomp.Node.Safety.PolicyEngine with a single public entry point.

### Deliverable

### PolicyEngine.evaluate/3

```elixir
@spec evaluate(
  Proposal.t(),
  [ActionDefinition.t()],
  Evidence.t() | [Evidence.t()],
  PolicyContext.t()
) :: ValidatorResult.t()
```

1. Call the filter pipeline (from EXOCOMP-73) to get eligible candidates and rejection reasons.
2. If eligible is empty: return ValidatorResult.deny/1 with reason summarising all rejection reasons (auditable ordering evidence). Include the sorted rejection list in the result.
3. If eligible is non-empty: sort by RiskRank using RiskRank.compare/2 (data_loss → work_loss → disruption → scope).
   - Tiebreaker: alphabetical action_id (ensures determinism when risk ranks are equal).
   - Select the first candidate after sorting (lowest risk).
4. Map the selected ActionDefinition to a decision:
   - requires_approval: false → ValidatorResult.allow/3
   - requires_approval: true → ValidatorResult.approval_required/3
5. Include in ValidatorResult:
   - action_id: the selected action's action_id
   - reason: human-readable string citing the selected candidate and why others were not chosen
   - evidence_refs: IDs of all evidence used (evidence.evidence_id for each evidence struct that satisfied a required_evidence collector for this action)

### Ordering evidence in the result

The reason field should be auditable: include the full ordered list of candidates with their risk ranks, which filters rejected the others. This allows post-hoc audit of why a higher-impact action was not chosen.

### Fail-closed invariants

- Any unexpected/nil inputs to evaluate/4 must return ValidatorResult.deny/1, never allow or approval_required.
- An exception inside the filter or selection logic must be caught and mapped to ValidatorResult.deny/1 with reason 'internal policy error'.
- These are safety invariants — silence or crash must never be treated as allow.

### Comprehensive tests

Write focused tests in apps/exocomp_node/test/exocomp/node/safety/policy_engine_test.exs covering:

### Table tests (deterministic scenarios)
1. **Single eligible candidate (requires_approval: false)** → :allow
2. **Single eligible candidate (requires_approval: true)** → :approval_required
3. **No candidates (empty catalog)** → :deny
4. **All candidates filtered** → :deny with all rejection reasons in result
5. **Stable ordering** — three candidates with different risk ranks → lowest-risk action_id selected, repeatable
6. **Tie on risk rank** — two candidates with identical RiskRank, different action_ids → alphabetically-first action_id selected deterministically
7. **Stale evidence** — candidate filtered by staleness → remaining safe candidate selected
8. **Unavailable policy** — nil catalog → :deny (fail closed)
9. **Safer remaining candidate** — high-risk action present alongside lower-risk eligible action → lower-risk always wins (escalation prevention)
10. **Multiple evidence types** — action requires two collectors; one missing → filtered; action with both present → eligible

### Property test (determinism)
11. **Repeated evaluation** — same inputs always produce the same ValidatorResult (action_id, decision, reason). Use ExUnitProperties or a simple repeated-call assertion.

### Validator error test (fail-closed)
12. **Validator error propagation** — if filter raises or returns unexpected term, evaluate/4 returns :deny

### Quality gate

Run make test and make lint. All tests in the policy engine test file must pass. No regressions in existing tests (EXOCOMP-21 safety types, EXOCOMP-25 executor).

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

