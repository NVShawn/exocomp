---
id: EXOCOMP-63
type: task
status: In Progress
priority: null
title: Implement ProposalClient inference HTTP client
parent: EXOCOMP-11
children: []
blocked_by:
- EXOCOMP-61
- EXOCOMP-62
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T21:04:13.412982Z'
updated_at: '2026-07-23T21:49:08.468228Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: e7faea17-a44c-4b07-b40f-0fe8a9e2f324
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 23
  total_output_tokens: 4827
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 23
      output_tokens: 4827
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 23
    output_tokens: 4827
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:39:49.562050+00:00'
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

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:37
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:37
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:39
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate found. EXOCOMP-63 is a unique, original task.

**Evidence reviewed:**
- Searched all task files under `.oompah/tasks` (done, in-progress, open, merged, archived) for: `ProposalClient`, `proposal_client`, `inference.*http`, `llama.*client`, `chat.*completions`
- Found only 5 tasks with overlap: EXOCOMP-61 (done, ProposalSchema module — dependency), EXOCOMP-62 (done, LlamaServer supervisor — dependency), EXOCOMP-63 (this task), EXOCOMP-64 (open, ExUnit tests — blocked by EXOCOMP-63), EXOCOMP-11 (parent feature)
- None of these describe the same implementation work as EXOCOMP-63; they are properly decomposed sibling/parent/child tasks
- No archived tasks cover ProposalClient implementation
- No `proposal_client.ex` file exists in the codebase — implementation has not been started

**Key files for implementation agent:**
- Target: `apps/exocomp_node/lib/exocomp_node/proposal_client.ex` (does not exist yet)
- Dependencies already implemented: `ProposalSchema` (EXOCOMP-61) and `LlamaServer` (EXOCOMP-62) are both Done
- Plan reference: `plans/milestone-1-node-agent.md` sections 'Inference Integration' and 'Failure and Security Behavior'

**Remaining work:** Full ProposalClient implementation as specified in the task description, plus unit smoke test for unavailable LlamaServer case.

