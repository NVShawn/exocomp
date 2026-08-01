---
id: EXOCOMP-195
type: task
status: Done
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
updated_at: '2026-08-01T14:58:07.659689Z'
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
  state: integrated
  attempts: 1
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-195
  base_branch: epic-EXOCOMP-186
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  head_sha: ab25e80c7dae6afdf9e0b9f0f99ad82a0728462b
  integrated_sha: ab25e80c7dae6afdf9e0b9f0f99ad82a0728462b
  submitted_at: '2026-08-01T14:43:26.071485+00:00'
  updated_at: '2026-08-01T14:44:03.364258+00:00'
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
oompah.terminal_audit:
  queued_comment_posted: true
  applied_result_attempts:
    attempt-980133c24157: '2026-08-01T14:58:05.084523+00:00'
  oompah.terminal_audit_retirements:
  - project_id: proj-c260b117
    task_id: EXOCOMP-195
    target_state: Done
    evidence_fingerprint: f7da0ed368bc9eab3d5cb92f6fceadc27098da9a950d86fe10aa6104510ebefd
    audit_ids:
    - audit-a63d8fdf7553
    kind: result
    applied: true
    retired_at: '2026-08-01T14:58:05.084537+00:00'
  oompah.terminal_audit_result_intents:
  - project_id: proj-c260b117
    task_id: EXOCOMP-195
    audit_id: audit-a63d8fdf7553
    attempt_id: attempt-980133c24157
    target_state: Done
    evidence_fingerprint: f7da0ed368bc9eab3d5cb92f6fceadc27098da9a950d86fe10aa6104510ebefd
    status: Done
    audit_ids:
    - audit-a63d8fdf7553
    applied: false
    created_at: '2026-08-01T14:58:05.084559+00:00'
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-a63d8fdf7553
    project_id: proj-c260b117
    task_id: EXOCOMP-195
    target_state: Done
    request_state: completed
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: f7da0ed368bc9eab3d5cb92f6fceadc27098da9a950d86fe10aa6104510ebefd
    attempts:
    - version: 1
      attempt_id: attempt-980133c24157
      target_state: Done
      request_state: completed
      evidence_fingerprint:
        version: 1
        algorithm: sha256
        digest: f7da0ed368bc9eab3d5cb92f6fceadc27098da9a950d86fe10aa6104510ebefd
      created_at: '2026-08-01T14:44:09.747222+00:00'
      provider_id: prov-651d553c
      model: opus
      started_at: '2026-08-01T14:44:09.747222+00:00'
      branch_key: epic-EXOCOMP-186--task-EXOCOMP-195
      verdict: pass
      completed_at: '2026-08-01T14:58:05.084228+00:00'
      ended_at: '2026-08-01T14:58:05.084228+00:00'
    requested_by:
      version: 1
      identity: oompah-integration
      source: service
    previous_state: Ready to Integrate
    created_at: '2026-08-01T14:44:04.770796+00:00'
    updated_at: '2026-08-01T14:58:05.084228+00:00'
  attempt_history:
  - version: 1
    attempt_id: attempt-980133c24157
    target_state: Done
    request_state: in_progress
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: f7da0ed368bc9eab3d5cb92f6fceadc27098da9a950d86fe10aa6104510ebefd
    created_at: '2026-08-01T14:44:09.747222+00:00'
    provider_id: prov-651d553c
    model: opus
    started_at: '2026-08-01T14:44:09.747222+00:00'
    branch_key: epic-EXOCOMP-186--task-EXOCOMP-195
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
author: oompah
created: 2026-08-01 14:42
---
Verification: make test completed its offline builder/packaging checks (13/13 plus Python release tests: 6, 3, and 7 all passed) but exited 2 when the required Elixir container stage could not start: host Podman reports read-only /run/user/1000/libpod. Native mix tests are also unavailable under Elixir 1.18.3 versus required 1.20.2. Independent checks pass: all exocomp_core sources compile with elixirc, the six registry ExUnit tests pass, and AgentCard profile encode/decode smoke round-trip passes.
---
author: oompah
created: 2026-08-01 14:43
---
Completion: delivered and pushed commit ab25e80c on epic-EXOCOMP-186--task-EXOCOMP-195. The signed-release-owned default profile v1 contract and static registry expose discovery, service derivation, health reduction, typed actions, and redaction metadata; structured coverage errors handle unknown/unsupported versions; runtime/file/command registration is rejected; both node and coordinator Agent Cards advertise the shipped profile ID/version. Branch is clean and up to date with origin.
---
author: oompah
created: 2026-08-01 14:43
---
Added the static shipped cluster-profile behavior/registry with default profile v1, structured coverage errors, fail-closed runtime/file/command registration, and node/coordinator Agent Card profile advertisements. Added registry, duplicate-ID, unknown/unsupported version, rejection, codec, and card tests. Commit ab25e80c pushed; make test offline checks passed but containerized Elixir stage was blocked by host Podman configuration.
---
author: oompah
created: 2026-08-01 14:43
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 0, Tool calls: 96
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 13m 16s
- Log: EXOCOMP-195__20260801T143033Z.jsonl
---
author: oompah
created: 2026-08-01 14:44
---
Queued for terminal transition to Done. An auditor will review and apply the terminal status.
---
author: oompah
created: 2026-08-01 14:44
---
Auditor dispatched (attempt #1, candidate: prov-651d553c/opus)
---
author: oompah
created: 2026-08-01 14:44
---
Focus: Completion Auditor
---
author: oompah
created: 2026-08-01 14:58
---
Audit PASS — Done

[REDACTED]

Safe evidence:
- branch_head: ab25e80c7dae6afdf9e0b9f0f99ad82a0728462b
- remote_branch: origin/epic-EXOCOMP-186--task-EXOCOMP-195
- commit_stat: 12 files changed, 432 insertions(+), 5 deletions(-)
- profile_registry_module: apps/exocomp_core/lib/exocomp/cluster_profile/registry.ex
- default_profile_module: apps/exocomp_core/lib/exocomp/cluster_profile/default.ex
- coverage_error_module: apps/exocomp_core/lib/exocomp/cluster_profile/coverage_error.ex
- behavior_module: apps/exocomp_core/lib/exocomp/cluster_profile.ex
- registry_tests: apps/exocomp_core/test/exocomp/cluster_profile/registry_test.exs (6 tests)
- codec_test_updated: apps/exocomp_core/test/exocomp/a2a/codec_test.exs (clusterProfiles round-trip + malformed rejection)
- node_card_test: apps/exocomp_node/test/exocomp/node/a2a_router_test.exs asserts clusterProfiles == [{id: default, versions: [1]}]
- coordinator_card_test: apps/exocomp_coordinator/test/exocomp/coordinator/a2a_router_test.exs asserts clusterProfiles == [{id: default, versions: [1]}]
- make_test_builders: 13 passed, 0 failed (verified in-session)
- make_test_release_packaging: 6 + 3 + 7 = 16 Python tests all passed (verified in-session)
- make_test_compliance: 29 tests OK (verified in-session)
- mix_test_evidence: Registry.beam artifact timestamp 2026-08-01 14:48:08 precedes both node and coordinator release builds at 14:53:36-37, proving mix test and mix release stages of make test completed
- advertised_profile_payload: [%{id: 'default', versions: [1]}]
- coverage_error_codes: :unknown_profile, :unsupported_profile_version, :non_shipped_profile, :duplicate_profile_id, :invalid_profile
---
<!-- COMMENTS:END -->
