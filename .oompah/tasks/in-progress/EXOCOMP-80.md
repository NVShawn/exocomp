---
id: EXOCOMP-80
type: task
status: In Progress
priority: null
title: 'Skill handler implementations: system.diagnose, service.diagnose, remediation.propose'
parent: EXOCOMP-12
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
- focus-complete:epic_planner
assignee: null
created_at: '2026-07-23T23:04:55.080769Z'
updated_at: '2026-07-24T01:52:37.946271Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 71e5e80a-2e4e-4740-9b16-887cbfdaf841
oompah.work_branch: epic-EXOCOMP-1
oompah.task_costs:
  total_input_tokens: 346021
  total_output_tokens: 6752
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 346021
      output_tokens: 6752
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 14
    output_tokens: 4639
    cost_usd: 0.0
    recorded_at: '2026-07-24T01:35:04.195223+00:00'
  - profile: standard
    model: unknown
    input_tokens: 346007
    output_tokens: 2113
    cost_usd: 0.0
    recorded_at: '2026-07-24T01:36:41.078145+00:00'
---
## Summary

### Goal
Implement the three diagnostic skill handler modules that are invoked by the task dispatch layer. Each skill collects data via the appropriate collector or inference client and returns a versioned A2A DataPart artifact.

### Prerequisites
This task requires the prerequisite branches to be merged (done by EXOCOMP-78):
- Collectors from EXOCOMP-10/EXOCOMP-60: Exocomp.Node.Collectors.{CPU, Memory, Disk, Uptime, Systemd}
- Inference client from epic-EXOCOMP-11/EXOCOMP-63: Exocomp.Node.{ProposalClient, ProposalSchema, LlamaServer}
- A2A types from epic-EXOCOMP-8: Exocomp.A2A.{Artifact, DataPart}

### Relevant files
- apps/exocomp_node/lib/exocomp/node/collectors/ — CPU, Disk, Memory, Uptime, Systemd collectors
- apps/exocomp_node/lib/exocomp/node/proposal_client.ex — calls llama-server
- apps/exocomp_core/lib/exocomp/a2a/artifact.ex — Artifact struct
- apps/exocomp_core/lib/exocomp/a2a/data_part.ex — DataPart struct

### Implementation

### Behavior: Exocomp.Node.Skills.Behaviour
Define a simple callback:
```elixir
@callback execute(params :: map(), context :: map()) ::
  {:ok, Exocomp.A2A.Artifact.t()} | {:error, term()}
```

### Module: Exocomp.Node.Skills.SystemDiagnose
Calls: CPU.collect/0, Memory.collect/0, Disk.collect/0, Uptime.collect/0 (all four, concurrently via Task.async)
Returns: A2A Artifact with a DataPart whose mimeType is "application/json" and data is a map:
```json
{"schema_version": "1", "skill": "exocomp.system.diagnose", "observations": {"cpu": {...}, "memory": {...}, "disk": {...}, "uptime": {...}}}
```
Partial failures: include structured errors for failed collectors, succeed overall.
Timeout: 10 seconds total (configurable via Application.get_env(:exocomp_node, :system_diagnose_timeout_ms, 10_000))

### Module: Exocomp.Node.Skills.ServiceDiagnose
Input params: %{"services" => [String.t()]} — list of service names from the A2A message
Calls: Systemd.collect(services) with the provided service names
Returns: A2A Artifact with DataPart:
```json
{"schema_version": "1", "skill": "exocomp.service.diagnose", "observations": {"services": {...}}}
```
Validation: reject empty service list with {:error, :invalid_params}; enforce configured allowed service names (from Application.get_env(:exocomp_node, :allowed_services, []))
Timeout: 10 seconds (configurable)

