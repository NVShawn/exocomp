---
id: EXOCOMP-121
type: bug
status: In Progress
priority: 2
title: Make cross-architecture tests robust under full-system arm64 execution
parent: EXOCOMP-117
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-26T03:58:33.822377Z'
updated_at: '2026-07-26T05:19:43.191102Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Context
The exact v0.1.0-rc.2 arm64 suite failed Bench.HostSamplerTest while waiting five seconds for a synthetic child readiness line and HealthPollerTest while waiting only 100 ms for crash-isolated capacity reuse. The same functionality passes on amd64. Full-system QEMU is accepted for qualification, so tests must distinguish real semantic failures from scheduler latency without weakening behavior.

Implementation
Replace brittle wall-clock message assumptions with deterministic synchronization or bounded eventually helpers tied to observable state. Preserve the semantic assertions: host sampling detects real CPU and RSS growth, and resolver or probe crashes release capacity so the next node is probed exactly as intended. Keep production timeouts unchanged unless evidence proves a production bug.

Testing
Add regression coverage that delays child readiness and resolver or probe completion beyond the former constants while proving eventual progress and bounded failure. Run the focused bench and coordinator tests repeatedly and run make test in the arm64 full-system guest.

Acceptance Criteria
- Both previously failing tests pass reliably on amd64 and full-system arm64.
- Tests still fail when readiness never occurs or capacity is never released.
- No production safety timeout is relaxed merely to accommodate emulation.
- Focused stress repetitions and make test pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

