---
id: EXOCOMP-71
type: task
status: In Review
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
updated_at: '2026-07-23T21:52:01.949400Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: ff873ad8-d2de-435c-b420-02be8050bc31
oompah.work_branch: epic-EXOCOMP-4
oompah.task_costs:
  total_input_tokens: 1496208
  total_output_tokens: 43535
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1496208
      output_tokens: 43535
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
  - profile: default
    model: unknown
    input_tokens: 44
    output_tokens: 33726
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:49:19.410877+00:00'
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
author: oompah
created: 2026-07-23 21:44
---
Understanding: This task requires writing 10 ExUnit integration test cases for the exocomp-fixture systemd service (from EXOCOMP-69/70). The previous agent dispatches were duplicate investigators who confirmed no duplicate exists; now I need to actually write the tests.

Plan:
1. Create EXOCOMP-71 branch from current HEAD (epic-EXOCOMP-29 = main)
2. Cherry-pick EXOCOMP-70 commit (a93685d) to include install.sh/cleanup.sh/service file
3. Write apps/exocomp_node/test/integration/fixture_test.exs with all 10 test cases tagged @moduletag :integration and @moduletag :systemd
4. Update apps/exocomp_node/test/test_helper.exs to exclude integration tags by default
5. Add fixture-install, fixture-cleanup, and test-integration Makefile targets
6. Commit and push EXOCOMP-71 branch

Key constraints: tests require root + systemd, use System.cmd for systemctl/curl/bash calls, no extra Elixir deps needed. Tag filter ensures standard CI is unaffected.
---
author: oompah
created: 2026-07-23 21:45
---
Discovery: Explored the codebase and found all the pieces needed to write the integration tests.

Key findings:
- exocomp-fixture daemon: test/fixtures/exocomp_fixture/bin/exocomp-fixture (Python 3, HTTP health endpoint on port 8877, mode file at /run/exocomp-fixture/mode)
- install.sh / cleanup.sh / .service file: available on origin/EXOCOMP-70 (cherry-picked to EXOCOMP-71 branch)
- Service: exocomp-fixture.service with Restart=on-failure, RestartSec=1s, StartLimitBurst=3 (within 30s)
- Elixir umbrella: apps/exocomp_node, apps/exocomp_core, apps/exocomp_coordinator - tests go in apps/exocomp_node/test/integration/
- Existing test_helper.exs: ExUnit.start() - needs tag exclude filter added
- No Jason/HTTPoison deps - will use System.cmd(curl) for health checks and System.cmd(systemctl) for service state
- docs/testing-systemd-fixture.md already documents the environment setup
- Makefile currently has test and test-fixture-service targets but lacks fixture-install, fixture-cleanup, and test-integration

Writing: apps/exocomp_node/test/integration/fixture_test.exs with all 10 required test scenarios.
---
author: oompah
created: 2026-07-23 21:48
---
Implementation: Created all required files on branch EXOCOMP-71.

Files added/modified:
1. apps/exocomp_node/test/integration/fixture_test.exs (NEW, 498 lines)
   - Module: Exocomp.Integration.FixtureTest
   - @moduletag :integration + @moduletag :systemd on all 10 tests
   - setup block: snapshots non-fixture services, calls install.sh, registers on_exit cleanup
   - All 10 required test cases with clear assertions and polling helpers
   - Uses System.cmd(systemctl/bash/curl) — zero added Elixir dependencies
   - Path to fixture scripts resolved at compile time via __DIR__ (4 levels up to project root)

2. apps/exocomp_node/test/test_helper.exs (MODIFIED)
   - Changed ExUnit.start() → ExUnit.start(exclude: [:integration, :systemd])
   - Standard CI is now safe: integration tests are excluded by default

3. Makefile (MODIFIED)
   - fixture-install: runs test/fixtures/exocomp_fixture/install.sh
   - fixture-cleanup: runs test/fixtures/exocomp_fixture/cleanup.sh
   - test-integration: MIX_ENV=test mix test --only integration apps/exocomp_node/test/integration/
   - Removed duplicate entries introduced by cherry-pick of EXOCOMP-70 commit

Branch also cherry-picked EXOCOMP-70 commit (a93685d) to include install.sh, cleanup.sh, and .service file that the tests depend on.
---
author: oompah
created: 2026-07-23 21:48
---
Verification: Standard CI tests pass; integration tests correctly excluded by tag filter.

Verified:
- make test-fixture-service: 22/22 Python daemon tests PASS (no regressions from Makefile/test_helper changes)
- git log confirms EXOCOMP-71 branch has 2 new commits on top of main:
    62d0171  EXOCOMP-70: cherry-pick (install.sh, cleanup.sh, .service)
    f6bebb2  EXOCOMP-71: integration test suite + Makefile targets
- make help shows all 3 new targets (fixture-install, fixture-cleanup, test-integration) with no duplicates
- Integration tests require systemd — they cannot be run in the current environment. They are correctly tagged to be excluded from standard CI.

To run the integration tests (requires privileged container or VM with systemd):
  make fixture-install   # as root
  make test-integration
---
author: oompah
created: 2026-07-23 21:48
---
Completion: EXOCOMP-71 integration test suite delivered on branch EXOCOMP-71.

Delivered:
- apps/exocomp_node/test/integration/fixture_test.exs — 10 ExUnit integration tests covering all required fixture states: install, start/stop, crash, degrade, flap, restart-failure, cleanup, health/systemd divergence, idempotent setup, non-fixture isolation
- apps/exocomp_node/test/test_helper.exs — updated to exclude :integration/:systemd by default so standard CI is unaffected
- Makefile — 3 new targets: fixture-install, fixture-cleanup, test-integration

All tests are tagged @moduletag :integration and @moduletag :systemd. Run with:
  make fixture-install && make test-integration
(inside a VM or privileged container with systemd as PID 1)

Branch EXOCOMP-71 pushed to origin. Also includes cherry-pick of EXOCOMP-70's commit to keep the branch self-contained until EXOCOMP-70 is merged.
---
author: oompah
created: 2026-07-23 21:49
---
Wrote all 10 ExUnit integration tests for exocomp-fixture systemd states (install, start/stop, crash, degrade, flap, restart-failure, cleanup, health divergence, idempotent setup, non-fixture isolation). Added fixture-install, fixture-cleanup, and test-integration Makefile targets. Updated test_helper.exs to exclude integration tests from standard CI. Branch EXOCOMP-71 pushed to origin.
---
author: oompah
created: 2026-07-23 21:49
---
Agent completed successfully in 629s (33770 tokens)
---
author: oompah
created: 2026-07-23 21:49
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/default]
- Turns: 82, Tool calls: 57
- Tokens: 44 in / 33.7K out [33.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 10m 29s
- Log: EXOCOMP-71__20260723T213853Z.jsonl
---
author: oompah
created: 2026-07-23 21:49
---
Close refused by orchestrator: branch `epic-EXOCOMP-4` has 1 commit not on `main` and no open PR targets `main` from this branch.

Diagnostic:
  Unmerged commits: 1
    5096f79 EXOCOMP-29: Add fixture design document and decompose into child tasks
  Open PRs from this branch: 0
  Merged PRs from this branch: 0

Required: open a PR before closing.
  gh pr create --base main --head epic-EXOCOMP-4 --title "EXOCOMP-71: Write focused ExUnit integration tests for all fixture states" --body "..."

Task reopened. Re-dispatch on the next tick will see this comment in its prompt context.
---
author: oompah
created: 2026-07-23 21:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:49
---
Focus: Refactoring Specialist
---
<!-- COMMENTS:END -->
