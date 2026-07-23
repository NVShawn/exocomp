---
id: EXOCOMP-43
type: feature
status: In Progress
priority: 2
title: Implement hardened installers and uninstallers
parent: EXOCOMP-6
children: []
blocked_by:
- EXOCOMP-25
- EXOCOMP-42
labels: []
assignee: null
created_at: '2026-07-23T19:12:02.637514Z'
updated_at: '2026-07-23T22:49:27.525628Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 6c797ce3-3ef6-4dcd-b21a-35f1f68d0302
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 531536
  total_output_tokens: 3280
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 531536
      output_tokens: 3280
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 531536
    output_tokens: 3280
    cost_usd: 0.0
    recorded_at: '2026-07-23T22:49:08.021188+00:00'
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Implement hardened installers and uninstallers.

Implementation
Implement non-interactive node/coordinator install, upgrade hooks, dedicated users/directories, atomic version link, configuration templates, systemd hardening, exact sudoers policy, installed-file manifest, and scoped uninstall/purge categories; preserve PKI/config/audit/execution state by default.

Testing
Test clean install, repeat install, permissions, service startup, invalid checksum/config, exact privileges, upgrade preparation, default uninstall, explicit system-cache purge, and proof user data/non-owned resources remain.

Acceptance Criteria
- [ ] Installer validates before host mutation.
- [ ] Services run unprivileged with expected hardening.
- [ ] Only configured exact privilege rules are installed.
- [ ] Default uninstall preserves protected operator state and all user data.
- [ ] Install tests pass.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 22:47
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 22:47
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 22:49
---
Agent completed successfully in 91s (534816 tokens)
---
author: oompah
created: 2026-07-23 22:49
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 7
- Tokens: 531.5K in / 3.3K out [534.8K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 31s
- Log: EXOCOMP-43__20260723T224740Z.jsonl
---
author: oompah
created: 2026-07-23 22:49
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-6`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 22:49
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 22:49
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
