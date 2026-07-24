---
id: EXOCOMP-106
type: task
status: In Progress
priority: 0
title: Rebase epic-EXOCOMP-4 onto main
parent: EXOCOMP-4
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
- needs:devops
assignee: null
created_at: '2026-07-24T18:47:19.753669Z'
updated_at: '2026-07-24T18:50:13.645914Z'
work_branch: epic-EXOCOMP-4
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 7a5a77e4-b46e-426a-a7d5-6c2963fc71ad
oompah.work_branch: epic-EXOCOMP-4
---
## Summary

The epic branch `epic-EXOCOMP-4` is stale: it has fallen behind `main`. Rebase the branch onto `origin/main`, resolve any conflicts, and force-push with `git push --force-with-lease`.

This task was auto-filed because epic EXOCOMP-4 was detected as stale. Do NOT create a new branch or PR — work directly on `epic-EXOCOMP-4`.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 18:47
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 18:47
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 18:47
---
Understanding: This task requests rebasing the epic-EXOCOMP-4 branch onto origin/main, resolving any conflicts, and force-pushing. My role here is Duplicate Investigator — I need to first check whether any prior task already covers this same rebase request before doing any implementation. Starting search now.
---
author: oompah
created: 2026-07-24 18:49
---
Discovery: Duplicate screening complete. No duplicate confirmed.

Searched: git log --grep for 'rebase', 'stale', 'EXOCOMP-106'; rg across docs/, plans/, README.md; oompah task view for EXOCOMP-4 (parent epic), EXOCOMP-105, surrounding IDs.

Evidence:
- EXOCOMP-106 is a dedicated child task of EXOCOMP-4 (epic label: `epic:rebasing`). It is the sole rebase entry under that epic — no sibling or ancestor task performs or has performed this rebase.
- git log shows epic-EXOCOMP-4 has one unique commit (EXOCOMP-30) not yet on origin/main, and origin/main has ~30+ commits the branch is missing. The staleness is real and unaddressed.
- No prior task in the tracker (searched task IDs EXOCOMP-104 through EXOCOMP-106, parent EXOCOMP-4, all text searches) describes or resolves this same rebase operation.
- docs/ and plans/ contain no rebase notes for this branch.

Closest reviewed tasks: EXOCOMP-4 (parent epic, 'epic:rebasing' label applied when staleness detected — not a prior rebase task), EXOCOMP-105 (unrelated integration tests on a different branch).

Recommendation: This task is not a duplicate. Proceed with git rebase implementation (devops/chore focus).
---
author: oompah
created: 2026-07-24 18:50
---
Focus handoff: duplicate_detector

1. Outcome: No duplicate confirmed. EXOCOMP-106 is a unique child task of EXOCOMP-4 and is the only rebase task for the epic-EXOCOMP-4 branch. The task is valid and should proceed to implementation.

2. Evidence and decisions:
   - Searched git log (all branches), docs/, plans/, README.md for 'rebase', 'stale', 'epic-EXOCOMP-4' — no matches.
   - Read EXOCOMP-4 (parent epic): lists EXOCOMP-106 as the single rebase child; epic has label 'epic:rebasing', meaning the system flagged it as stale when filing this task.
   - git log --left-right HEAD...origin/main confirms the staleness: epic-EXOCOMP-4 has 1 unique commit (EXOCOMP-30: service-recovery state machine) and is missing ~30+ commits that have landed on origin/main via merged PRs for epics 1, 2, 5, 6, and other work.
   - No earlier EXOCOMP task ID describes or resolves the same rebase operation.

3. Remaining work and risks:
   - Perform `git fetch origin && git rebase origin/main` on branch epic-EXOCOMP-4.
   - Resolve any merge conflicts (most likely in .oompah/tasks if any tasks files were added on main, and possibly in apps/exocomp_coordinator or apps/exocomp_node if overlapping changes exist).
   - Run `make test && make lint && make fmt-check` to verify the rebased branch is clean.
   - Force-push with `git push --force-with-lease`.
   - Risk: EXOCOMP-30 (service-recovery state machine) may conflict with main-branch changes to coordinator files that were introduced by epics 1 and 2.

4. Recommended next focus: devops (or chore — git rebase + conflict resolution, no new feature code).
---
<!-- COMMENTS:END -->
