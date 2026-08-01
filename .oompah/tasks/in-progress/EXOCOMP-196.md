---
id: EXOCOMP-196
type: task
status: In Progress
priority: 1
title: Validate Ceph profile configuration and read-only credentials
parent: EXOCOMP-186
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-195
labels:
- focus-complete:docs
- needs:feature
assignee: null
created_at: '2026-07-30T21:38:18.558307Z'
updated_at: '2026-08-01T15:15:26.091205Z'
work_branch: epic-EXOCOMP-186--task-EXOCOMP-196
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: a03743bc0cb5768c8457f1924bc0c71e5d799f4774b7c2bd7f219a52690e6384
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:05:12.917713+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\n\nDuplicate preflight verdict: no_duplicate\n\
    \nMatches: none\n\nEvidence: Reviewed active task records EXOCOMP-186, EXOCOMP-195,\
    \ EXOCOMP-197\u2013EXOCOMP-206. EXOCOMP-195 covers the profile registry/version\
    \ contract, EXOCOMP-197 covers Ceph collection, EXOCOMP-202 covers helper packaging,\
    \ and EXOCOMP-205 covers user documentation; none owns protected coordinator configuration\
    \ validation. Terminal tasks were excluded."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 229faea2-f0f0-4609-87fe-09631239826b
oompah.work_branch: epic-EXOCOMP-186--task-EXOCOMP-196
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-186--task-EXOCOMP-196
  base_branch: epic-EXOCOMP-186
  base_sha: ab25e80c7dae6afdf9e0b9f0f99ad82a0728462b
  updated_at: '2026-08-01T15:13:13.501346+00:00'
oompah.task_costs:
  total_input_tokens: 926009
  total_output_tokens: 19611
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 926009
      output_tokens: 19611
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 925743
    output_tokens: 5957
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:05:12.912429+00:00'
  - profile: default
    model: haiku
    input_tokens: 266
    output_tokens: 13654
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:10:59.207201+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-196__20260801T140247Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-186--task-EXOCOMP-196
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:05:12.922722+00:00'
---
## Summary

Plan: plans/mission-control.md, Ceph profile configuration.

Deliverable: Add protected coordinator configuration for a fixed Ceph binary, ceph.conf, and client.exocomp keyring.

Acceptance criteria:
- Profile activation requires exact absolute paths and a supported profile version.
- Startup validates file existence, ownership, keyring permissions, and executable identity without logging key material.
- Missing or unsafe configuration degrades profile coverage and emits an actionable audit event instead of crashing unrelated monitoring.
- Documentation specifies read-only mon, mgr, osd, and mds cephx capabilities.

Tests: Cover valid configuration, missing files, relative paths, unsafe permissions, wrong ownership, absent binary, and secret redaction; run make test.

