---
id: EXOCOMP-61
type: task
status: In Progress
priority: null
title: Define versioned proposal schema module
parent: EXOCOMP-11
children: []
blocked_by:
- EXOCOMP-7
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T21:03:38.382843Z'
updated_at: '2026-07-23T21:14:23.165929Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 0d5b7da2-9c44-41bc-9460-a8acf7c1a393
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 23
  total_output_tokens: 6059
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 23
      output_tokens: 6059
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 23
    output_tokens: 6059
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:14:11.558964+00:00'
---
## Summary

### Goal

Define the versioned proposal schema that constrains all model output from the Qwen2.5 inference client.

### Context

This is a foundational module for EXOCOMP-11. The ProposalClient (sibling task) will use this schema to validate all output from llama-server before returning anything to the A2A service layer. The schema must be versioned, closed (no open-ended proposal IDs), and must exclude any executable shell commands.

### Implementation

In `apps/exocomp_node/lib/exocomp_node/proposal_schema.ex`:

- Define the current schema version as a compile-time constant (e.g., `@schema_version "1"`)
- Define the closed set of valid proposal identifiers as a module attribute (e.g., `:restart_service`, `:clear_disk_space`, `:rotate_logs`, `:increase_swap`)
- Define required fields for each proposal type: `proposal_id`, `schema_version`, `rationale`, `affected_resource`, `confidence`
- Implement `validate/1` that returns `{:ok, proposal}` or `{:error, reason}` for:
  - Unknown schema_version → `:unknown_schema_version`
  - Unknown proposal_id → `:unknown_proposal_id`
  - Missing required field → `{:missing_field, field_name}`
  - Extra fields that look like shell commands → `:forbidden_field`
- No shell execution interface. No arbitrary string pass-through.

### Testing

Unit tests in `apps/exocomp_node/test/exocomp_node/proposal_schema_test.exs`:
- Valid proposal for each known proposal_id passes validation
- Unknown proposal_id returns error
- Unknown schema_version returns error
- Missing required field returns error with field name
- Extra forbidden fields are rejected

### Acceptance Criteria
- [ ] Only known proposal IDs pass schema validation
- [ ] Unknown/missing schema version is rejected
- [ ] All required fields enforced
- [ ] Unit tests pass

### Dependencies
- EXOCOMP-7 (umbrella scaffold) must be done — use the `apps/exocomp_node` app created there

### Quality Gate
`make test` and `make lint` from the umbrella root must pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:11
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:11
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:13
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-61 is a unique task with no overlapping scope in the existing task graph.

**Scope searched:**
- All tasks in .oompah/tasks/ (open, in-progress, done, merged, archived, backlog, proposed)
- Searched for keywords: proposal_schema, ProposalSchema, proposal schema, versioned proposal, schema validate
- Reviewed plans/milestone-1-node-agent.md, plans/exocomp.md

**Closest candidates reviewed and ruled out:**
- EXOCOMP-52 ('Implement versioned benchmark configuration schema'): concerns Bench.Config in apps/bench (benchmark harness) — completely different domain, unrelated to proposal validation
- EXOCOMP-21 ('Define action, evidence, risk, and data-classification types'): M3-scope, covers a broader JSON schema set for policy types (action definitions, evidence, risk ranks, data classification) — a different milestone and significantly wider scope than EXOCOMP-61's M1 llama-server output validation
- EXOCOMP-63 ('Implement ProposalClient inference HTTP client'): CONSUMES ProposalSchema.validate/1 (depends on EXOCOMP-61) but does not define the schema — complementary, not duplicate
- EXOCOMP-27 ('Integrate remediation lifecycle with A2A tasks and audit'): uses structured proposals in M3 orchestration, does not define a proposal schema module
- EXOCOMP-31 ('Implement automatic recovery of an already-failed service'): M4-level recovery flow using proposals, does not implement a schema module

**Evidence of uniqueness:**
- The EXOCOMP-11 epic planner explicitly created EXOCOMP-61 as a distinct child for the foundational ProposalSchema module
- EXOCOMP-61 has a unique dependency position: blocked by EXOCOMP-7 (umbrella scaffold) and blocks EXOCOMP-63 (ProposalClient)
- No existing task in any state folder contains 'proposal_schema' or 'ProposalSchema' in its content (grep confirmed)
- The closed-list proposal IDs (:restart_service, :clear_disk_space, :rotate_logs, :increase_swap) and M1-scoped validate/1 function are not defined anywhere in the codebase yet

**Remaining work:**
1. Create apps/exocomp_node/lib/exocomp_node/proposal_schema.ex with: @schema_version, @valid_proposal_ids, validate/1 with all required error variants
2. Create apps/exocomp_node/test/exocomp_node/proposal_schema_test.exs with full unit test coverage
3. Run make test and make lint from umbrella root

**Relevant files:**
- plans/milestone-1-node-agent.md (Inference Integration + Failure and Security Behavior sections)
- apps/exocomp_node/ (umbrella app scaffold from EXOCOMP-7, already merged to main)

**Recommended next focus:** feature — implement ExocompNode.ProposalSchema in Elixir
---
author: oompah
created: 2026-07-23 21:14
---
Agent completed successfully in 154s (6082 tokens)
---
author: oompah
created: 2026-07-23 21:14
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 45, Tool calls: 33
- Tokens: 23 in / 6.1K out [6.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 34s
- Log: EXOCOMP-61__20260723T211142Z.jsonl
---
author: oompah
created: 2026-07-23 21:14
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:14
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:14
---
Focus: Maintenance Engineer
---
<!-- COMMENTS:END -->