**Recommended next focus:** `feature` (Elixir/OTP implementation)
---
author: oompah
created: 2026-07-23 21:39
---
Agent completed successfully in 131s (4850 tokens)
---
author: oompah
created: 2026-07-23 21:39
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 40, Tool calls: 30
- Tokens: 23 in / 4.8K out [4.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 11s
- Log: EXOCOMP-63__20260723T213741Z.jsonl
---
author: oompah
created: 2026-07-23 21:39
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:39
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:39
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-23 21:43
---
Focus handoff: security (pre-implementation audit)

**Understanding:** I am the Security Auditor for EXOCOMP-63. No ProposalClient implementation exists yet — the feature agent was not run. I will perform a security-first implementation, embedding all security controls as first-class design elements rather than afterthoughts.

**Security threat model for ProposalClient:**
1. Log injection / information disclosure: Raw LLM output must NEVER appear in logs (redact to [REDACTED])
2. SSRF: base_url from LlamaServer is already loopback-only (enforced in LlamaServer.init/1 with a warning and override)
3. Atom exhaustion: JSON parsing of model output must use string keys, not atom keys, to avoid BEAM atom table exhaustion
4. Input size bounding: Diagnostic context serialization must be truncated before sending
5. Arbitrary execution: Model output must pass ProposalSchema.validate/1 gate — no bypass
6. Timeout: Must enforce HTTP timeout; no blocking forever on a slow model
7. Schema pinning: System prompt hardcoded (not caller-configurable)
8. Checksum validation: Model binary verified before use (configurable fn)
9. Oversized HTTP responses: Must cap response body size
10. Malformed HTTP: Must handle gracefully without crashing

**Plan:** Create EXOCOMP-63 branch from EXOCOMP-62, bring in ProposalSchema from EXOCOMP-61, implement ProposalClient with all security controls, add unit tests, run quality gates.
---
author: oompah
created: 2026-07-23 21:45
---
Discovery: Security findings from specification and dependency review

**ProposalSchema (EXOCOMP-61) — SECURE:**
- Uses String.to_existing_atom (prevents atom table exhaustion)
- Closed valid_proposal_ids set (prevents unknown proposal execution)
- schema_version pinning enforced
- Forbidden field detection (prevents shell-command injection via extra keys)
- No execution interface

**LlamaServer (EXOCOMP-62) — SECURE with one note:**
- Enforces loopback-only (127.0.0.1) — ignores non-loopback config with warning
- Health checks use :gen_tcp directly (no HTTP library needed)
- LlamaServer returns {:error, :not_ready} when not available

**Security requirements for ProposalClient implementation:**
1. Checksum gate must be called FIRST (before any network I/O)
2. LlamaServer availability check SECOND
3. Diagnostic context MUST be serialized + byte-truncated (not character-truncated for safety with multi-byte chars)
4. HTTP request MUST use :inets/:httpc (zero external deps, loopback already enforced)
5. Raw model response must NEVER appear in Logger calls
6. Schema validation must be the LAST gate before return
7. Atom table safety: JSON keys from model output must be string keys (not atoms!) — JSON.decode/1 defaults to string keys in Elixir 1.18+ ✓
8. All error paths must return structured {:error, reason} — no exceptions/crashes

**Key findings:**
- Branch created from EXOCOMP-62, ProposalSchema cherry-picked from EXOCOMP-61
- Using built-in :httpc (inets) + built-in JSON module (Elixir 1.18+) — no external deps
- Will add :inets to extra_applications in mix.exs
---
author: oompah
created: 2026-07-23 21:48
---
Implementation: ProposalClient with security-first design

**Files changed:**
- `apps/exocomp_node/lib/exocomp/node/proposal_client.ex` (new)
- `apps/exocomp_node/test/exocomp/node/proposal_client_test.exs` (new)
- `apps/exocomp_node/mix.exs` (added :inets to extra_applications)

**Security pipeline (in execution order):**
1. Checksum gate: configurable checksum_fn/0, defaults to stub :ok
2. Availability gate: LlamaServer.base_url/0 -> :inference_unavailable if not ready
3. Bounded context: byte-truncated to max_context_bytes (default 8192) before send
4. Fixed system prompt: hardcoded, never caller-configurable
5. HTTP timeout: configurable inference_timeout_ms (default 15000ms) via :httpc
6. Response extraction: choices[0].message.content parsed defensively
7. Atom-safe decode: JSON.decode uses string keys (prevents atom table exhaustion)
8. Schema gate: ProposalSchema.validate/1 is the last gate before return
9. Audit logging: every call logged; raw model output ALWAYS [REDACTED]

**Zero new external dependencies:** uses built-in :inets/:httpc + Elixir 1.18+ JSON module.

**Branch:** EXOCOMP-63, cherry-picked ProposalSchema from EXOCOMP-61 on top of EXOCOMP-62.
---
author: oompah
created: 2026-07-23 21:48
---
Verification: make test and make lint both pass

- 37/37 tests pass (includes 10 new ProposalClient unit tests)
- make lint passes with 0 warnings-as-errors
- make fmt-check passes (formatter applied)
- Releases build: exocomp_node and exocomp_coordinator both assemble and smoke-start

All acceptance criteria met:
✓ Invalid/timed-out/unavailable inference never yields an executable action
✓ Raw model output is [REDACTED] in all audit log events
✓ Only schema-valid proposals returned (ProposalSchema.validate/1 gate)
✓ Diagnostic context is byte-bounded before transmission
---
author: oompah
created: 2026-07-23 21:49
---
Completion: ProposalClient implemented and pushed

Delivered Exocomp.Node.ProposalClient on branch EXOCOMP-63 (cherry-picks ProposalSchema from EXOCOMP-61 onto EXOCOMP-62). All security requirements from milestone-1-node-agent.md 'Inference Integration' and 'Failure and Security Behavior' sections are enforced.

No remaining security risks found. EXOCOMP-64 (full scenario ExUnit tests) can now unblock.
---
<!-- COMMENTS:END -->
