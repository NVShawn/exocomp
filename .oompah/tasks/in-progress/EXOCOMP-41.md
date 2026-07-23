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
updated_at: '2026-07-23T19:25:49.353724Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 9a629f92-a027-4dd1-b257-acbcae8b5c18
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 437083
  total_output_tokens: 5499
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 437083
      output_tokens: 5499
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 437083
    output_tokens: 5499
    cost_usd: 0.0
    recorded_at: '2026-07-23T19:25:30.493726+00:00'
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
author: oompah
created: 2026-07-23 19:25
---
Agent completed successfully in 148s (442582 tokens)
---
author: oompah
created: 2026-07-23 19:25
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 21
- Tokens: 437.1K in / 5.5K out [442.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 28s
- Log: EXOCOMP-41__20260723T192304Z.jsonl
---
author: oompah
created: 2026-07-23 19:25
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-6`. Escalating from 'default' to 'quick'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 19:25
---
Agent dispatched (profile: quick)
---
author: oompah
created: 2026-07-23 19:25
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
