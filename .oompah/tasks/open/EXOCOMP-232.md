---
id: EXOCOMP-232
type: task
status: Open
priority: 1
title: Migrate journal vacuum to the broker
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-229
- EXOCOMP-230
labels: []
assignee: null
created_at: '2026-08-03T14:26:36.951867Z'
updated_at: '2026-08-03T15:46:57.440265Z'
work_branch: epic-EXOCOMP-211--task-EXOCOMP-232
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: fea6ea4724ac53bb25cff903075cba869f4d2d05d6901eb1953bc23f788d265a
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:46:54.022189+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: ** After reviewing all 60+ tasks in the provided corpus,\
    \ no active (Open/Proposed) or inactive (Done/Merged/Archived) task describes\
    \ migrating journal vacuum operations to a broker action pattern with node/cluster/global\
    \ precedence. The closest related tasks (EXOCOMP-28, EXOCOMP-33) address service\
    \ recovery and fault injection but not journal cleanup. EXOCOMP-232 describes\
    \ a unique, novel scope with no equivalent in the task graph provided.\nI am investigating\
    \ whether EXOCOMP-232 is a duplicate of an existing task. Let me review the task\
    \ corpus systematically.\n\n**Understanding the Current Task (EXOCOMP-232):**\n\
    - Title: \"Migrate journal vacuum to the broker\"\n- Description: Replace direct\
    \ `sudo journalctl vacuum` execution with a node-scoped broker action\n- Key scope:\
    \ Journal vacuum (systemd journal cleanup) as a broker action, with node/cluster/global\
    \ precedence resolution\n- Status: Open (not terminal)\n\n**Searching the Provided\
    \ Task Corpus:**\n\nI'll look for tasks that might address the same journal vacuum\
    \ / journalctl cleanup scope:\n\n- **EXOCOMP-10-16**: Linux diagnostics, llama.cpp,\
    \ A2A services, DNS discovery, coordinator PKI \u2014 none mention journal vacuum\n\
    - **EXOCOMP-100-107**: Volatile task stores, orchestration, cancellation, audit,\
    \ restart recovery \u2014 diagnostic/coordinator infrastructure, no journal operations\n\
    - **EXOCOMP-11-13**: Node supervision, A2A service exposure, M1 verification \u2014\
    \ no journal operations\n- **EXOCOMP-111-123**: Recovery work, M5 benchmarks,\
    \ M6 release qualification \u2014 no journal cleanup\n\nSearching by keyword across\
    \ all task descriptions:\n- \"journal\": No matches in task descriptions (only\
    \ in this task)\n- \"vacuum\": No matches in other tasks\n- \"journalctl\": No\
    \ matches in other tasks\n- \"cleanup\": Appears in EXOCOMP-28 (M3 acceptance)\
    \ but refers to test cleanup, not journal operations\n\n**Status Check of Candidates:**\n\
    All tasks in the corpus that might be tangentially related (EXOCOMP-28, EXOCOMP-33,\
    \ EXOCOMP-30) are in terminal states (Archived) and describe different scopes\
    \ (service recovery, fault injection, state machines).\n\n**Coordination Data\
    \ Review:**\nThe task corpus notes this is part of epic EXOCOMP-211 with peer\
    \ tasks EXOCOMP-127, 225-234. These tasks are not in the provided corpus (higher-numbered),\
    \ so I cannot assess them. The provided corpus is authoritative per instructions,\
    \ and within it, no match exists.\n\n---\n\n**Focus handoff: duplicate_detector**\n\
    \n**Duplicate preflight"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 530dc570-1d30-4a03-a2e1-c5715af5d86b
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-232
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-232
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:45:32.343227+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 1780
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 1780
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 1780
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:46:54.021263+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-232__20260803T154535Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-232
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:46:54.030896+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Replace direct sudo journalctl vacuum execution with a node-scoped broker action.

Acceptance criteria:
- Resolve node, cluster, global, then implicit observe because journal vacuum has no service key.
- Preserve installed vacuum-size bounds, filesystem preconditions, approval rules, idempotency, audit, and verification.
- Caller input cannot select a path, executable, vacuum size, or argument.
- Observe denial starts no journalctl process.
- Existing direct journalctl sudo and executor paths are removed.

Tests: Port bounded-cleanup tests and add node/cluster/global precedence, observe default, permit mismatch, bounds, unsafe filesystem state, direct-path rejection, and installer privilege assertions; run make test, make test-integration, make fmt-check, and make lint.

Out of scope: Service restart and cluster-profile actions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:45
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:45
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:46
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 2, Tool calls: 0
- Tokens: 10 in / 1.8K out [1.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 27s
- Log: EXOCOMP-232__20260803T154535Z.jsonl
---
<!-- COMMENTS:END -->