Out of scope: Creating Ceph credentials automatically, parsing Ceph command output, and remediation.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:02
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:02
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:05
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 21
- Tokens: 925.7K in / 6.0K out [931.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 32s
- Log: EXOCOMP-196__20260801T140247Z.jsonl
---
author: oompah
created: 2026-08-01 14:59
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 14:59
---
Focus: Technical Writer
---
author: oompah
created: 2026-08-01 15:02
---
Understanding: My role as Technical Writer is to document Ceph profile configuration for protected coordinator operation. The task requires documentation specifying:
1. Configuration format for fixed Ceph binary path, ceph.conf, and client.exocomp keyring (absolute paths, version required)
2. Startup validation requirements (file existence, ownership, keyring permissions, executable identity, no key material logging)
3. Read-only cephx capabilities (mon, mgr, osd, mds)
4. Degraded profile coverage and audit events for missing/unsafe configuration

Plan:
1. Explore existing cluster profile implementation (from EXOCOMP-195)
2. Look for any Ceph-specific code or configuration examples
3. Review validation and audit event patterns in the codebase
4. Create or update docs/ file with Ceph profile configuration guide
5. Document with verified examples (no hypothetical code)
6. Verify tests exist for the scenarios mentioned in acceptance criteria
---
author: oompah
created: 2026-08-01 15:08
---
Discovery: Created comprehensive Ceph profile configuration documentation (docs/ceph-profile-configuration.md) covering:
1. Configuration requirements (absolute paths, version 1)
2. Startup validation (file existence, ownership, permissions, executable identity, no key logging)
3. Cephx capabilities (mon, mgr, osd, mds read-only)
4. Configuration examples with JSON and env vars
5. Validation checklist and troubleshooting

Finding: Documentation is complete, but implementation is needed:
- Ceph profile module (Exocomp.ClusterProfile.Ceph) not yet implemented
- Coordinator configuration doesn't yet support cluster_profiles section
- Validation logic and audit events not yet implemented
- Tests for validation scenarios not yet written

Task requires both documentation AND code implementation. As Technical Writer, I've completed documentation. Next phase needs backend developer to:
1. Create ClusterProfile.Ceph module per EXOCOMP-195 pattern
2. Add cluster_profiles config support to Coordinator.Config
3. Implement startup validation with audit events
4. Write comprehensive tests per acceptance criteria
---
author: oompah
created: 2026-08-01 15:08
---
HANDOFF: Documentation phase complete. 

Summary of documentation work:
- Created docs/ceph-profile-configuration.md with complete operator guidance
- Documented absolute path requirements and validation rules
- Specified Ceph read-only capabilities (mon, mgr, osd, mds)
- Provided configuration examples and troubleshooting guide
- Documented that validation failures degrade profile coverage instead of crashing

What a backend developer needs to implement:
1. Create apps/exocomp_core/lib/exocomp/cluster_profile/ceph.ex implementing ClusterProfile behavior
   - id() -> "ceph"
   - version() -> 1
   - Implement required callbacks per ClusterProfile contract
   - Include validation metadata for file paths, permissions, ownership

2. Extend Exocomp.Coordinator.Config to support cluster_profiles configuration section with:
   - ceph_binary_path, ceph_conf_path, keyring_path
   - Environment variable overrides (EXOCOMP_CEPH_*)

3. Implement coordinator startup validation:
   - Check file existence, ownership, permissions during startup
   - Emit audit events on validation failures (without logging secrets)
   - Degrade profile coverage on failure (don't crash coordinator)

4. Add tests per acceptance criteria:
   - Valid configuration (all files present, correct permissions)
   - Missing files (binary, ceph.conf, keyring)
   - Relative paths (should be rejected)
   - Unsafe permissions (world-readable keyring, etc.)
   - Wrong ownership (root-owned files, etc.)
   - Absent binary (validation failure)
   - Secret redaction (no key material in logs)

Reference implementation: apps/exocomp_core/lib/exocomp/cluster_profile/default.ex
Reference tests: apps/exocomp_core/test/exocomp/cluster_profile/registry_test.exs

Note: EXOCOMP-195 established profile infrastructure; this builds on that foundation.
---
author: oompah
created: 2026-08-01 15:10
---
Completion: Documentation phase complete and handed off.

Delivered:
- docs/ceph-profile-configuration.md with complete operator guidance for Ceph integration
- Specification of absolute path requirements, validation rules, and fail-safe degradation behavior
- Cephx capability recommendations (mon, mgr, osd, mds read-only)
- Configuration examples and environment variable overrides
- Troubleshooting guide and validation checklist

Branch: epic-EXOCOMP-186--task-EXOCOMP-196
Commit: f621e163 (Ceph profile configuration documentation)

Status: Handed off to backend/feature developer with detailed implementation guidance
Label: needs:feature (for backend implementation phase)

Next phase: Backend developer implements Ceph profile module, coordinator configuration support, startup validation with audit events, and comprehensive tests.
---
author: oompah
created: 2026-08-01 15:11
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 0, Tool calls: 52
- Tokens: 266 in / 13.7K out [13.9K total]
- Cost: $0.0000
- Exit: terminated, Duration: 11m 18s
- Log: EXOCOMP-196__20260801T145948Z.jsonl
---
author: oompah
created: 2026-08-01 15:13
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-08-01 15:13
---
Focus: Technical Writer
---
author: oompah
created: 2026-08-01 15:13
---
Understanding: I will review the existing Ceph profile operator documentation for accuracy and concise, usable configuration guidance; verify examples against the current repository; then document any remaining backend implementation work in a focused handoff.
---
author: oompah
created: 2026-08-01 15:15
---
Implementation (docs): Confirmed the committed guide in docs/ceph-profile-configuration.md documents the required absolute-path, version, startup-validation, degradation, and read-only Cephx capability contract. No code was changed in this docs focus.
---
author: oompah
created: 2026-08-01 15:15
---
Verification (docs): make check-links passed. Repository inspection confirms the guide's Cephx command and JSON examples are syntactically valid; coordinator support for the documented cluster_profiles.ceph schema remains to be implemented.
---
author: oompah
created: 2026-08-01 15:15
---
Focus handoff: docs\n\nOutcome: Ceph operator documentation is complete and link-checked.\n\nRelevant files and evidence: docs/ceph-profile-configuration.md (committed as f621e163); make check-links passed. The current profile registry (apps/exocomp_core/lib/exocomp/cluster_profile/registry.ex) ships only Exocomp.ClusterProfile.Default, and apps/exocomp_coordinator/lib/exocomp/coordinator/config.ex currently accepts only version, coordinator_id, tls, and listen.\n\nRemaining work and risks: Implement and test the Ceph profile, protected cluster_profiles.ceph config parsing, startup file/ownership/permission/executable validation, redacted actionable audit event emission, and degraded Ceph coverage. Align the final ownership policy and any environment overrides precisely with the documented contract; do not expose keyring content.\n\nRecommended next focus: feature.
---
author: oompah
created: 2026-08-01 15:15
---
Completion (docs): Documentation phase is complete. The task remains in progress for the feature implementation described in the handoff.
---
<!-- COMMENTS:END -->
