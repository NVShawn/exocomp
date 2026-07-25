---
id: EXOCOMP-111
type: chore
status: Backlog
priority: 1
title: Recover omitted M1 A2A codec and fixture work
parent: EXOCOMP-110
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-25T17:58:20.183018Z'
updated_at: '2026-07-25T17:58:20.183018Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Recover the stranded EXOCOMP-49 and EXOCOMP-51 commits onto the EXOCOMP-110 shared recovery branch based on current main. Preserve the later A2A router/type changes already on main while integrating JSON codec/version handling, protocol fixtures, and focused tests. Resolve conflicts semantically, run the affected Make targets and full project tests where available, and verify the recovered files are present in the recovery branch.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

