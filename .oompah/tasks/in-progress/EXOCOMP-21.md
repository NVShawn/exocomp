---
id: EXOCOMP-21
type: feature
status: In Progress
priority: 1
title: Define action, evidence, risk, and data-classification types
parent: EXOCOMP-3
children: []
blocked_by:
- EXOCOMP-8
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:10:07.361533Z'
updated_at: '2026-07-23T22:12:30.988113Z'
work_branch: epic-EXOCOMP-3
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: d93bd5ab-7fd0-47f8-a081-379a97aee8ab
oompah.work_branch: epic-EXOCOMP-3
oompah.task_costs:
  total_input_tokens: 357400
  total_output_tokens: 9332
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 357400
      output_tokens: 9332
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 30
    output_tokens: 6927
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:54:15.837606+00:00'
  - profile: default
    model: unknown
    input_tokens: 357370
    output_tokens: 2405
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:55:44.025999+00:00'
---
## Summary

Plan: [Milestone 3 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-3-safety-validation.md)

Goal
Define action, evidence, risk, and data-classification types.

Implementation
Implement versioned types and JSON schemas for action definitions, proposals, evidence, validator results, risk ranks, reversibility, data classification, execution, and verification; reject unknown fields/versions where security-relevant; default unknown data to protected user data.

Testing
Add table/property tests for valid schemas, malformed values, unknown versions, missing evidence, risk ordering primitives, and every data-classification default.

Acceptance Criteria
- [ ] All security-relevant inputs are bounded and schema-versioned.
- [ ] Unknown data is always classified as protected user data.
- [ ] User-data deletion is unrepresentable as an eligible action.
- [ ] Focused type/schema tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:51
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:51
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:51
---
Understanding: Investigating whether EXOCOMP-21 ('Define action, evidence, risk, and data-classification types') is a duplicate of an existing task. Will search for related tasks covering type definitions for actions, evidence, risk ranks, reversibility, data classification, and schema versioning before any implementation proceeds.
---
author: oompah
created: 2026-07-23 21:54
---
Duplicate screening found no duplicate.

Closest reviewed task: EXOCOMP-61 (Done, parent EXOCOMP-11) — 'Define versioned proposal schema module'. This adds Exocomp.Node.ProposalSchema which validates LLM proposal output (closed proposal_id set, required fields, schema version, forbidden shell-command indicators). It is a Milestone 1/inference-client task that validates *what the LLM proposes*. EXOCOMP-21 is a Milestone 3/safety task that defines the *action catalog types, evidence structure, risk ranks, reversibility, and data classification* consumed by the policy engine. Scope and domain are distinct.

All other candidate tasks reviewed: EXOCOMP-3 (M3 parent epic), EXOCOMP-8 (A2A protocol types, Done), EXOCOMP-22–28 (M3 siblings that *depend on* EXOCOMP-21). None define action/evidence/risk/data-classification types.

Evidence: searched git log, plans/milestone-3-safety-validation.md, all .oompah/tasks/ entries in origin/oompah/state/proj-c260b117, and commit diffs for EXOCOMP-61.

