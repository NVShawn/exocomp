---
id: EXOCOMP-41
type: chore
status: In Progress
priority: 2
title: Add licensing and open-source governance files
parent: EXOCOMP-6
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-23T19:12:00.656358Z'
updated_at: '2026-07-23T19:23:03.968047Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: eedbcb76-1253-4542-96a7-5365c133267a
oompah.work_branch: epic-EXOCOMP-6
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Add licensing and open-source governance files.

Implementation
Add Apache-2.0 LICENSE, third-party/runtime/model notices, contribution guide, code of conduct, security policy with private reporting instructions, release-note template, changelog policy, and maintainer release checklist; verify all bundled licenses permit redistribution.

Testing
Add automated required-file, link, license-header where applicable, dependency-license, and notice inventory checks; test an intentionally missing/incompatible entry.

Acceptance Criteria
- [ ] Apache-2.0 and governance files are complete.
- [ ] Every dependency, llama.cpp, and model artifact has compatible recorded terms.
- [ ] Security reporting does not require public disclosure.
- [ ] Automated checks detect missing/incompatible notices.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 19:20
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 19:20
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 19:23
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 19:23
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
