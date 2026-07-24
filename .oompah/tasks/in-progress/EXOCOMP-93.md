---
id: EXOCOMP-93
type: task
status: In Progress
priority: 0
title: Rebase epic-EXOCOMP-1 onto main
parent: EXOCOMP-1
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T02:50:21.235712Z'
updated_at: '2026-07-24T02:52:29.867783Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 17ab8676-9820-4c7a-bcf4-cbc3446260fa
oompah.work_branch: epic-EXOCOMP-1
---
## Summary

The epic branch `epic-EXOCOMP-1` is stale: it has fallen behind `main`. Rebase the branch onto `origin/main`, resolve any conflicts, and force-push with `git push --force-with-lease`.

This task was auto-filed because epic EXOCOMP-1 was detected as stale. Do NOT create a new branch or PR — work directly on `epic-EXOCOMP-1`.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:50
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-24 02:50
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 02:50
---
Understanding: This is an auto-filed stale-epic rebase request. I will screen existing tasks for the same epic branch/rebase event, inspect full candidate task histories, and either archive EXOCOMP-93 as a confirmed duplicate or hand it off for implementation if none exists.
---
author: oompah
created: 2026-07-24 02:52
---
Discovery: Duplicate screening found no duplicate. The closest reviewed task is EXOCOMP-82, a completed rebase of epic-EXOCOMP-6; its full description/comments and branch state are specific to that different epic. EXOCOMP-1's full record lists EXOCOMP-93 as the rebase child for epic-EXOCOMP-1, and no task through EXOCOMP-92 covers this branch operation. Repository docs contain no competing rebase task; .oompah/tasks is absent from this worktree, so tracker records were inspected through oompah task view.
---
author: oompah
created: 2026-07-24 02:52
---
Focus handoff: duplicate_detector

Outcome: No duplicate confirmed; EXOCOMP-93 is the unique stale-branch maintenance task for epic-EXOCOMP-1. No code or git history was changed during screening.

Evidence: Searched the prescribed repository paths for rebase/stale/epic-EXOCOMP-1 terms (local .oompah/tasks and WORKFLOW.md are absent). Reviewed EXOCOMP-1 in full: it lists EXOCOMP-93 as its rebase child. Reviewed the closest candidate EXOCOMP-82 in full: it rebased epic-EXOCOMP-6 and is branch-specific, so it is analogous but not duplicate work. Screened tracker records through EXOCOMP-92 for another rebase of epic-EXOCOMP-1 and found none.

Remaining work/risks: Fetch/prune origin, verify the worktree is clean and branch identity is epic-EXOCOMP-1, rebase onto current origin/main, resolve conflicts without losing epic changes, run proportionate verification, then force-push with --force-with-lease and confirm local/remote status. Shared-branch updates may make the lease stale, so re-check the remote immediately before pushing.

Recommended next focus: chore.
---
<!-- COMMENTS:END -->