Conclusion: EXOCOMP-21 is a unique task. Handing off to feature implementation focus.
---
author: oompah
created: 2026-07-23 21:54
---
Agent completed successfully in 165s (6957 tokens)
---
author: oompah
created: 2026-07-23 21:54
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 62, Tool calls: 49
- Tokens: 30 in / 6.9K out [7.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 45s
- Log: EXOCOMP-21__20260723T215134Z.jsonl
---
author: oompah
created: 2026-07-23 21:54
---
Focus handoff required before leaving `duplicate_detector`. Add a comment headed `Focus handoff: duplicate_detector` with outcome, evidence, remaining work, and next focus.
---
author: oompah
created: 2026-07-23 21:54
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:54
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:55
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening confirmed no duplicate. EXOCOMP-21 is a unique Milestone 3 safety-types task.

Evidence: Reviewed the full tracker records for EXOCOMP-21, EXOCOMP-61, EXOCOMP-8, parent epic EXOCOMP-3, and siblings EXOCOMP-22 through EXOCOMP-28 from origin/oompah/state/proj-c260b117. Also reviewed plans/milestone-3-safety-validation.md. EXOCOMP-61 only validates Milestone 1 LLM proposal output; EXOCOMP-8 defines A2A protocol types; EXOCOMP-22 through EXOCOMP-28 consume the action/evidence/risk/data-classification contracts and do not define them.

Remaining work and risks: Implement the versioned closed schemas and types, fail-closed unknown-field/version behavior, protected-user-data default, deletion-ineligibility invariant, and focused table/property tests. Preserve compatibility boundaries with Exocomp.Node.ProposalSchema while keeping the Milestone 3 policy domain distinct.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-23 21:55
---
Agent completed successfully in 78s (359775 tokens)
---
author: oompah
created: 2026-07-23 21:55
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 7
- Tokens: 357.4K in / 2.4K out [359.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 18s
- Log: EXOCOMP-21__20260723T215427Z.jsonl
---
author: oompah
created: 2026-07-23 21:55
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:55
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:55
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-23 21:58
---
Understanding (Security Auditor): EXOCOMP-21 requires defining the type-level security contracts for the M3 policy engine — action definitions, proposals, evidence, validator results, risk ranks, reversibility, and data classification. No implementation exists yet on this branch; previous agents confirmed no duplicate and identified the scope.

Security invariants I must enforce at the type level:
1. Unknown data classification defaults to :protected_user_data (fail-closed)
2. Deletion-class actions targeting :protected_user_data are structurally ineligible — enforced at ActionDefinition construction, not runtime policy
3. All security-relevant parse paths reject unknown schema versions and unknown fields
4. Evidence includes integrity hash and observed_at; validator rejects stale or mismatched evidence
5. Proposal parser rejects unknown action IDs and unknown fields (LLM output is untrusted input)
6. Risk ranks support deterministic lexicographic ordering for policy selection

Attack surface: Proposal parsing (LLM = untrusted), Evidence validation (staleness/forgery), schema version downgrade/confusion, data-classification bypass, atom injection via string-to-atom conversion (using explicit pattern matching instead).

Plan: implement Exocomp.Node.Safety.{DataClassification, RiskRank, Reversibility, ActionDefinition, Evidence, Proposal, ValidatorResult} in exocomp_node with table-driven tests for every invariant.
---
author: oompah
created: 2026-07-23 22:11
---
Discovery: No prior implementation existed on this branch. Explored the M3 safety design in plans/milestone-3-safety-validation.md and found the following security attack surface requiring type-level invariants:
1. Proposals come from the LLM (untrusted) — strict parsing with unknown-field rejection
2. Evidence requires integrity hash, timestamp, and schema version — stale/tampered evidence rejected
3. Data classification must default to :protected_user_data for any unknown value
4. ActionDefinition must structurally prevent deletion-class actions from targeting :protected_user_data
5. Risk rank parsing must reject unknown levels (no atom injection via String.to_atom)
6. ValidatorResult must default to :deny — fail-closed
---
author: oompah
created: 2026-07-23 22:11
---
Implementation: Created Exocomp.Node.Safety type system in apps/exocomp_node/lib/exocomp/node/safety/:

- DataClassification: classify/1 fail-closed (unknown → :protected_user_data); deletion_eligible?/1 blocks :protected_user_data
- RiskRank: parse/1 with explicit string pattern matching (no String.to_atom); compare/2 and less_than?/2 for policy ordering
- Reversibility: parse/1 with no default — explicit required value; unknown strings rejected
- Evidence: full parse/1 with schema version check, unknown-field rejection, required-field validation, ISO 8601 datetime parsing, flat string→string values validation, SHA-256 hex integrity hash validation (64 lowercase hex chars)
- Proposal: parse/1 with untrusted-input hardening: action_id restricted to [A-Za-z0-9._-]{1,128}, unknown fields rejected, flat parameters map required
- ActionDefinition: build/1 with deletion-ineligibility invariant (deletion+:protected_user_data → error at construction), forbidden action_id pattern check (shell/exec/cmd/rm/wildcard), all numeric fields validated
- ValidatorResult: deny/allow/approval_required constructors with schema version; parse/1 with unknown-field rejection; default struct is :deny

Tests: 180 tests (7 test files) covering valid schemas, malformed values, unknown schema versions, missing fields, risk ordering, fail-closed data classification defaults, and deletion-ineligibility variants.
---
author: oompah
created: 2026-07-23 22:12
---
Verification: All quality gates pass.

make lint: PASS (format check + compile --warnings-as-errors, 0 warnings)
MIX_ENV=test mix test: 180 tests, 0 failures

Test breakdown by module:
- DataClassification: 18 tests — all 13 unknown-input fail-closed cases including nil, empty string, uppercase strings, integers, booleans, maps, lists; round-trip classify→deletion_eligible?
- RiskRank: 30 tests — all 5 valid level strings for all 4 fields; missing defaults; 6 unknown level rejections; compare ordering: tiebreak sequences, full none<minimal<moderate<high<critical order proof (10 ordered pairs)
- Reversibility: 15 tests — known strings/atoms; 11 unknown scalar rejections; map/list rejections
- Evidence: 31 tests — valid map; schema version checks; unknown-field rejection; 7 required-field validations; datetime valid/invalid; values map validation; integrity hash (too short/long/uppercase/non-hex/non-string)
- Proposal: 25 tests — valid map; schema version; unknown-field injection; action_id allowlist (5 valid, 7 invalid patterns); parameters validation; evidence_refs validation
- ActionDefinition: 33 tests — deletion-ineligibility invariant (5 cases including nil/unknown classification); forbidden patterns (6); schema version; unknown action_class; numeric field validation; risk_rank from map
- ValidatorResult: 28 tests — all 3 constructors; predicate helpers; fail-closed default; parse/1 all decisions; schema version; unknown fields; malformed decision
---
<!-- COMMENTS:END -->
