---
id: EXOCOMP-219
type: task
status: Open
priority: 1
title: Define and sign canonical policy bundles
parent: EXOCOMP-210
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-213
labels: []
assignee: null
created_at: '2026-08-03T14:25:05.936225Z'
updated_at: '2026-08-03T15:33:54.324244Z'
work_branch: epic-EXOCOMP-210--task-EXOCOMP-219
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 8e4f157e381cac884559cb2fc34eb7a534f07384743fd72f70985a2263f95b6c
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:33:49.638972+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: No active task in the provided corpus (EXOCOMP-10 through\
    \ EXOCOMP-123) addresses canonical policy-bundle schema, encoding, or Ed25519\
    \ signature verification. The closest related work\u2014EXOCOMP-16 (coordinator\
    \ PKI initialization and enrollment tokens)\u2014is architecturally distinct and\
    \ focuses on key material initialization and enrollment handshakes, not policy-bundle\
    \ canonicalization or cross-runtime encoding consistency. EXOCOMP-219 is uniquely\
    \ scoped to the policy-bundle domain with its specific requirements for byte-identical\
    \ canonical encoding and Ed25519 signature coverage.\nLooking at this task, I\
    \ need to determine whether EXOCOMP-219 is a duplicate of any existing issue by\
    \ comparing it against the provided task corpus.\n\n## Analysis\n\n**EXOCOMP-219\
    \ Scope:**\n- Title: \"Define and sign canonical policy bundles\"\n- Deliverable:\
    \ Shared versioned cluster policy-bundle schema, canonical encoder, signature\
    \ verifier, and fixture corpus\n- Key characteristics: Ed25519 signatures, byte-identical\
    \ canonical encoding across runtimes (Mission Control, coordinator, node, broker),\
    \ bundle identity fields (organization, cluster, policy version, issue time, expiry,\
    \ signing-key ID)\n- Scope is purely schema/encoding/signature verification\u2014\
    explicitly excludes key storage, transport, caching, lease timers, and policy\
    \ resolution\n\n**Corpus Review:**\n\nI've reviewed all tasks in the provided\
    \ corpus (EXOCOMP-10 through EXOCOMP-123). The active and recent tasks cover:\n\
    - Diagnostic collectors and orchestration (EXOCOMP-100\u2013105, EXOCOMP-10, EXOCOMP-12)\n\
    - Coordinator infrastructure (EXOCOMP-14\u201316: inventory, DNS discovery, CA/enrollment\
    \ tokens)\n- Release and qualification work (EXOCOMP-118\u2013123)\n- All of these\
    \ are in terminal states (Archived or Done)\n\n**No overlapping scope found:**\n\
    - No task in the corpus addresses \"canonical policy bundles\" or Ed25519 signature\
    \ verification\n- EXOCOMP-16 (CA initialization and enrollment tokens) is about\
    \ PKI and enrollment handshakes, not policy-bundle encoding/verification\n- No\
    \ task covers the cross-runtime canonicalization or bundle schema definition that\
    \ EXOCOMP-219 specifies\n- The coordination metadata shows EXOCOMP-219 is a child\
    \ of EXOCOMP-210 (epic-parent) and has dependency/sibling relationships, not duplicate\
    \ relationships\n\n---\n\nFocus handoff: duplicate_detector\n\nDuplicate preflight\
    \ verdict: no_duplicate\n\nMatches: none\n\nEvidence: No active task in the provided\
    \ corpus (EXOCOMP-10 through EXOCOMP-123) addresses canonical policy-bundle schema,\
    \ encoding, or Ed25519 signature verification. The closest related work\u2014\
    EXOCOMP-16 (coordi"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 84afea07-d914-4ff9-8328-cb087874ed04
oompah.work_branch: epic-EXOCOMP-210--task-EXOCOMP-219
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-210--task-EXOCOMP-219
  base_branch: epic-EXOCOMP-210
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:31:18.532012+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 2297
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 2297
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2297
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:33:49.630262+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-219__20260803T153126Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-210--task-EXOCOMP-219
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:33:49.650377+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Add the shared versioned cluster policy-bundle schema, canonical encoder, signature verifier, and fixture corpus.

Acceptance criteria:
- Bundle identity includes organization, cluster, policy version, issue time, expiry, signing-key ID, and only rules applicable to that cluster.
- Canonical encoding is byte-identical across Mission Control, coordinator, node, and broker implementations.
- Ed25519 signatures cover the complete canonical body.
- Unknown versions, duplicate rules, invalid scope identities, non-canonical input, and oversized bundles fail closed.

Tests: Add golden fixtures plus encode/decode, cross-runtime canonicalization, signature, tamper, size, version, duplicate, and malformed-schema tests; run make test, make fmt-check, and make lint.

Out of scope: Key storage, transport, caching, lease timers, and policy resolution semantics.

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
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 2.3K out [2.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 37s
- Log: EXOCOMP-219__20260803T153126Z.jsonl
---
<!-- COMMENTS:END -->
