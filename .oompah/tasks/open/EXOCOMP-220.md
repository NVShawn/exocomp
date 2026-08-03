---
id: EXOCOMP-220
type: task
status: Open
priority: 1
title: Manage Mission Control policy-signing keys
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-219
labels: []
assignee: null
created_at: '2026-08-03T14:25:11.140193Z'
updated_at: '2026-08-03T15:36:43.660416Z'
work_branch: epic-EXOCOMP-210--task-EXOCOMP-220
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 1bf24e81bc6b275b555dec62e5aa1be3707a7ec640488f1f6c3ae2df6b71eba2
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: 5462dc05-7538-48f0-aea4-0a9d3e7e8e98
  claim_owner: 2dcc53e1-cdcd-4522-a08d-de6ce4222a8c
  claimed_at: '2026-08-03T15:36:31.453017+00:00'
  claim_expires_at: '2026-08-03T16:06:31.453017+00:00'
  retry_count: 1
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 0d505f45-392c-4eab-895a-2f1814d6d47f
oompah.work_branch: epic-EXOCOMP-210--task-EXOCOMP-220
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-210--task-EXOCOMP-220
  base_branch: epic-EXOCOMP-210
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:36:41.109287+00:00'
oompah.task_costs:
  total_input_tokens: 455752
  total_output_tokens: 3221
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 455752
      output_tokens: 3221
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 455752
    output_tokens: 3221
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:33:26.738705+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-220__20260803T153157Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-210--task-EXOCOMP-220
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:33:26.777973+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Provision and rotate the dedicated online Ed25519 policy-signing key and publish its verification chain to enrolled clusters.

Acceptance criteria:
- Private keys use protected runtime secret storage and are never written to audit, logs, fixtures, or API responses.
- Every key has a stable key ID and activation/retirement timestamps.
- Rotation permits the current and immediately previous verification keys during a bounded overlap.
- Missing, corrupt, insecurely permissioned, or mismatched keys make bundle issuance unavailable without affecting read-only Mission Control operation.

Tests: Cover initial provisioning, permission checks, sign/verify, rotation overlap, retired-key rejection, corruption, restart, redaction, and concurrent issuance; run make test, make fmt-check, make lint, and security checks.

Out of scope: Cluster certificate PKI, bundle delivery, and action permits.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:31
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:31
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:33
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 13
- Tokens: 455.8K in / 3.2K out [459.0K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 38s
- Log: EXOCOMP-220__20260803T153157Z.jsonl
---
author: oompah
created: 2026-08-03 15:36
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:36
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
