---
id: EXOCOMP-74
type: task
status: In Progress
priority: null
title: Implement PolicyEngine risk-ordered selection and comprehensive policy tests
parent: EXOCOMP-22
children: []
blocked_by:
- EXOCOMP-73
labels:
- focus-complete:duplicate_detector
- focus-complete:test
assignee: null
created_at: '2026-07-23T22:51:10.216409Z'
updated_at: '2026-07-24T01:21:46.375317Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: edd3f14a-b8d9-4403-9ca5-9c88d830f837
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 26
  total_output_tokens: 7149
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 26
      output_tokens: 7149
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 26
    output_tokens: 7149
    cost_usd: 0.0
    recorded_at: '2026-07-24T01:13:12.746477+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 01:10
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 01:10
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 01:13
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed. EXOCOMP-74 is a unique second-stage policy engine implementation task with no coverage overlap in the existing task graph.

Evidence reviewed:
- EXOCOMP-73 (Done): First-stage filter pipeline (PolicyContext + eligibility checks). Distinct scope — returns FilterResult; does NOT implement evaluate/4 or risk-ordered selection.
- EXOCOMP-22 (Open): Parent epic that decomposed into exactly EXOCOMP-73 and EXOCOMP-74 — not an implementation task.
- EXOCOMP-21 (Done): Safety types only (ActionDefinition, Evidence, Proposal, RiskRank, ValidatorResult) — prerequisite types, no policy logic.
- EXOCOMP-25 (Done): Unprivileged systemd executor and sudoers policy — executor layer, not policy selection.
- EXOCOMP-23/24 (Open): Approval issuance and replay prevention — distinct approval/crypto scope.
- No other task defines PolicyEngine.evaluate/4 or risk-ordered candidate selection anywhere in the task graph or codebase.

Key findings for the feature agent:
1. EXOCOMP-73 code lives on local branch 'EXOCOMP-73' and 'remotes/origin/EXOCOMP-73'. The current working branch (epic-EXOCOMP-22) does NOT yet include the EXOCOMP-73 code — the feature agent must merge/cherry-pick EXOCOMP-73 before extending PolicyEngine.
2. PolicyEngine.evaluate/4 does not yet exist — must be added to apps/exocomp_node/lib/exocomp/node/safety/policy_engine.ex.
3. The test file apps/exocomp_node/test/exocomp/node/safety/policy_engine_test.exs does not exist — must be created with all 12 specified test scenarios.
4. Existing filter tests are in policy_engine_filter_test.exs (separate file, 828 lines) — don't disturb these.
5. Two pre-existing LlamaServer process tests fail in the test suite (unrelated to this task).
6. Run 'make test' and 'make lint' before closing.

Remaining work/risks:
- Extend PolicyEngine with evaluate/4: call filter/4, sort eligible by RiskRank.compare/2 with alphabetical tiebreaker, map to ValidatorResult, include auditable reason with full ordered candidate list.
- Fail-closed on nil/unexpected inputs and on any exception during filter/selection.
- Write 12 comprehensive tests (table tests 1-10, property test 11, fail-closed test 12).
- evidence_refs field: IDs of Evidence structs whose collector satisfied a required_evidence entry for the selected action.
- Merge EXOCOMP-73 code first (or ensure working branch has those files).

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 01:13
---
Agent completed successfully in 164s (7175 tokens)
---
author: oompah
created: 2026-07-24 01:13
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 56, Tool calls: 39
- Tokens: 26 in / 7.1K out [7.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 44s
- Log: EXOCOMP-74__20260724T011032Z.jsonl
---
author: oompah
created: 2026-07-24 01:13
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 01:13
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 01:13
---
Focus: Test Engineer
---
author: oompah
created: 2026-07-24 01:13
---
Understanding: Test focus will inspect the existing EXOCOMP-73 filter and EXOCOMP-21 result contracts, then add focused policy_engine_test.exs coverage for all 12 required selection, audit, evidence, determinism, and fail-closed scenarios. I will verify the new tests expose missing/broken behavior, run the relevant Makefile test target, and hand off production implementation to feature focus if needed.
---
author: oompah
created: 2026-07-24 01:14
---
Discovery: Created the missing EXOCOMP-74 branch from prerequisite EXOCOMP-73 because the dispatched worktree was actually on epic-EXOCOMP-22/origin-main. EXOCOMP-73's filter/4 evaluates only proposal.action_id, but EXOCOMP-74 must rank catalog alternatives; tests will target evaluate/4 behavior and require per-candidate eligibility, deterministic RiskRank/action_id ordering, complete eligible/rejected audit text, selected evidence refs, and exception fail-closed handling without prescribing internal implementation.
---
author: oompah
created: 2026-07-24 01:17
---
Implementation (test focus): Added apps/exocomp_node/test/exocomp/node/safety/policy_engine_test.exs with independent fixed-time fixtures and coverage for allow/approval/deny, complete rejection audit, RiskRank ordering, alphabetical ties, stale and multi-collector evidence, evidence_refs, nil/unexpected inputs, escalation prevention, repeated-call determinism, and caught filter exceptions. Added a single-Evidence API regression case beyond the required table.
---
author: oompah
created: 2026-07-24 01:17
---
Verification (test focus): git diff --cached --check passes. The new suite is intentionally red against EXOCOMP-73 because PolicyEngine.evaluate/4 does not exist yet, demonstrating it covers the missing behavior. make fmt/test could not execute in this managed environment: the Docker-compatible Podman wrapper fails before container startup with a read-only /run/user/1000/libpod runtime lock/config error; no local mix executable is installed. Feature agent must run make fmt, focused tests, make test, and make lint after implementation.
---
author: oompah
created: 2026-07-24 01:18
---
Focus handoff: test

Outcome: Test focus complete. Added and pushed commit e742b5b on origin/EXOCOMP-74 with comprehensive PolicyEngine.evaluate/4 contract coverage (14 tests covering all 12 requested scenarios plus single-Evidence normalization and broader invalid-input fail-closed cases).

Relevant files/evidence: apps/exocomp_node/test/exocomp/node/safety/policy_engine_test.exs; branch was created from EXOCOMP-73 commit 66b5f15 because dispatch initially checked out epic-EXOCOMP-22. git diff --cached --check passed before commit; final git status is clean and up to date. EXOCOMP-73 filter/4 only evaluates proposal.action_id, so evaluate/4 must evaluate catalog alternatives per candidate before sorting. Audit tests require candidate IDs/ranks in ordered reason text and rejection reasons for filtered candidates.

Remaining work/risks: Implement evaluate/4 and likely per-candidate filtering orchestration; scope staleness checks to evidence collectors required by each candidate so an unrelated stale record does not reject the safe candidate; normalize Evidence.t() to a list; catch exceptions as exact reason 'internal policy error'. Container-backed make fmt/test/lint cannot run in this sandbox because Podman cannot write /run/user/1000/libpod and no host mix exists, so rerun all gates in a functioning environment.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 01:18
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 0, Tool calls: 22
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 4m 55s
- Log: EXOCOMP-74__20260724T011326Z.jsonl
---
author: oompah
created: 2026-07-24 01:21
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 01:21
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-07-24 01:21
---
Understanding (DevOps focus): Previous test focus added the test file but the feature implementation of PolicyEngine.evaluate/4 is still missing. As DevOps focus, I will: (1) explore current branch state, (2) implement the missing evaluate/4 function to make tests pass, (3) run make test and make lint quality gates, (4) commit and push. The key infrastructure concern is ensuring the build/test pipeline passes cleanly end-to-end.
---
<!-- COMMENTS:END -->
