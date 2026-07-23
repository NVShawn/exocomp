---
id: EXOCOMP-61
type: task
status: Backlog
priority: null
title: Define versioned proposal schema module
parent: EXOCOMP-11
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T21:03:38.382843Z'
updated_at: '2026-07-23T21:04:49.450890Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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

