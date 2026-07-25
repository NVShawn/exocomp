---
id: EXOCOMP-113
type: chore
status: In Progress
priority: 1
title: Recover omitted M3 and M4 acceptance and fault-injection work
parent: EXOCOMP-110
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-25T17:58:22.004834Z'
updated_at: '2026-07-25T18:55:22.424666Z'
work_branch: epic-EXOCOMP-110
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 90f13d7b-9c96-4cc8-80e7-815b257b1a98
oompah.work_branch: epic-EXOCOMP-110
---
## Summary

Recover the task-specific changes from EXOCOMP-28 and EXOCOMP-33 onto the EXOCOMP-110 shared recovery branch based on current main. Integrate M3 criterion evidence tests, the complete recovery fault-injection suite, and the EXOCOMP-33 state-restore and approval-gate security fixes without regressing later main changes. Run focused and full Make quality gates and verify all recovered scenarios.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 18:53
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-25 18:53
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-25 18:53
---
Understanding: As Duplicate Investigator, I'm screening EXOCOMP-113 before any implementation. The task asks to recover M3/M4 acceptance tests and fault-injection work from EXOCOMP-28 and EXOCOMP-33 onto the EXOCOMP-110 epic branch. I will search for any existing tasks covering the same recovery work before proceeding.
---
author: oompah
created: 2026-07-25 18:55
---
Discovery: Duplicate screening found NO duplicate. EXOCOMP-113 is the unique, dedicated recovery task for M3 and M4 deliverables from EXOCOMP-28 and EXOCOMP-33 within the EXOCOMP-110 epic.

Tasks reviewed as candidates:
- EXOCOMP-28 (Needs Human): SOURCE task — M3 safety/remediation verification. Its work (m3_acceptance_test.exs, vacuum_bounds.ex fix, privilege_test.exs fix) is stranded on branch EXOCOMP-28 at commit 27f5c5e and never landed on main. This is a SOURCE not a duplicate.
- EXOCOMP-33 (Needs Human): SOURCE task — M4 fault-injection suite. Its work (fault_injection_test.exs, state_machine.ex security fixes, approval_gate.ex security fix) is stranded on branch EXOCOMP-33 at commit 47fbb61 and never landed on main. This is a SOURCE not a duplicate.
- EXOCOMP-110 (Open): Parent epic — broader scope covering all stranded deliverables.
- EXOCOMP-111 (Done): Sibling — covered M1 A2A codec/fixture recovery (different scope, closed).
- EXOCOMP-112 (Done): Sibling — covered M5 benchmark host-profile/sampler recovery (different scope, closed).
- EXOCOMP-114/115/116 (Open): Siblings — M6 governance, undelivered work, and verification (all different scopes).

EXOCOMP-113 is the sole recovery vehicle for the EXOCOMP-28 and EXOCOMP-33 deliverables. No other task covers integrating these onto epic-EXOCOMP-110.
---
<!-- COMMENTS:END -->
