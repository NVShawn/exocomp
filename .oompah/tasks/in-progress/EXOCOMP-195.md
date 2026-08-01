---
id: EXOCOMP-195
type: task
status: In Progress
priority: 1
title: Add the shipped cluster-profile registry and version contract
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-189
labels: []
assignee: null
created_at: '2026-07-30T21:38:14.294893Z'
updated_at: '2026-08-01T14:41:04.937458Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-195
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 26cbd1212490db132d74a5d76ade1a8f8bcc9dc0bca9cdfc4949bd1c0e350f25
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:59:33.981374+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector  \nDuplicate preflight verdict: no_duplicate\
    \  \nMatches: none  \n\nEvidence: Reviewed active task records EXOCOMP-186, EXOCOMP-188,\
    \ EXOCOMP-189, EXOCOMP-196\u2013206. They cover parent orchestration, inventory\
    \ parsing, service merging, Ceph implementation stages, and recovery\u2014not\
    \ the shipped profile registry/version contract. No active duplicate confirmed."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: ac6c0299-a9b9-4a71-a353-3f9cea999e35
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-195
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-195
  base_branch: epic-EXOCOMP-186
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:30:30.736430+00:00'
oompah.task_costs:
  total_input_tokens: 1059335
  total_output_tokens: 4793
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 1059335
      output_tokens: 4793
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 1059335
    output_tokens: 4793
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:59:33.974742+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-195__20260801T135730Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-186--task-EXOCOMP-195
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:59:33.989984+00:00'
---
## Summary

Plan: plans/mission-control.md, cluster service path.

Deliverable: Add a behavior and registry for versioned cluster profiles compiled into signed Exocomp releases.

Acceptance criteria:
- A profile exposes ID, version, node-discovery capability, expected-service derivation, health reduction, supported typed actions, and redaction metadata.
- Unknown or unsupported profile versions return structured coverage errors.
- Local files and caller-supplied commands cannot register profiles.
- Node and coordinator Agent Cards advertise supported profile IDs and versions.

Tests: Add registry, duplicate-ID, unknown-version, capability-advertisement, and non-shipped-profile rejection tests; run make test.

Out of scope: Ceph parsing, systemd discovery, privileged execution, and Mission Control storage.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:57
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:57
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:59
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 26
- Tokens: 1.1M in / 4.8K out [1.1M total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 11s
- Log: EXOCOMP-195__20260801T135730Z.jsonl
---
author: oompah
created: 2026-08-01 14:30
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 14:30
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 14:30
---
Understanding: add a signed-release-owned cluster-profile contract exposing identity/version, discovery, expected-service derivation, health reduction, typed actions, and redaction metadata; reject unknown/unsupported versions and all runtime/local/command registration; advertise shipped IDs/versions in node and coordinator Agent Cards. I will inspect the existing cluster and card surfaces, implement the smallest compatible registry, add focused tests, then run the Makefile test gate.
---
author: oompah
created: 2026-08-01 14:31
---
Discovery: no cluster-profile implementation exists yet. The shared A2A card model is in apps/exocomp_core/lib/exocomp/a2a; node and coordinator card handlers are separate. Existing node/coordinator action and health modules should remain unchanged for this contract-only task. I’m defining the release-owned registry in shared core and wiring supported profile IDs/versions into both card producers.
---
author: oompah
created: 2026-08-01 14:36
---
Implementation: added Exocomp.ClusterProfile behavior, Default profile v1, static Registry, and structured CoverageError. The registry has no dynamic source or mutation path; register/register_from_file/register_from_command fail closed. AgentCard/Codec now carry clusterProfiles, and node/coordinator cards advertise the shipped default ID/version. Focused tests cover contract fields, duplicate IDs, unknown/unsupported coverage, registration rejection, and both card handlers.
---
author: oompah
created: 2026-08-01 14:41
---
Verification update: standalone elixirc compilation of all exocomp_core sources succeeds; the focused registry ExUnit file passes 6/6. make fmt-check and focused mix tests cannot start in this environment because the host has Elixir 1.18.3 (project requires 1.20.2) and the container engine fails on read-only /run/user/1000/libpod configuration. I will run the required make test gate and record its result.
---
<!-- COMMENTS:END -->
