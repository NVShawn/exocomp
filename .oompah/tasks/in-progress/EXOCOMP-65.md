---
id: EXOCOMP-65
type: feature
status: In Progress
priority: 2
title: Pin multi-architecture OTP release builders
parent: EXOCOMP-42
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T21:06:03.498156Z'
updated_at: '2026-07-23T21:13:24.961751Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 48a0fea2-630b-48bf-8e36-35b35afee25f
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 571258
  total_output_tokens: 3322
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 571258
      output_tokens: 3322
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 571258
    output_tokens: 3322
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:13:01.463638+00:00'
---
## Summary

Create digest-pinned Linux amd64 and arm64 builder definitions for the supported glibc baseline and the Elixir/OTP versions established by EXOCOMP-7. Add non-interactive Make targets/scripts that select an explicit target architecture, build from a clean checkout, and fail clearly when the host lacks the required container/emulation capability. Keep builder inputs immutable and record the exact builder image digest/toolchain versions for later manifests. Add focused tests or static validation for pinning, supported-architecture mapping, and non-interactive invocation. Acceptance: both target builders can produce the node and coordinator Mix releases with ERTS enabled; no floating image/package/toolchain inputs remain; relevant Make quality gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:11
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:11
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:13
---
Agent completed successfully in 91s (574580 tokens)
---
author: oompah
created: 2026-07-23 21:13
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 9
- Tokens: 571.3K in / 3.3K out [574.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 31s
- Log: EXOCOMP-65__20260723T211136Z.jsonl
---
author: oompah
created: 2026-07-23 21:13
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-42`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:13
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:13
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
