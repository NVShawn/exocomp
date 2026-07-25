---
id: EXOCOMP-45
type: chore
status: Merged
priority: 2
title: Write installation, PKI, policy, and operations guides
parent: EXOCOMP-6
children: []
blocked_by:
- EXOCOMP-17
- EXOCOMP-28
- EXOCOMP-115
labels: []
assignee: null
created_at: '2026-07-23T19:12:04.573016Z'
updated_at: '2026-07-25T21:10:35.557967Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Write installation, PKI, policy, and operations guides.

Implementation
Document supported hosts, online/offline install, coordinator initialization, offline-root handling, fingerprint distribution, enrollment, renewal/revocation/rotation, inventory, diagnostics, model sizing, service allow-lists, sudoers, approvals, data classification, bounded system cleanup, and audit retention in docs/.

Testing
Execute every command block against release fixtures; run Markdown/link checks; have scenarios cover first node, renewal, approval, cleanup boundaries, and troubleshooting unsafe permissions.

Acceptance Criteria
- [ ] Commands match shipped artifacts and pass fixture validation.
- [ ] Guides clearly state user data is never deleted and unknown data is protected.
- [ ] PKI and approval procedures include failure/recovery paths.
- [ ] All links and documentation checks pass.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-25 18:31
---
Action required: use recovery task EXOCOMP-115 to implement and verify this task's previously undelivered scope on main. Do not mark this task Merged again until EXOCOMP-115 lands and the original acceptance criteria are confirmed against main.
---
author: oompah
created: 2026-07-25 18:31
---
Moved to Needs Human from the dashboard/API. Human action required: inspect EXOCOMP-45 (Write installation, PKI, policy, and operations guides), add the specific decision, missing information, or manual fix needed, then move the task back to Open when it is ready for agents again.
---
author: oompah
created: 2026-07-25 19:59
---
The parent epic EXOCOMP-6 merged from epic-EXOCOMP-6, but this task was Needs Human with work branch unset. Its work is not proven to be in the merged epic. Inspect the task's agent history and remote branches, recover any missing commits through a new recovery epic or approved follow-up PR, then move this task to Done only after the recovered work is verified on the target branch.
---
author: oompah
created: 2026-07-25 21:10
---
Recovered delivery verified on origin/main at merge commit 2085e44152f03ffd41f35cbfeee89a0da53b8bce (PR #14). Evidence: installation, PKI, policy, and operator guides are integrated by 516faf81e5f506f9cc7d1ac24a98499e73dbfea0. The full recovery quality gates passed.
---
author: oompah
created: 2026-07-25 21:10
---
Recovered deliverable verified on origin/main via PR #14 (2085e44).
---
<!-- COMMENTS:END -->
