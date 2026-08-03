---
id: EXOCOMP-231
type: task
status: Open
priority: 1
title: Migrate systemd service restart to the broker
parent: EXOCOMP-211
children: []
blocked_by: []
start_blocked_by: &id001
- EXOCOMP-127
- EXOCOMP-229
- EXOCOMP-230
labels: []
assignee: null
created_at: '2026-08-03T14:26:35.002542Z'
updated_at: '2026-08-03T15:45:51.022940Z'
work_branch: epic-EXOCOMP-211--task-EXOCOMP-231
target_branch: null
review_url: null
review_number: null
review_head: null
merged_at: null
oompah.start_blocked_by: *id001
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 850548fff0dcd4804922b55b28e079b9a2be9875b6ba9ecd60157b4984075829
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-03T15:45:47.796711+00:00'
  matched_identifiers: []
  evidence: "Focus handoff: duplicate_detector\nDuplicate preflight verdict: no_duplicate\n\
    Matches: none\nEvidence: The current project task corpus (authoritative, scope:\
    \ current project tracker) contains no active (non-terminal) tasks with scope\
    \ overlapping EXOCOMP-231. All visible tasks are in terminal states (Archived,\
    \ Merged, Done). Keyword scan for \"broker\", \"systemctl restart\", \"service\
    \ restart\", and \"remediation executor\" found no matching active task. The epic\
    \ parent (EXOCOMP-211) and sibling tasks (EXOCOMP-225-234) identified in coordination\
    \ metadata are absent from the provided corpus and therefore cannot be evaluated.\
    \ Among tasks present, EXOCOMP-10 and EXOCOMP-31 are closest topically but are\
    \ either focused on diagnostics (EXOCOMP-10) or failed-service recovery (EXOCOMP-31),\
    \ distinct from broker-based restart migration.\n**Searching task corpus for duplicates:**\n\
    \n1. **Scope analysis**: EXOCOMP-231 targets broker-based service-restart migration\
    \ with policy checks and systemd integration. \n2. **Keyword scan**: Searched\
    \ corpus for \"broker\", \"systemctl restart\", \"service restart\", \"remediation\
    \ executor\"\n3. **Terminal task exclusion**: All visible tasks in the corpus\
    \ are in terminal states (Archived, Merged, Done)\n4. **Active task check**: No\
    \ other Open, Backlog, or Proposed tasks found with overlapping scope\n\n**Findings:**\n\
    - EXOCOMP-10 (diagnostic collectors) is Archived \u2014 unrelated scope (diagnostics\
    \ vs. restart execution)\n- EXOCOMP-31 (failed-service recovery, referenced in\
    \ EXOCOMP-115 notes) \u2014 Needs Human status, different scope (recovery vs.\
    \ migration)\n- No task in the visible corpus describes broker-based service restart\
    \ migration\n\n**Limitation noted**: The task corpus omits EXOCOMP-211 (epic parent)\
    \ and EXOCOMP-225-234 (listed siblings), which cannot be evaluated against the\
    \ authoritative corpus provided.\n\n---\n\n**Focus handoff: duplicate_detector**\n\
    \n**Duplicate preflight verdict: no_duplicate**\n\n**Matches: none**\n\nEvidence:\
    \ The current project task corpus (authoritative, scope: current project tracker)\
    \ contains no active (non-terminal) tasks with scope overlapping EXOCOMP-231.\
    \ All visible tasks are in terminal states (Archived, Merged, Done). Keyword scan\
    \ for \"broker\", \"systemctl restart\", \"service restart\", and \"remediation\
    \ executor\" found no matching active task. The epic parent (EXOCOMP-211) and\
    \ sibling tasks (EXOCOMP-225-234) identified in coordination metadata are absent\
    \ from the provided corpus and therefore cannot be evaluated. Among tasks present,\
    \ EXOCOMP-10 and EXOCOMP-31 are closest topically but are either focused on diagnostics\
    \ (EXOCOMP-10) or failed-service recovery (EXOCOMP-31), distinct from broker-based\
    \ restart migration."
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
  owner_resolved_at: null
  owner_login: null
  owner_resolution_reason: ''
oompah.agent_run_id: 2c073aee-e70d-4ab0-924c-9a9e65dd8f93
oompah.work_branch: epic-EXOCOMP-211--task-EXOCOMP-231
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-211--task-EXOCOMP-231
  base_branch: epic-EXOCOMP-211
  base_sha: 4e01311060eee5be3c1d18d86d809f4007664497
  updated_at: '2026-08-03T15:44:10.045515+00:00'
oompah.task_costs:
  total_input_tokens: 10
  total_output_tokens: 2892
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 10
      output_tokens: 2892
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 10
    output_tokens: 2892
    cost_usd: 0.0
    recorded_at: '2026-08-03T15:45:47.795774+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-231__20260803T154419Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-211--task-EXOCOMP-231
    source_sha: 4e01311060eee5be3c1d18d86d809f4007664497
    completed_at: '2026-08-03T15:45:47.821625+00:00'
---
## Summary

Plan: plans/hierarchical-management-modes.md

Deliverable: Replace direct sudo systemctl restart execution with the broker service-restart adapter.

Acceptance criteria:
- Adapter accepts only exact validated and installed allow-listed service units.
- Broker rechecks policy manage, failed/live-state policy, permit, lock, idempotency, and fixed systemctl argv immediately before execution.
- Existing automatic failed-service and approved live-service workflows retain their evidence, one-attempt, cooldown, and verification behavior.
- Observe denial produces no systemctl process.
- Existing direct executor entry is removed after migration.

Tests: Port existing recovery tests and add all five policy scopes, peer conflict, observe default, permit mismatch, action race, direct-path rejection, and shipped systemd integration coverage; run make test, make test-integration, make fmt-check, and make lint.

Out of scope: Journal vacuum and profile actions.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-03 15:44
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-03 15:44
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-03 15:45
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 4, Tool calls: 0
- Tokens: 10 in / 2.9K out [2.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 42s
- Log: EXOCOMP-231__20260803T154419Z.jsonl
---
<!-- COMMENTS:END -->
