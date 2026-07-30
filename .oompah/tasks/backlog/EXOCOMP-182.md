---
id: EXOCOMP-182
type: task
status: Backlog
priority: 1
title: Build the two-cluster Mission Control qualification scenario
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-169
- EXOCOMP-173
- EXOCOMP-180
- EXOCOMP-181
start_blocked_by: &id001
- EXOCOMP-206
labels: []
assignee: null
created_at: '2026-07-30T14:18:50.264411Z'
updated_at: '2026-07-30T21:41:30.427673Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.start_blocked_by: *id001
---
## Summary

Plan: plans/mission-control.md, Test Strategy.

Deliverables:
- Automate the planned two-cluster scenario: connect and report nodes; open/deduplicate a failed-service incident; converse with the cluster-local model; receive a cited typed proposal; approve once; revalidate, execute once, verify, and report the audit timeline.
- Force disconnect/reconnect during the scenario.
- Capture machine-readable results and raw evidence.

Acceptance:
- No duplicate incident, message, approval, or execution appears.
- Every timeline item shares the expected correlation chain.
- Failure at any step exits nonzero with the failed phase and retained evidence path.

Out of scope: 100-cluster load and release publication.
Quality gate: a dedicated noninteractive Make qualification target.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 21:41
---
Desired-state extension acceptance: incorporate the VM-qualified EXOCOMP-206 path so the two-cluster scenario includes composed service expectations, one coordinator-declared Ceph profile, a deduplicated failed-daemon incident, exactly-once safe restart, stable verification, and reconnect replay.
---
<!-- COMMENTS:END -->