### Module: Exocomp.Node.Skills.RemediationPropose
Input params: diagnostic context map (passed from message DataPart)
Calls: ProposalClient.propose(context) which calls llama-server
Returns: A2A Artifact with DataPart:
```json
{"schema_version": "1", "skill": "exocomp.remediation.propose", "proposal": {"proposal_id": "...", "rationale": "...", "affected_resource": "...", "confidence": 0.85}}
```
Error handling: if ProposalClient returns {:error, reason}, return {:error, reason} — the task fails, but no exception propagates
Inference unavailable: if LlamaServer is not ready, return {:error, :inference_unavailable}

### Module: Exocomp.Node.Skills.Dispatcher
Routes skill_id to the right handler module:
- "exocomp.system.diagnose" → SystemDiagnose
- "exocomp.service.diagnose" → ServiceDiagnose
- "exocomp.remediation.propose" → RemediationPropose
- unknown skill → {:error, :unknown_skill}

### Tests
- SystemDiagnose.execute/2: success path returns artifact with all four measurements
- SystemDiagnose.execute/2: partial collector failure returns artifact with structured error for that collector
- SystemDiagnose.execute/2: timeout returns {:error, :timeout}
- ServiceDiagnose.execute/2: success path returns artifact with service state
- ServiceDiagnose.execute/2: empty service list → {:error, :invalid_params}
- ServiceDiagnose.execute/2: service not in allowed list → {:error, :invalid_params}
- RemediationPropose.execute/2: success returns artifact with proposal
- RemediationPropose.execute/2: ProposalClient returns {:error, :timeout} → {:error, :timeout}
- RemediationPropose.execute/2: inference unavailable → {:error, :inference_unavailable}
- Dispatcher: routes each known skill_id correctly
- Dispatcher: unknown skill → {:error, :unknown_skill}
Use mocked collectors and ProposalClient via Application.put_env or Mox.

### Quality gate
mix test apps/exocomp_node (focused)

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 01:33
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 01:33
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 01:34
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate confirmed. EXOCOMP-80 is the unique child task C of EXOCOMP-12 for implementing skill handler modules.

**Evidence reviewed:**
- EXOCOMP-10 (Done): implements diagnostic collectors (CPU/Memory/Disk/Uptime/Systemd) — prerequisites called BY the skill handlers, not the handlers themselves
- EXOCOMP-11 and children EXOCOMP-61/62/63/64 (Done): implements LlamaServer supervision, ProposalClient, and ProposalSchema — also prerequisites, not skill handlers
- EXOCOMP-78 (Done): implements the A2A HTTP router scaffold, Agent Card, and mTLS enforcement — the layer above, not skill handlers
- EXOCOMP-79 (Done): implements the bounded in-memory TaskRegistry GenServer — task lifecycle tracking, not skill handlers
- EXOCOMP-81 (Open): wires A2A endpoints to TaskRegistry + skill dispatch — explicitly lists EXOCOMP-80 as a prerequisite; depends on, not duplicates, this task
- EXOCOMP-12 (parent epic): confirms EXOCOMP-80 is child C in the planned decomposition

**Repository search:** Zero files matching Skills, SystemDiagnose, ServiceDiagnose, RemediationPropose, or Dispatcher exist in apps/. No prior commits implement the skill handler layer.

**Relevant files for implementation agent:**
- apps/exocomp_node/lib/exocomp/node/collectors/ — CPU, Memory, Disk, Uptime, Systemd (from EXOCOMP-10)
- apps/exocomp_node/lib/exocomp/node/proposal_client.ex — ProposalClient (from EXOCOMP-63)
- apps/exocomp_node/lib/exocomp/node/llama_server.ex — LlamaServer readiness check (from EXOCOMP-62)
- apps/exocomp_core/lib/exocomp/a2a/ — A2A Artifact and DataPart structs (from epic-EXOCOMP-8)
- apps/exocomp_node/lib/exocomp/node/application.ex — supervision tree (no changes needed but worth checking)

