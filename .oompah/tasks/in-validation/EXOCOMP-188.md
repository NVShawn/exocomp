---
id: EXOCOMP-188
type: task
status: In Validation
priority: 1
title: Add coordinator inventory v2 service-monitoring fields
parent: EXOCOMP-185
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-187
labels: []
assignee: null
created_at: '2026-07-30T21:36:57.890248Z'
updated_at: '2026-08-01T13:59:03.129030Z'
work_branch: epic-EXOCOMP-185--task-EXOCOMP-188
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 5fa601cce56f09b943a2e26288b42b8f33455297aa6fe6b4929200cf4e5b26b9
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:40:27.215030+00:00'
  matched_identifiers: []
  evidence: "Based on my investigation, I have thoroughly searched the codebase and\
    \ task system for any duplicate or overlapping work.\n\n## Investigation Summary\n\
    \n**What I searched:**\n- `.oompah/tasks` directory for similar tasks\n- Codebase\
    \ for \"inventory\", \"coordinator\", \"service-monitoring\", \"v2\", \"profile\"\
    , \"EXOCOMP\" references\n- Current Inventory module implementation in `apps/exocomp_coordinator/lib/exocomp/coordinator/inventory.ex`\n\
    - Current Inventory.Node structure\n- Existing test coverage in `inventory_test.exs`\n\
    - CHANGELOG, plans, and documentation\n\n**What I found:**\n\n1. **Current Implementation\
    \ State**: The Inventory module (v1) only supports basic node metadata:\n   -\
    \ id, hostname, port, certificate_identity, capabilities, labels\n   - No service\
    \ monitoring, automatic enablement, or cluster profile fields exist\n\n2. **Version\
    \ 2 Status**: The test file explicitly shows v2 is currently REJECTED as unsupported:\n\
    \   ```elixir\n   assert {:error, %{code: :unsupported_inventory_version}} =\n\
    \          :json.encode(%{\"version\" => 2, \"nodes\" => []})\n   ```\n\n3. **Related\
    \ Tasks**: EXOCOMP-187 and other EXOCOMP tasks (185, 189-194, 205) are listed\
    \ as coordination peers, NOT duplicates. They are distinct tasks in the same epic.\n\
    \n4. **No Existing Implementation**: Zero code references to service monitoring,\
    \ v2 inventory validation, or cluster profiles in the coordinator.\n\n---\n\n\
    **Focus handoff: duplicate_detector**\n\n**Duplicate preflight verdict: no_duplicate**\n\
    \n**Matches: none**\n\n**Evidence:** EXOCOMP-188 requests a new feature to extend\
    \ the coordinator inventory parser with v2 support for optional per-node service\
    \ entries, automatic-mode enablement, and cluster-profile declaration. The current\
    \ codebase only implements v1 inventory with basic node metadata (id, hostname,\
    \ port, certificate_identity, capabilities, labels). No existing active task or\
    \ implemented code handles v2 service-monitoring fields. The coordination peers\
    \ listed (EXOCOMP-185, EXOCOMP-187, EXOCOMP-189-194, EXOCOMP-205) a"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 761000a1-46fb-4fa4-99cd-6fe5cf7b91f2
oompah.work_branch: epic-EXOCOMP-185--task-EXOCOMP-188
oompah.integration:
  version: 2
  state: integrated
  attempts: 1
  task_branch: epic-EXOCOMP-185--task-EXOCOMP-188
  base_branch: epic-EXOCOMP-185
  base_sha: 6742aa13ef4dc7e3dafa1582cebb5e4550ba9a72
  head_sha: e211afce695af9a158376ffc5e5eac66044c88c5
  integrated_sha: e211afce695af9a158376ffc5e5eac66044c88c5
  submitted_at: '2026-08-01T13:58:23.730368+00:00'
  updated_at: '2026-08-01T13:58:59.497904+00:00'
oompah.task_costs:
  total_input_tokens: 1136
  total_output_tokens: 5761
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 1136
      output_tokens: 5761
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 178
    output_tokens: 5516
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:40:27.213614+00:00'
  - profile: default
    model: haiku
    input_tokens: 958
    output_tokens: 245
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:58:36.935180+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-188__20260801T133834Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-185--task-EXOCOMP-188
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:40:27.227347+00:00'
oompah.terminal_audit:
  queued_comment_posted: true
  version: 1
  pending_chain:
  - version: 1
    audit_id: audit-e734e02e8d0d
    project_id: proj-c260b117
    task_id: EXOCOMP-188
    target_state: Done
    request_state: pending
    evidence_fingerprint:
      version: 1
      algorithm: sha256
      digest: f5a91af2fc653d72ddff070ab74e7f62f4e1296277e4ab43bf353bed0ccc53bd
    attempts: []
    requested_by:
      version: 1
      identity: oompah-integration
      source: service
    previous_state: Ready to Integrate
    created_at: '2026-08-01T13:59:00.538419+00:00'
  attempt_history: []
---
## Summary

Plan: plans/mission-control.md, three-path desired-state extension.

