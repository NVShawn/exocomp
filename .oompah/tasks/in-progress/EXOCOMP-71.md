---
id: EXOCOMP-71
type: task
status: In Progress
priority: null
title: Write focused ExUnit integration tests for all fixture states
parent: EXOCOMP-29
children: []
blocked_by:
- EXOCOMP-69
- EXOCOMP-70
labels: []
assignee: null
created_at: '2026-07-23T21:06:51.547848Z'
updated_at: '2026-07-23T21:36:09.121588Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 56c26e55-fba9-4744-bc7a-cc08f3c4208f
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 827365
  total_output_tokens: 5253
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 827365
      output_tokens: 5253
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 403308
    output_tokens: 2442
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:34:21.963443+00:00'
  - profile: standard
    model: unknown
    input_tokens: 424057
    output_tokens: 2811
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:36:06.713530+00:00'
---
## Summary

Write ExUnit integration tests that exercise the systemd fixture service (EXOCOMP-69 + EXOCOMP-70) through all required scenarios. These tests require a VM or privileged container with systemd.

Test module: test/integration/fixture_test.exs (or an appropriate location under the Elixir umbrella scaffolded by EXOCOMP-7).

Required test cases:
1. install: fixture installs cleanly and service reaches active state
2. start/stop: service can be stopped and restarted via systemctl
3. crash: fixture enters failed state on demand; systemd reports failed
4. degrade: fixture enters degraded mode; systemd shows active but health endpoint returns unhealthy
5. flap: fixture flapping mode causes repeated restart events visible to systemctl
6. restart-failure: fixture exhausts StartLimitBurst; systemd reports failed/restart-failure
7. cleanup: cleanup.sh leaves no fixture files or units; non-fixture services untouched
8. health vs systemd divergence: explicitly assert health endpoint can disagree with systemctl is-active
9. repeated fixture setup: idempotent install+cleanup cycle succeeds multiple times
10. non-fixture isolation: verify no non-fixture services or files were modified

Tag these tests with @tag :systemd or @tag :integration and add an ExUnit.Case tag filter so they only run in the appropriate CI environment. Document how to run them (make test-integration or similar target).

Depends on: EXOCOMP-69 (service script) and EXOCOMP-70 (installer/cleanup). Reference: plans/milestone-4-service-recovery.md acceptance criteria.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:33
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:33
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:34
---
Agent completed successfully in 81s (405750 tokens)
---
author: oompah
created: 2026-07-23 21:34
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 10
- Tokens: 403.3K in / 2.4K out [405.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 21s
- Log: EXOCOMP-71__20260723T213304Z.jsonl
---
author: oompah
created: 2026-07-23 21:34
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-29`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:34
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:34
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:36
---
Agent completed successfully in 88s (426868 tokens)
---
author: oompah
created: 2026-07-23 21:36
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 8
- Tokens: 424.1K in / 2.8K out [426.9K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 28s
- Log: EXOCOMP-71__20260723T213441Z.jsonl
---
author: oompah
created: 2026-07-23 21:36
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-29`. Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
<!-- COMMENTS:END -->
