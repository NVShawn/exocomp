---
id: EXOCOMP-63
type: task
status: Open
priority: null
title: Implement ProposalClient inference HTTP client
parent: EXOCOMP-11
children: []
blocked_by:
- EXOCOMP-61
- EXOCOMP-62
labels: []
assignee: null
created_at: '2026-07-23T21:04:13.412982Z'
updated_at: '2026-07-23T21:10:32.277059Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

### Goal

Implement `Exocomp.Node.ProposalClient`, an HTTP client that sends bounded diagnostic context to llama-server and validates the structured response against the versioned proposal schema.

### Context

This is the inference request layer. It calls `LlamaServer.base_url/0` to locate the running server, sends the Qwen2.5 completion request with a fixed system prompt, enforces a timeout, and validates the response using the `ProposalSchema` module. Invalid, timed-out, or unavailable inference MUST NEVER yield an executable action.

Reference: plans/milestone-1-node-agent.md, 'Inference Integration' and 'Failure and Security Behavior' sections.

### Implementation

In `apps/exocomp_node/lib/exocomp_node/proposal_client.ex`:

- `propose/1` accepting bounded diagnostic context map (size-limited, max configurable)
- Check `LlamaServer.base_url/0`; return `{:error, :inference_unavailable}` if not ready
- Build the llama-server `/v1/chat/completions` request body with:
  - Fixed system prompt (hardcoded, not user-configurable): instructs Qwen2.5 to output a single JSON object matching the proposal schema
  - User message: serialized diagnostic context (truncated to configured max tokens)
  - `max_tokens`: bounded (configurable, default 512)
  - `temperature`: 0 (deterministic)
- POST to `<base_url>/v1/chat/completions` with configurable HTTP timeout (default 15s)
- On timeout → return `{:error, :inference_timeout}`
- On HTTP error → return `{:error, {:http_error, status}}`
- Parse response JSON; on invalid JSON → return `{:error, :invalid_json}`
- Extract content string; parse as JSON object; validate with `ProposalSchema.validate/1`
- On schema error → return `{:error, {:schema_error, reason}}`
- On success → return `{:ok, validated_proposal}`
- Audit logging: emit structured log events for every call attempt; redact raw model output (replace with `[REDACTED]` in logs, keep only the validated proposal or error reason)
- Model binary checksum validation: call a configurable checksum_fn/0 (default: stub returning `:ok`); real implementation supplied by EXOCOMP-9 config layer

### Testing (unit, with stubs)

A basic unit smoke test: with `LlamaServer` mocked as unavailable, `propose/1` returns `{:error, :inference_unavailable}` without crashing.

Full scenario tests are in the sibling test task.

### Acceptance Criteria
- [ ] Invalid/timed-out/unavailable inference never yields an executable action
- [ ] Raw model output is redacted in audit logs
- [ ] Only schema-valid proposals are returned
- [ ] Diagnostic context is size-bounded before sending

### Dependencies
- EXOCOMP-61 (proposal schema module)
- EXOCOMP-62 (LlamaServer supervisor — for `base_url/0` API)

### Quality Gate
`make test` and `make lint` from the umbrella root must pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

