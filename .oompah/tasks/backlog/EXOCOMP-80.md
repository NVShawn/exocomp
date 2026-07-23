---
id: EXOCOMP-80
type: task
status: Backlog
priority: null
title: 'Skill handler implementations: system.diagnose, service.diagnose, remediation.propose'
parent: EXOCOMP-12
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T23:04:55.080769Z'
updated_at: '2026-07-23T23:04:55.080769Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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

