---
id: EXOCOMP-225
type: task
status: Open
priority: 1
title: Define the privileged broker request protocol and action registry
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-213
- EXOCOMP-219
labels: []
assignee: null
created_at: '2026-08-03T14:26:19.439901Z'
updated_at: '2026-08-03T15:40:50.773970Z'
work_branch: epic-EXOCOMP-211--task-EXOCOMP-225
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: c99fdb2c23291f7f8ad063eb214d12a0b9d33c1e86d3b0e71c0d786042540952
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:40:32.376243+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: ** Reviewed all 40+ tasks in the provided authoritative\
    \ corpus. EXOCOMP-225 uniquely addresses privileged execution broker protocol\
    \ and action registry design, with reference to `plans/hierarchical-management-modes.md`.\
    \ No active task covers broker protocol definition, request parsing, or action\
    \ registry implementation. All terminal tasks reviewed (EXOCOMP-10\u201316, 100\u2013\
    105, 106\u2013123) focus on diagnostics, coordination, orchestration, remediation,\
    \ and release infrastructure\u2014distinct scopes. Closest architectural context\
    \ is in M2 coordinator work (EXOCOMP-14\u201316), which covers policy/state but\
    \ not privileged broker protocol. No duplicate confirmed.\nI am investigating\
    \ whether EXOCOMP-225 is a duplicate of an existing task. Let me review the current\
    \ project task corpus systematically.\n\n**Scope of EXOCOMP-225:**\n- Privileged\
    \ execution broker with no command-line arguments\n- Bounded versioned stdin protocol\n\
    - Closed action registry (only compiled typed actions, fixed builders)\n- Strict\
    \ validation: reject unknown fields/versions/actions, malformed encoding, oversized\
    \ requests\n- No shell or arbitrary executable/argv interface\n- Reference plan:\
    \ `plans/hierarchical-management-modes.md`\n\n**Analysis of provided task corpus:**\n\
    \nI've examined all tasks in the corpus. The tasks fall into these categories:\n\
    \n1. **M1 Node Agent (EXOCOMP-7 through EXOCOMP-13, archived):** Diagnostics,\
    \ llama.cpp supervision, A2A service\u2014no broker/protocol work.\n\n2. **M2\
    \ Coordinator (EXOCOMP-14 through EXOCOMP-16, archived):** Inventory management,\
    \ DNS discovery, PKI/enrollment\u2014no privileged broker.\n\n3. **Coordinator\
    \ orchestration/audit (EXOCOMP-100 through EXOCOMP-105, archived):** Task store,\
    \ fan-out, cancellation, audit trails\u2014no broker protocol.\n\n4. **Recovery/remediation\
    \ tasks (EXOCOMP-106 through EXOCOMP-123, archived):** Bundle fixes, PKI startup,\
    \ reproducibility, performance qualification, requalification\u2014no broker/action\
    \ registry.\n\nAll terminal-state tasks reviewed (Archived, Merged, Done) have\
    \ no overlap with EXOCOMP-225's scope. The task corpus contains no **active**\
    \ (Open, Backlog, Proposed) tasks covering privileged execution brokers, request\
    \ protocols, or action registries.\n\nThe coordination peers listed (EXOCOMP-211\
    \ epic-parent; EXOCOMP-127, 213, 219, 226-234 as dependencies/siblings) are not\
    \ provided in the corpus, but EXOCOMP-225 itself remains the only Open task visible\
    \ in the full corpus.\n\n---\n\nFocus handoff: duplicate_detector\n\nDuplicate\
    \ preflight verdict: no_duplicate\n\nMatches: none\n\n**Evidence:** Reviewed all\
    \ 40+ tasks in the provided authoritative corpus. EXOCOMP-225 uniquely addresses\
    \ privileged execution broker protocol"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 469959d2-d581-44e0-b5e2-9fb03dd9e0d2
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-225
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-225
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:39:06.460559+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 1459
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 1459
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1459
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:40:31.573848+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-225__20260803T153917Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-225
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:40:31.868420+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Generalize the shipped restricted profile helper into one privileged execution broker with a bounded versioned stdin protocol and a closed action registry.

Acceptance criteria:
- The broker has no command-line arguments and reads one length-bounded request from stdin.
- Requests identify schema version, action ID, exact target, node, canonical service key when applicable, policy bundle, and signed action permit.
- The registry contains only compiled typed actions and fixed executable/argument builders.
- Unknown fields, versions, actions, targets, duplicate fields, malformed encoding, trailing data, and oversized requests fail before execution.
- No shell or arbitrary executable/argv interface exists.

Tests: Add parser, registry, size, malformed-input, unknown-action, shell-metacharacter, fuzz-corpus, and fixed-argv snapshot tests; run the focused broker Make target plus make test, make fmt-check, and make lint.

Out of scope: Signature verification, policy resolution, installer changes, and individual action migration.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:38
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:39
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:40
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 1.5K out [1.5K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 36s
- Log: EXOCOMP-225__20260803T153917Z.jsonl
---
<!-- COMMENTS:END -->
