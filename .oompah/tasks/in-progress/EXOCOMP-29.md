---
id: EXOCOMP-29
type: feature
status: In Progress
priority: 1
title: Create the isolated systemd recovery fixture
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T19:10:45.456680Z'
updated_at: '2026-07-23T20:36:02.027842Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 8cb8f676-1608-4574-8fc1-79bcfe30bfc3
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 542271
  total_output_tokens: 4809
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 542271
      output_tokens: 4809
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 542271
    output_tokens: 4809
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:35:59.035047+00:00'
---
## Summary

Plan: [Milestone 4 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-4-service-recovery.md)

Goal
Create the isolated systemd recovery fixture.

Implementation
Add an intentionally crashable fixture systemd service with an application health endpoint, harmless workload marker, active/failed/degraded/flapping/restart-failure controls, disposable installer, and cleanup limited to fixture resources; document VM or privileged-container requirements.

Testing
Test install/start/stop/crash/degrade/flap/restart-failure/cleanup, health versus systemd state, repeated fixture setup, and proof that non-fixture services/files are untouched.

Acceptance Criteria
- [ ] Every required service state is reproducible.
- [ ] Health can disagree with systemd active state.
- [ ] Fixture setup and cleanup are idempotent and scoped.
- [ ] Focused fixture tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:24
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:24
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:33
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:33
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:35
---
Agent completed successfully in 132s (547080 tokens)
---
author: oompah
created: 2026-07-23 20:36
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 11
- Tokens: 542.3K in / 4.8K out [547.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 12s
- Log: EXOCOMP-29__20260723T203348Z.jsonl
---
author: oompah
created: 2026-07-23 20:36
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-4`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
<!-- COMMENTS:END -->