Deliverable: Extend the coordinator inventory parser with optional per-node manual service entries, optional automatic-mode enablement, and a root cluster-profile declaration.

Acceptance criteria:
- Version 2 validates exact .service names, boolean automatic enablement, and loopback HTTP health checks.
- Version 1 inventories still load with empty monitoring and profile defaults.
- Invalid replacements leave the active inventory unchanged and emit the existing rejection audit path.
- Parsed values are available through typed inventory structures.

Tests: Add focused parser tests for valid v1/v2 files and malformed names, URLs, booleans, profiles, duplicates, and atomic rejection; run make test.

Out of scope: Polling, systemd collection, Ceph logic, and Mission Control persistence.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:38
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:38
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:40
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 55, Tool calls: 26
- Tokens: 178 in / 5.5K out [5.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 58s
- Log: EXOCOMP-188__20260801T133834Z.jsonl
---
author: oompah
created: 2026-08-01 13:46
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 13:46
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-08-01 13:48
---
**Understanding:** Implementing Coordinator Inventory v2 service-monitoring fields. Current state: inventory v1 supports basic node definitions (id, hostname, port, certificate_identity, capabilities, labels). Task extends parser to support:
1. Optional per-node manual service entries (with .service name, HTTP health check URL validation)
2. Optional automatic-mode enablement (boolean)
3. Root cluster-profile declaration

Approach: (1) Extend Node struct with optional monitoring fields, (2) Update validate() to handle v1 and v2 with backward-compatibility, (3) Add validation for service names, HTTP URLs, booleans, (4) Add comprehensive tests for valid/invalid inputs, (5) Ensure atomic rejection leaves prior inventory intact.

Will now explore current version and design v2 schema.
---
author: oompah
created: 2026-08-01 13:48
---
**Discovery:** Found inventory implementation in apps/exocomp_coordinator/lib/exocomp/coordinator/inventory.ex. Current structure:
- Inventory.ex: Parses JSON, validates nodes, manages replacements atomically
- Node struct: id, hostname, port, certificate_identity, capabilities, labels
- Tests: inventory_test.exs validates JSON parsing, duplicates, malformed data, file loading

Will implement v2 by:
1. Extending Node struct with optional monitoring: {automatic: bool, services: [{name: string, health_check_url: string}]}
2. Updating validate() to accept v1 (backward compatible) and v2 with new fields
3. Adding validations: .service names (must end with .service), HTTP URLs (loopback), boolean automatic
4. Adding comprehensive tests for v1 backward-compat, v2 valid/invalid inputs, atomic rejection
---
author: oompah
created: 2026-08-01 13:58
---
**Implementation:** Extended coordinator inventory parser to support v2 with service-monitoring fields. Changes:

1. Extended Node struct: Added optional monitoring field with automatic (bool) and services array
2. Updated inventory validation: Added support for v1 (backward-compatible) and v2 with new cluster_profile field
3. Added v2-specific validation:
   - Service names must end with .service (e.g., ceph-mon.service)
   - Health check URLs restricted to loopback (http://127.0.0.1, http://localhost, http://[::1])
   - Automatic field must be boolean (defaults to false)
   - Duplicate service names rejected per node
   - cluster_profile optional root field
4. Maintained backward compatibility: v1 inventories load with monitoring=nil and cluster_profile=nil
5. Atomic rejection: Invalid v2 replacements leave prior inventory unchanged, emit audit event

Test coverage: Added 26 new tests covering:
- v1 backward compatibility
- v2 valid/invalid inputs
- Service name validation (.service suffix, duplicates)
- Health check URL validation (loopback only, http only, port/path parsing)
- Automatic boolean validation
- Atomic rejection scenarios
---
author: oompah
created: 2026-08-01 13:58
---
**Verification:** All 537 tests pass including:
- 26 new inventory tests for v1/v2 validation
- Full test suite passes: make test
- Backward compatibility verified: v1 files load unchanged
- Atomic rejection verified: invalid replacements leave prior inventory intact
- Service validation: .service names, loopback URLs, boolean automatic
- Parsing available through typed inventory structures

Branch pushed to origin/epic-EXOCOMP-185--task-EXOCOMP-188. Ready for submission.
---
author: oompah
created: 2026-08-01 13:58
---
Implemented coordinator inventory v2 with service-monitoring fields: per-node services (name, health_check_url), automatic boolean flag, cluster-profile root field. Full backward-compatibility with v1, atomic validation, comprehensive test coverage (26 new tests, all 537 tests pass).
---
author: oompah
created: 2026-08-01 13:58
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 0, Tool calls: 57
- Tokens: 958 in / 245 out [1.2K total]
- Cost: $0.0000
- Exit: terminated, Duration: 11m 55s
- Log: EXOCOMP-188__20260801T134649Z.jsonl
---
author: oompah
created: 2026-08-01 13:59
---
Queued for terminal transition to Done. An auditor will review and apply the terminal status.
---
<!-- COMMENTS:END -->
