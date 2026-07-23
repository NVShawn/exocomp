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
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T21:06:51.547848Z'
updated_at: '2026-07-23T21:38:53.311126Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 7af677f7-d6f3-4584-9f87-f998daccca84
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 1496164
  total_output_tokens: 9809
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1496164
      output_tokens: 9809
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
  - profile: deep
    model: unknown
    input_tokens: 668799
    output_tokens: 4556
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:38:42.202487+00:00'
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
author: oompah
created: 2026-07-23 21:36
---
Retrying (attempt #2, agent: deep)
---
author: oompah
created: 2026-07-23 21:36
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:38
---
Understanding (duplicate screening): EXOCOMP-71 is the focused ExUnit/systemd integration-test slice of parent EXOCOMP-29. I will compare its complete scope and comments with the parent and sibling fixture tasks, then either archive a confirmed duplicate or hand off to test implementation without changing code.
---
author: oompah
created: 2026-07-23 21:38
---
Focus handoff: duplicate_detector

Outcome: No duplicate found. EXOCOMP-71 is the unique integration-test child of EXOCOMP-29 and should proceed to test implementation.

Evidence: Searched the complete tracker state and repository plans/docs for systemd fixture, integration test, restart-failure, and health/systemd divergence. Read EXOCOMP-29, EXOCOMP-69, EXOCOMP-70, EXOCOMP-71, and EXOCOMP-72 descriptions and comments. EXOCOMP-29 explicitly decomposes into EXOCOMP-69 (daemon), EXOCOMP-70 (unit/installer/cleanup), EXOCOMP-71 (10-scenario ExUnit integration suite), and EXOCOMP-72 (environment documentation). EXOCOMP-69 Python tests exercise the daemon without systemd; they do not cover real systemctl behavior. EXOCOMP-70 tests script syntax and daemon tests; it explicitly leaves real systemd integration to EXOCOMP-71. EXOCOMP-72 documents how to run future tests but contains no test implementation. No other task or branch contains test/integration/fixture_test.exs or equivalent.

Relevant files: test/fixtures/exocomp_fixture/bin/exocomp-fixture; test/fixtures/exocomp_fixture/exocomp-fixture.service, install.sh, cleanup.sh (present on origin/EXOCOMP-70 but not yet merged into current origin/main); test/fixtures/exocomp_fixture/test/test_fixture.py; docs/testing-systemd-fixture.md; plans/milestone-4-service-recovery.md; Makefile.

Remaining work/risks: First ensure EXOCOMP-70 is merged or base the implementation on its committed deliverables. Add tagged ExUnit integration coverage for all 10 required scenarios, an opt-in tag filter, and a Make target/documentation alignment. Real verification requires a VM or privileged container running systemd. Check naming drift in docs (systemd_fixture/exocomp_fixture) against the implemented dash-named unit exocomp-fixture.service. The current worktree is on epic-EXOCOMP-29 despite task metadata naming epic-EXOCOMP-4, so the implementation agent must create/use the actual EXOCOMP-71 issue branch before committing.

Recommended next focus: test.
---
author: oompah
created: 2026-07-23 21:38
---
Agent completed successfully in 126s (673355 tokens)
---
author: oompah
created: 2026-07-23 21:38
---
Run #3 [attempt=3, profile=deep, role=deep -> Codex/default]
- Turns: 1, Tool calls: 11
- Tokens: 668.8K in / 4.6K out [673.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 6s
- Log: EXOCOMP-71__20260723T213638Z.jsonl
---
author: oompah
created: 2026-07-23 21:38
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 21:38
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:38
---
Focus: Refactoring Specialist
---
<!-- COMMENTS:END -->
