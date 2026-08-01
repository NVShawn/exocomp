---
id: EXOCOMP-176
type: task
status: In Progress
priority: 1
title: Package the Mission Control release and OCI image
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-136
- EXOCOMP-137
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:18:27.819781Z'
updated_at: '2026-08-01T13:11:29.216824Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-176
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 4a6f8158709e1ee2895f9ef8fd058289fc251a62fe0f746557d674cc2bb84598
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:11:05.945025+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active task records for EXOCOMP-135, 136, 137, 177, 178, 184,
    and 202. EXOCOMP-135 is the parent epic; 178 is documentation, 184 is downstream
    qualification, and 136/137 are application/database foundations with packaging
    explicitly out of scope. Historical merged tasks EXOCOMP-66, 44, 67, 68, 114,
    and 115 cover prior M6 node/coordinator artifacts, not this active Mission Control
    packaging task.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 0da8f466-fed8-443f-9132-80271fe7a18f
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-176
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-176
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:11:27.164487+00:00'
oompah.task_costs:
  total_input_tokens: 1157401
  total_output_tokens: 4784
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 1157401
      output_tokens: 4784
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 1157401
    output_tokens: 4784
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:11:05.938373+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-176__20260801T130906Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-176
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:11:05.995656+00:00'
---
## Summary

Plan: plans/mission-control.md, Deployment and Operations.

Deliverables:
- Add a production Mission Control OTP release and reproducible OCI image using the repository pinned builder conventions.
- Provide explicit noninteractive database migrate and server commands.
- Run as an unprivileged user with a read-only root filesystem except documented state paths.
- Add manifest, checksum, SBOM, provenance, and license coverage.

Acceptance:
- Packaging tests start the image against PostgreSQL, run migrations once, restart safely, reject missing secrets, and inspect runtime dependencies.
- No build tools, source tree, credentials, or test fixtures are shipped.

Out of scope: Kubernetes manifests and final qualification.
Quality gate: focused packaging tests plus repository release-check targets.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:08
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:09
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:11
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 34
- Tokens: 1.2M in / 4.8K out [1.2M total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 9s
- Log: EXOCOMP-176__20260801T130906Z.jsonl
---
author: oompah
created: 2026-08-01 13:11
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 13:11
---
Focus: DevOps Engineer
---
<!-- COMMENTS:END -->
