---
id: EXOCOMP-46
type: chore
status: Merged
priority: 2
title: Document and test upgrade, rollback, backup, and removal
parent: EXOCOMP-6
children: []
blocked_by:
- EXOCOMP-34
- EXOCOMP-43
- EXOCOMP-115
labels: []
assignee: null
created_at: '2026-07-23T19:12:05.467498Z'
updated_at: '2026-07-25T21:10:41.914653Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Document and test upgrade, rollback, backup, and removal.

Implementation
Implement/document side-by-side upgrade, configuration validation, health-gated current-version switch, automatic rollback, compatibility limits, PKI/state backup and restore, troubleshooting, and safe removal; avoid irreversible first-release migrations.

Testing
Test successful upgrade, failed health rollback, coordinator/node version compatibility, backup/restore, interrupted upgrade, default uninstall, explicit purge categories, and preservation of PKI/audit/execution/config/user data.

Acceptance Criteria
- [ ] Failed upgrade restores a healthy prior version.
- [ ] Rollback does not reissue identities or repeat actions.
- [ ] Backup/restore procedures are verified.
- [ ] Removal deletes only recorded Exocomp-owned resources and never user data.
- [ ] Lifecycle tests pass.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 18:32
---
Action required: use recovery task EXOCOMP-115 to implement and verify this task's previously undelivered scope on main. Do not mark this task Merged again until EXOCOMP-115 lands and the original acceptance criteria are confirmed against main.
---
author: oompah
created: 2026-07-25 18:32
---
Moved to Needs Human from the dashboard/API. Human action required: inspect EXOCOMP-46 (Document and test upgrade, rollback, backup, and removal), add the specific decision, missing information, or manual fix needed, then move the task back to Open when it is ready for agents again.
---
author: oompah
created: 2026-07-25 20:09
---
The parent epic EXOCOMP-6 merged from epic-EXOCOMP-6, but this task was Needs Human with work branch unset. Its work is not proven to be in the merged epic. Inspect the task's agent history and remote branches, recover any missing commits through a new recovery epic or approved follow-up PR, then move this task to Done only after the recovered work is verified on the target branch.
---
author: oompah
created: 2026-07-25 21:10
---
Recovered delivery verified on origin/main at merge commit 2085e44152f03ffd41f35cbfeee89a0da53b8bce (PR #14). Evidence: health-gated upgrade/rollback, backup/restore, removal lifecycle, docs, and 63 installer tests are integrated by 516faf81e5f506f9cc7d1ac24a98499e73dbfea0. The full recovery quality gates passed.
---
author: oompah
created: 2026-07-25 21:10
---
Recovered deliverable verified on origin/main via PR #14 (2085e44).
---
<!-- COMMENTS:END -->