**Remaining work:**
1. Create Exocomp.Node.Skills.Behaviour (@callback execute/2)
2. Create Exocomp.Node.Skills.SystemDiagnose (concurrent Task.async CPU/Memory/Disk/Uptime, partial failures, 10s timeout)
3. Create Exocomp.Node.Skills.ServiceDiagnose (Systemd.collect, param validation, allowed_services config)
4. Create Exocomp.Node.Skills.RemediationPropose (ProposalClient.propose, :inference_unavailable handling)
5. Create Exocomp.Node.Skills.Dispatcher (route skill_id to handler module)
6. Write 11 focused ExUnit tests (use Mox or Application.put_env for mocking)
7. Run: mix test apps/exocomp_node

**Risks:**
- Prerequisites (EXOCOMP-78/79) are on separate branches; implementation worktree may need to merge them
- The current epic-EXOCOMP-1 branch must contain the A2A type layer from epic-EXOCOMP-8 and collector modules from EXOCOMP-10; verify before implementing
- LlamaServer readiness check API must be confirmed from the actual llama_server.ex implementation

**Recommended next focus:** feature
---
author: oompah
created: 2026-07-24 01:35
---
Agent completed successfully in 99s (4653 tokens)
---
author: oompah
created: 2026-07-24 01:35
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 33, Tool calls: 21
- Tokens: 14 in / 4.6K out [4.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 39s
- Log: EXOCOMP-80__20260724T013328Z.jsonl
---
author: oompah
created: 2026-07-24 01:35
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 01:35
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 01:35
---
Focus: Epic Planner
---
author: oompah
created: 2026-07-24 01:35
---
Understanding (epic_planner): EXOCOMP-80 is already a concrete child task of epic EXOCOMP-12, with bounded handler, dispatcher, test, and quality-gate scope. I will inspect the parent epic and existing child graph, then decide whether further decomposition would create useful single-session units or merely duplicate this accepted implementation task. No code changes will be made in this focus.
---
author: oompah
created: 2026-07-24 01:36
---
Discovery (epic_planner): EXOCOMP-12 already has a complete four-child decomposition: EXOCOMP-78 router/mTLS (Done), EXOCOMP-79 registry (Done), EXOCOMP-80 skill handlers (current), and EXOCOMP-81 endpoint wiring (Open). EXOCOMP-81 explicitly depends on the dispatcher and three handlers from EXOCOMP-80. EXOCOMP-80 has no children and is a task, not an epic; its five small modules plus focused tests form one cohesive, single-session feature unit.
---
author: oompah
created: 2026-07-24 01:36
---
Implementation (epic_planner): No child tasks were created and no code was changed. Further decomposition would split tightly coupled handler contracts from their focused tests and duplicate the already accepted EXOCOMP-80 scope. The existing parent decomposition is complete; this task should proceed directly to the feature implementation focus.
---
author: oompah
created: 2026-07-24 01:36
---
Verification (epic_planner): Re-read EXOCOMP-80, parent epic EXOCOMP-12, and downstream EXOCOMP-81 via the tracker. Confirmed the task graph covers the full epic flow and that EXOCOMP-80's outputs are the precise prerequisite consumed by EXOCOMP-81. No repository quality gate applies because this planning focus made no file changes.
---
author: oompah
created: 2026-07-24 01:36
---
Focus handoff: epic_planner\n\nOutcome: Planning review is complete. EXOCOMP-80 is already a concrete, independently actionable child of EXOCOMP-12 and should not be decomposed further. No duplicate child tasks were created.\n\nEvidence and decisions: EXOCOMP-12's four children cleanly partition router/mTLS (78), task registry (79), skill handlers (80), and endpoint wiring (81). EXOCOMP-81 explicitly consumes EXOCOMP-80's dispatcher and handlers. EXOCOMP-80's Behaviour, three handlers, Dispatcher, mocks, and focused ExUnit coverage are cohesive and sized for one feature session.\n\nRemaining work and risks: Implement the five modules and 11 focused cases described in the task; verify actual Artifact/DataPart construction and LlamaServer readiness APIs; ensure configurable timeouts and collector dependency injection support deterministic tests; run the focused node test gate, commit, push, and close EXOCOMP-80. Prerequisite availability in this branch should be checked before editing.\n\nRecommended next focus: feature.
---
author: oompah
created: 2026-07-24 01:36
---
Agent completed successfully in 86s (348120 tokens)
---
author: oompah
created: 2026-07-24 01:36
---
Run #1 [attempt=1, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 10
- Tokens: 346.0K in / 2.1K out [348.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 26s
- Log: EXOCOMP-80__20260724T013517Z.jsonl
---
author: oompah
created: 2026-07-24 01:36
---
Focus handoff from `epic_planner` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 01:36
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 01:36
---
Focus: Software Engineer
---
author: oompah
created: 2026-07-24 01:37
---
Understanding (feature): Implementing five Elixir modules for the skill handler layer: Behaviour (callback), SystemDiagnose (concurrent CPU/Memory/Disk/Uptime via Task.async), ServiceDiagnose (Systemd.collect with param validation), RemediationPropose (ProposalClient + LlamaServer readiness), and Dispatcher (skill_id routing). Will also write 11 ExUnit tests using Application.put_env or Mox for mocking. Starting by reading existing prerequisites (collectors, ProposalClient, A2A structs) to match patterns.
---
author: oompah
created: 2026-07-24 01:40
---
Discovery: Merged prerequisite branches EXOCOMP-78 (A2A router + A2A types + mTLS listener), EXOCOMP-79 (TaskRegistry), and EXOCOMP-10 (collectors: CPU/Memory/Disk/Uptime/Systemd) into epic-EXOCOMP-12. All prerequisites now available. Key findings: (1) DataPart has no mimeType field — uses metadata map instead; (2) Collectors use dependency-injection via keyword opts (e.g. :cmd_runner for Systemd, file paths for others), making them testable without mocking; (3) ProposalClient.propose/1 returns {:error, :inference_unavailable} when LlamaServer not ready; (4) No Mox library present — will use Application.put_env + lightweight module stubs for tests. Now implementing the 5 skill modules and 11 tests.
---
author: oompah
created: 2026-07-24 01:51
---
Implementation: Created 5 new modules and 4 test files under apps/exocomp_node: (1) Behaviour — @callback execute/2 contract; (2) SystemDiagnose — concurrent Task.async for CPU/Memory/Disk/Uptime with try/rescue wrapping inside tasks (to prevent EXIT signal propagation on partial failure), uses Task.yield_many for timeout handling; (3) ServiceDiagnose — validates service list against allowed_services config, rejects empty/disallowed with {:error, :invalid_params}; (4) RemediationPropose — delegates to configurable ProposalClient, propagates {:error, reason} unchanged; (5) Dispatcher — routes skill_id to correct handler via static map. Also merged prerequisite branches EXOCOMP-78, EXOCOMP-79, EXOCOMP-10. Key design decision: wrap collector functions in try/rescue inside each Task.async to capture exceptions as {:error, reason} values instead of crash signals, enabling proper partial-failure semantics without trapping exits in the caller.
---
author: oompah
created: 2026-07-24 01:52
---
Verification: make test passes 171/173 tests (10 excluded for integration/systemd). The 2 failures are pre-existing LlamaServer OS-process tests from EXOCOMP-64 that require a real llama-server binary not present in CI. All 22 new skill handler tests pass: 5 SystemDiagnose tests (success, partial-failure, timeout, artifactId, DataPart structure), 7 ServiceDiagnose tests (success, empty list, disallowed service, mixed, missing key, artifactId, multiple-services), 6 RemediationPropose tests (success, timeout propagation, inference_unavailable, schema_error, artifactId, DataPart), 4 Dispatcher tests (3 known skill routes + unknown skill). Branch pushed to origin/epic-EXOCOMP-12.
---
<!-- COMMENTS:END -->
