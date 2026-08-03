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
updated_at: '2026-08-03T15:38:08.433692Z'
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
  verdict: no_duplicate
  checked_at: '2026-08-03T15:38:03.339777+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: Searched the complete task corpus for any active (non-terminal)\
    \ task covering policy-signing key provisioning, rotation, or management. EXOCOMP-119\
    \ (PKI/enrollment, Archived) handles node credential enrollment; EXOCOMP-107 (node\
    \ enrollment, Archived) handles client-side credential installation. Neither addresses\
    \ the distinct requirement of managing a dedicated Ed25519 policy-signing key\
    \ for Mission Control bundle authorization. No active duplicate found; EXOCOMP-220\
    \ describes unique work.\n# Duplicate Investigation: EXOCOMP-220\n\nI'll compare\
    \ EXOCOMP-220 against the authoritative task corpus to determine if it's a duplicate\
    \ of any active task.\n\n## Analysis\n\n**EXOCOMP-220 Scope:**\n- Provision and\
    \ rotate a dedicated online Ed25519 policy-signing key\n- Publish verification\
    \ chain to enrolled clusters\n- Secure key storage, stable key IDs with activation/retirement\
    \ timestamps\n- Rotation overlap with current + immediately previous keys only\n\
    - Degrade bundle issuance (not read-only operations) when keys are missing/corrupt/mismatched\n\
    \n**Closest Related Tasks in Corpus:**\n\n1. **EXOCOMP-119** (Archived): \"Start\
    \ production coordinator PKI and enrollment services\"\n   - Scope: PKI state\
    \ initialization, enrollment token service, enrollment/renewal flows\n   - Focus:\
    \ Node-to-coordinator mTLS credential enrollment (PKI for node certificates)\n\
    \   - Different: Node enrollment PKI \u2260 Mission Control policy-signing keys\n\
    \n2. **EXOCOMP-107** (Archived): \"Implement node-agent enrollment client...\"\
    \n   - Scope: Node-side enrollment client, credential installer, renewal scheduler\n\
    \   - Focus: Node credentials from coordinator\n   - Different: Node credentials\
    \ \u2260 policy-signing keys\n\n3. **EXOCOMP-14** (Archived): \"Scaffold coordinator\
    \ inventory, registry, and audit\"\n   - Scope: Infrastructure foundation for\
    \ coordinator\n   - Different: Inventory/audit infrastructure \u2260 key management\n\
    \n**Findings:**\n\nAll tasks in the corpus related to PKI or key material focus\
    \ on **node enrollment credentials** (mTLS certificates for node-to-coordinator\
    \ communication). EXOCOMP-220's scope is uniquely focused on **Mission Control\
    \ policy-signing keys**\u2014a separate cryptographic requirement for bundle authorization.\n\
    \nThe coordinated peers listed in the task metadata (EXOCOMP-219, 221, 222, 223,\
    \ 224, 226 as epic-siblings and dependencies) are not present in the provided\
    \ corpus, suggesting EXOCOMP-220 is part of a newer or distinct epic (EXOCOMP-210)\
    \ that hasn't been retrospectively documented in the historica"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
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
  total_input_tokens: 455762
  total_output_tokens: 4940
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 455762
      output_tokens: 4940
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 455752
    output_tokens: 3221
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:33:26.738705+00:00'
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1719
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:38:03.336938+00:00'
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
  - run_id: EXOCOMP-220__20260803T153644Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-210--task-EXOCOMP-220
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:38:03.351208+00:00'
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
author: oompah
created: 2026-08-03 15:38
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 1.7K out [1.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 28s
- Log: EXOCOMP-220__20260803T153644Z.jsonl
---
<!-- COMMENTS:END -->
