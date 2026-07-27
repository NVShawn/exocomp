---
id: EXOCOMP-125
type: task
status: In Progress
priority: 1
title: Complete remaining M5 workload and soak qualification
parent: null
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-27T16:09:24.864781Z'
updated_at: '2026-07-27T16:15:45.545611Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 42267f60-2369-4ee3-bc34-ff63f3171f41
---
## Summary

Triggered by: EXOCOMP-124

Close M5-CRIT-3 through M5-CRIT-6. Main has pinned shipped-artifact CPU/RAM gates and startup/inference/saturation evidence, but lacks shipped llama restart results, mixed healthy/slow/unreachable coordinator polling benchmarks, recovery observation-to-verification latency under load, and multi-hour leak/soak analysis covering memory, processes, mailboxes, descriptors, and task history. Implement the missing workloads and reports, qualify amd64 and arm64 artifacts, commit raw evidence, and merge to main.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-27 16:15
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-27 16:15
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
