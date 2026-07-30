---
id: EXOCOMP-127
type: epic
status: Backlog
priority: 1
title: 'M7: Exocomp Mission Control'
parent: null
children:
- EXOCOMP-128
- EXOCOMP-129
- EXOCOMP-130
- EXOCOMP-131
- EXOCOMP-132
- EXOCOMP-133
- EXOCOMP-134
- EXOCOMP-135
- EXOCOMP-185
- EXOCOMP-186
blocked_by: []
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:12:14.308143Z'
updated_at: '2026-07-30T21:35:55.686265Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: plans/mission-control.md

Outcome: Implement the optional self-hosted Mission Control plane for up to 100 Exocomp clusters and 10,000 nodes. Coordinators connect outbound over mTLS, report status and alerts, participate in evidence-linked conversations, and execute only typed remedies that pass cluster-local policy after operator approval.

Required invariants:
- Mission Control remains optional; clusters continue local operation during outages.
- Organization scoping is mandatory on tenant-owned records.
- Mission Control never holds cluster approval-signing keys or exposes arbitrary command execution.
- Delivery is durable and idempotent across reconnects and replica changes.
- All 12 M7 acceptance criteria in the plan must pass.

Implementation is decomposed into area epics. Each child task is sized as one focused pull request and must include focused tests and the relevant Make quality gates.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-30 14:25
---
Mission Control implementation graph created from plans/mission-control.md.

Structure:
- 1 umbrella epic (EXOCOMP-127)
- 8 area epics (EXOCOMP-128 through EXOCOMP-135)
- 49 junior-scoped implementation tasks (EXOCOMP-136 through EXOCOMP-184)
- 139 explicit dependency edges

Each implementation task defines one focused deliverable, acceptance tests, out-of-scope boundaries, and Make quality gates. The graph was validated for complete parentage, existing dependency targets, required task sections, and cycles; validation reported zero errors. All items remain in Backlog so implementation does not start automatically. The first implementation task is EXOCOMP-136, which scaffolds the isolated Mission Control Phoenix application.
---
<!-- COMMENTS:END -->
