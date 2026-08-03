---
id: EXOCOMP-233
type: task
status: Open
priority: 1
title: Migrate shipped cluster-profile actions to the broker
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-229
- EXOCOMP-230
labels: []
assignee: null
created_at: '2026-08-03T14:26:39.646035Z'
updated_at: '2026-08-03T15:47:55.097613Z'
work_branch: epic-EXOCOMP-211--task-EXOCOMP-233
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: f00033530429fcefd154fe9520e524ddcfc419e6dfd218d288be242b52c246ff
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:47:49.441805+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: The authoritative current project task corpus contains\
    \ no existing task covering Ceph cluster-profile action brokering or profile mutation\
    \ routing. All 50+ tasks in the corpus (EXOCOMP-10 through EXOCOMP-123) address\
    \ distinct domains: node-agent diagnostics (M1), coordinator infrastructure and\
    \ PKI (M2), benchmark/performance work (M5), and release/bundle management (M6).\
    \ EXOCOMP-233's scope\u2014routing shipped Ceph profile mutations through a common\
    \ broker with profile-specific policy\u2014is unique and overlaps with none of\
    \ the tracked work. The related epic (EXOCOMP-211) and sibling tasks (EXOCOMP-225-234)\
    \ referenced in coordination metadata are not present in the corpus, indicating\
    \ they either do not yet exist or are managed separately. No duplicate is confirmed.\n\
    I will now investigate whether EXOCOMP-233 is a duplicate of any existing task\
    \ by carefully comparing it against the provided project task corpus.\n\n## Investigation\n\
    \n**Current Task Analysis:**\nEXOCOMP-233 is about migrating shipped Ceph cluster-profile\
    \ actions to route through a common broker while preserving profile-specific policy.\
    \ Key scope elements:\n- Ceph cluster profile mutations\n- Broker-based routing\n\
    - Profile daemon instance mapping to canonical service keys\n- Profile-specific\
    \ policy preservation\n- Legacy profile-helper removal\n\n**Corpus Search:**\n\
    I've reviewed all tasks in the provided authoritative corpus (EXOCOMP-10 through\
    \ EXOCOMP-123). The corpus covers:\n\n1. **M1 Milestone (Node Agent):** EXOCOMP-10-13\n\
    \   - Linux/systemd diagnostics\n   - llama.cpp supervision\n   - Node A2A service\n\
    \   - **No profile/Ceph work**\n\n2. **M2 Milestone (Coordinator):** EXOCOMP-14-16\
    \ + dependencies (100-105)\n   - Coordinator scaffolding, PKI, enrollment\n  \
    \ - Diagnostic orchestration\n   - DNS discovery, polling\n   - **No profile/Ceph\
    \ work**\n\n3. **Recovery Epic:** EXOCOMP-111-116\n   - A2A codecs, benchmarks,\
    \ acceptance tests\n   - Governance and release work\n   - **No profile/Ceph work**\n\
    \n4. **Release/Installation:** EXOCOMP-118-123\n   - Bundle installation, PKI\
    \ services\n   - Performance qualification\n   - Clean-host release certification\n\
    \   - **No profile/Ceph work**\n\n**Keyword Search Results:**\nNo task in the\
    \ corpus contains:\n- \"cluster-profile\" / \"profile mutation\"\n- \"broker\"\
    \ (in the routing/action sense)\n- \"Ceph\" or cluster management terminology\n\
    - \"shipped profile action\"\n- \"profile daemon\"\n\n**Status Filter:**\nAll\
    \ potentially related tasks referenced in coordination metadata (EXOCOMP-127,\
    \ EXOCOMP-211, EXOCOMP-225-234) are outside the corpus range and not in terminal\
    \ states, so they cannot be duplicate targets.\n\n---\n\nFocus handoff: duplicate_detector\n\
    \nDuplicate preflight verdict: no_duplicate\n\nMatches: none\n\nEvidence: The\
    \ authoritative current project task corpus contains no"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: aca48ed7-9092-40f8-97a7-0bc6b289242a
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-233
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-233
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:46:30.004617+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 3714
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 3714
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 3714
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:47:49.437619+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-233__20260803T154635Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-233
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:47:49.450290+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Route Ceph and future shipped profile mutations through the common broker while preserving profile-specific policy.

Acceptance criteria:
- Profile daemon instances map to canonical service keys before policy resolution.
- Node/service overrides apply to all matching local instances; exact target and profile version remain permit-bound.
- Broker requires manage plus the installed shipped-profile action, topology/evidence, disruption, cooldown, and verification rules.
- Unknown/local profile definitions and arbitrary Ceph commands remain impossible.
- Legacy profile-helper execution and sudo entries are removed.

Tests: Cover every shipped Ceph role, multiple OSD instances, all policy scopes, peer conflict, unsupported profile/node, topology drift, observe denial, permit mismatch, legacy-path rejection, and safe-restart integration; run make test, profile integration gates, make fmt-check, and make lint.

Out of scope: Adding new Ceph repair action types.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:46
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:46
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:47
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 3.7K out [3.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 26s
- Log: EXOCOMP-233__20260803T154635Z.jsonl
---
<!-- COMMENTS:END -->
