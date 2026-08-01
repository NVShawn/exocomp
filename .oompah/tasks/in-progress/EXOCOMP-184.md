---
id: EXOCOMP-184
type: task
status: In Progress
priority: 1
title: Qualify amd64 and arm64 Mission Control artifacts
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-176
- EXOCOMP-178
- EXOCOMP-181
- EXOCOMP-182
- EXOCOMP-183
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:18:58.209388Z'
updated_at: '2026-08-01T13:28:14.773006Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-184
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 9f504d9488343565c1d4160688e3f0750bcb838ef6ef002b4199224a5f54c000
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:26:44.436595+00:00'
  matched_identifiers: []
  evidence: "Based on my comprehensive investigation of the codebase, documentation,\
    \ and project structure, I can now provide my finding:\n\n## Investigation Summary\n\
    \nI searched for potential duplicates of EXOCOMP-184 (\"Qualify amd64 and arm64\
    \ Mission Control artifacts\") using:\n\n1. **Repository searches** for keywords:\
    \ \"Mission Control\", \"qualify\", \"qualification\", \"M7-CRIT\", \"two-cluster\
    \ scenario\", \"artifact qualification\"\n2. **Documentation review**: Read mission-control.md\
    \ plan, release-qualification.md, maintainer-release-checklist.md, and clean-host-qualification.md\n\
    3. **Makefile inspection**: Confirmed no existing Mission Control qualification\
    \ targets\n4. **Project structure analysis**: Examined the epic decomposition\
    \ and task dependencies\n\n## Key Findings\n\n**EXOCOMP-184 Specifics:**\n- Title:\
    \ \"Qualify amd64 and arm64 Mission Control artifacts\"  \n- Scope: Build Mission\
    \ Control/coordinator/node artifacts for both architectures, run M7 qualification\
    \ tests (repository gates, clean install, migrations, security suite, two-cluster\
    \ scenario, scale gate, backup/restore, upgrade/rollback), publish signed evidence\n\
    - Dependencies: Blocked by EXOCOMP-176, 178, 181, 182, 183\n- Addresses: M7-CRIT-11\
    \ and M7-CRIT-12 from mission-control.md\n\n**Existing Infrastructure:**\n- M6\
    \ qualification exists for node/coordinator (release-qualification.md)\n- M5 performance\
    \ qualification exists (performance-qualification.md)  \n- No M7 Mission Control\
    \ qualification infrastructure found\n- M7 is a new milestone with Mission Control\
    \ as a new component\n\n**Epic Structure:**\n- Part of carefully-planned EXOCOMP-135\
    \ epic\n- Structured decomposition of 8 sibling tasks with tracked dependencies\n\
    - No other tasks reference Mission Control qualification work\n\n---\n\n## Duplicate\
    \ Investigation Result\n\n**Focus handoff: duplicate_detector**\n\n**Duplicate\
    \ preflight verdict: no_duplicate**\n\n**Matches: none**\n\n**Evidence:** Comprehensive\
    \ search across documentation (plans/, docs/), Makefile, and codebase found no\
    \ existing active t"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: bded46ef-defa-4789-a4d7-8222f2408d22
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-184
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-184
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:27:04.044826+00:00'
oompah.task_costs:
  total_input_tokens: 218
  total_output_tokens: 8238
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 218
      output_tokens: 8238
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 218
    output_tokens: 8238
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:26:44.435606+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-184__20260801T132400Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-184
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:26:44.441969+00:00'
---
## Summary

Plan: plans/mission-control.md, Rollout, Test Strategy, and M7-CRIT-11/12.

Deliverables:
- Build final Mission Control, coordinator, and node artifacts from one signed candidate tag for amd64 and arm64.
- Run repository gates, clean install, migrations, security suite, two-cluster scenario, scale gate, backup/restore, upgrade/rollback, and documentation commands on supported qualification guests.
- Publish checksummed and signed evidence indexed by all M7 criteria.

Acceptance:
- Both architectures pass using shipped artifacts and recorded host identities.
- Evidence identifies source commit, builders, dependencies, model, migrations, and configuration.
- Any override is captured as evidence and cannot weaken functional/security requirements.

Out of scope: creating the final public release entry before qualification passes.
Quality gate: make release-check plus the full M7 qualification target.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:23
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:23
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:26
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 62, Tool calls: 26
- Tokens: 218 in / 8.2K out [8.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 52s
- Log: EXOCOMP-184__20260801T132400Z.jsonl
---
author: oompah
created: 2026-08-01 13:27
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 13:27
---
Focus: Security Auditor
---
author: oompah
created: 2026-08-01 13:28
---
UNDERSTANDING: As Security Auditor, my focus is to identify and address security vulnerabilities in the Mission Control artifact qualification process. Key security concerns include:

1. PKI & Certificates: Cluster enrollment with locally-generated keys, certificate rotation (20-30 day lifecycle), and revocation mechanisms
2. OIDC Authentication: Operator identity validation and role enforcement (viewer/operator/admin)
3. mTLS: Cluster-to-control-plane connectivity validation
4. Signing & Verification: HMAC-SHA256 webhook signatures, Ed25519 approval tokens
5. Evidence Redaction: Sanitization before storage/transmission
6. Secret Handling: No secrets in logs, configs, or artifacts
7. Audit Trail: Complete mutation logging with operator identity
8. Cross-architecture consistency: Both amd64/arm64 must pass identical security checks

PLAN:
1. Review codebase for security issues related to artifact qualification (signing, verification, secrets)
2. Check for credential leakage in build/test processes
3. Validate PKI implementation and certificate validation
4. Review evidence redaction and audit trail mechanisms
5. Run make release-check and security-related quality gates
6. Identify and fix any issues found
7. Verify both architectures pass identical security validation
---
<!-- COMMENTS:END -->
