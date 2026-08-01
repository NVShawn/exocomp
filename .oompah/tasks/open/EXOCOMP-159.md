---
id: EXOCOMP-159
type: task
status: Open
priority: 1
title: Implement the coordinator exocomp.cluster.chat skill
parent: EXOCOMP-132
children: []
blocked_by:
- EXOCOMP-145
- EXOCOMP-139
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:16:17.558974Z'
updated_at: '2026-08-01T12:36:55.863087Z'
work_branch: epic-EXOCOMP-132--task-EXOCOMP-159
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 08c25940ce751cca2648d6e0ea31d3752d9b48a646b57a15a0dab31445053147
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: c0845bc6-99f4-42d9-a685-861c08420d8f
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T12:36:47.627828+00:00'
  claim_expires_at: '2026-08-01T13:06:47.627828+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 50e5a119-6a86-4adc-896c-257db19552d0
oompah.work_branch: epic-EXOCOMP-132--task-EXOCOMP-159
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-132--task-EXOCOMP-159
  base_branch: epic-EXOCOMP-132
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T12:36:53.657133+00:00'
---
## Summary

Plan: plans/mission-control.md, Conversations and Cluster-Local Reasoning.

Deliverables:
- Add exocomp.cluster.chat to the coordinator Agent Card and A2A dispatcher.
- Build bounded model input from the fixed system prompt, recent thread context, and fresh typed diagnostics.
- Call the configured local OpenAI-compatible inference endpoint.
- Validate schema-constrained output containing Markdown, evidence citations, and at most one typed proposal.

Acceptance:
- Tests cover valid reply, no model configured, timeout, invalid/truncated schema, stale evidence, missing citation, oversized context, and model crash.
- The skill exposes no arbitrary command or file access.

Out of scope: Mission Control persistence and executing proposals.
Quality gate: focused coordinator/A2A tests plus make test, make fmt-check, and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 12:36
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 12:36
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
