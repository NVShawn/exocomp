---
id: EXOCOMP-184
type: task
status: Open
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
updated_at: '2026-08-01T13:23:59.701891Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-184
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 9f504d9488343565c1d4160688e3f0750bcb838ef6ef002b4199224a5f54c000
  detector_version: duplicate-detector-v1
  verdict: inconclusive
  checked_at: null
  matched_identifiers: []
  evidence: ''
  claim_id: d8566f85-fde8-4631-8684-c1232b566704
  claim_owner: 7946c223-6c24-4967-8291-1d20c0e47f05
  claimed_at: '2026-08-01T13:23:49.081851+00:00'
  claim_expires_at: '2026-08-01T13:53:49.081851+00:00'
  retry_count: 0
  retry_after: null
oompah.agent_run_id: e44592b2-d732-4aab-a800-f13e5f1d14b1
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-184
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-184
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:23:56.528587+00:00'
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
<!-- COMMENTS:END -->
