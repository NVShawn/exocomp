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
updated_at: '2026-07-23T21:33:04.030543Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 6a963341-169b-4078-b74a-fea0146bbb2d
oompah.work_branch: epic-EXOCOMP-4
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
<!-- COMMENTS:END -->
