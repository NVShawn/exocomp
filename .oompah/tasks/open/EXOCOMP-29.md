---
id: EXOCOMP-29
type: feature
status: Open
priority: 1
title: Create the isolated systemd recovery fixture
parent: EXOCOMP-4
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T19:10:45.456680Z'
updated_at: '2026-07-23T20:51:59.930727Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 4514a72e-3f35-4b5b-9157-13a29210cdb3
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 1553836
  total_output_tokens: 15029
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1553836
      output_tokens: 15029
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 542271
    output_tokens: 4809
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:35:59.035047+00:00'
  - profile: standard
    model: unknown
    input_tokens: 1011513
    output_tokens: 8336
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:40:57.716174+00:00'
  - profile: default
    model: unknown
    input_tokens: 52
    output_tokens: 1884
    cost_usd: 0.0
    recorded_at: '2026-07-23T20:51:58.540368+00:00'
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
author: oompah
created: 2026-07-23 20:37
---
Retrying (attempt #3, agent: standard)
---
author: oompah
created: 2026-07-23 20:37
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:40
---
Agent completed successfully in 217s (1019849 tokens)
---
author: oompah
created: 2026-07-23 20:40
---
Run #4 [attempt=4, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 33
- Tokens: 1.0M in / 8.3K out [1.0M total]
- Cost: $0.0000
- Exit: normal, Duration: 3m 37s
- Log: EXOCOMP-29__20260723T203722Z.jsonl
---
author: oompah
created: 2026-07-23 20:41
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-4`. Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
author: oompah
created: 2026-07-23 20:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:49
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 20:51
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 0, Tool calls: 33
- Tokens: 52 in / 1.9K out [1.9K total]
- Cost: $0.0000
- Exit: terminated, Duration: 2m 3s
- Log: EXOCOMP-29__20260723T204957Z.jsonl
---
<!-- COMMENTS:END -->
