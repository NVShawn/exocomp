---
id: EXOCOMP-69
type: task
status: Backlog
priority: null
title: Create crashable fixture service script with health endpoint and state controls
parent: EXOCOMP-29
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T21:06:29.970644Z'
updated_at: '2026-07-23T21:06:29.970644Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Implement the fixture service daemon (bash or Python) for the M4 systemd recovery fixture. The service must:

- Run as a long-lived daemon suitable for use as a systemd ExecStart target
- Serve a minimal HTTP health endpoint on a configurable localhost port (e.g. 127.0.0.1:8877) that returns JSON {"status": "ok"} or {"status": "degraded"} independently of the systemd process state
- Write and maintain a harmless workload marker file (e.g. /run/exocomp-fixture/workload.marker) that proves the service is actively running
- Accept a control signal or file-based trigger to enter one of these modes: active (healthy, normal), failed (exits nonzero), degraded (running but health endpoint returns unhealthy), flapping (restarts repeatedly), restart-failure (ExecStart exits immediately each time, exhausting StartLimitBurst)
- Health endpoint must be able to report unhealthy while the systemd unit is still active (process alive but health bad), satisfying the acceptance criterion that health can disagree with systemd active state

Place the service under test/fixtures/exocomp_fixture/bin/exocomp-fixture (executable script).

Reference: plans/milestone-4-service-recovery.md, section 'Reference Fixture'. This is a prerequisite for the unit file / installer task and the ExUnit test task.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

