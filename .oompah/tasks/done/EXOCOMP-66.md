---
id: EXOCOMP-66
type: feature
status: Done
priority: 2
title: Package deterministic OTP release archives and identity manifests
parent: EXOCOMP-42
children: []
blocked_by:
- EXOCOMP-65
labels: []
assignee: null
created_at: '2026-07-23T21:06:23.964610Z'
updated_at: '2026-07-23T21:31:25.175949Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 6b22c659-4f38-4d9c-98f4-da7bf1b93368
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 1417265
  total_output_tokens: 8358
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 1417265
      output_tokens: 8358
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 585734
    output_tokens: 3329
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:27:59.227083+00:00'
  - profile: standard
    model: unknown
    input_tokens: 417464
    output_tokens: 2871
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:29:32.462769+00:00'
  - profile: deep
    model: unknown
    input_tokens: 414067
    output_tokens: 2158
    cost_usd: 0.0
    recorded_at: '2026-07-23T21:31:12.436920+00:00'
---
## Summary

Build on the pinned builders to package versioned node and coordinator OTP releases for linux-amd64 and linux-arm64. Normalize archive ordering, ownership, modes, and timestamps using the tagged source epoch so equivalent inputs produce stable archives/reproducible fields. Include ERTS and emit a machine-readable manifest per archive containing product/version/architecture, source commit and tag, builder digest, Elixir/OTP/ERTS versions, dependency-lock identity, exact non-interactive build command, file inventory, size, and SHA-256. Keep cryptographic signing, SBOM generation, and offline-bundle assembly in EXOCOMP-44. Add tests for naming/layout, ERTS presence, manifest schema/identity, and deterministic normalization. Acceptance: four versioned archives plus manifests are generated for one version and relevant Make gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 21:26
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 21:26
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:28
---
Agent completed successfully in 91s (589063 tokens)
---
author: oompah
created: 2026-07-23 21:28
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 10
- Tokens: 585.7K in / 3.3K out [589.1K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 31s
- Log: EXOCOMP-66__20260723T212631Z.jsonl
---
author: oompah
created: 2026-07-23 21:28
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-42`. Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 21:28
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-23 21:28
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:29
---
Agent completed successfully in 76s (420335 tokens)
---
author: oompah
created: 2026-07-23 21:29
---
Run #2 [attempt=2, profile=standard, role=standard -> Codex/default]
- Turns: 1, Tool calls: 6
- Tokens: 417.5K in / 2.9K out [420.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 16s
- Log: EXOCOMP-66__20260723T212818Z.jsonl
---
author: oompah
created: 2026-07-23 21:29
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-42`. Escalating from 'standard' to 'deep'. Retrying in 20s (2/3).
---
author: oompah
created: 2026-07-23 21:30
---
Retrying (attempt #2, agent: deep)
---
author: oompah
created: 2026-07-23 21:30
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 21:31
---
Agent completed successfully in 73s (416225 tokens)
---
author: oompah
created: 2026-07-23 21:31
---
Run #3 [attempt=3, profile=deep, role=deep -> Codex/default]
- Turns: 1, Tool calls: 5
- Tokens: 414.1K in / 2.2K out [416.2K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 13s
- Log: EXOCOMP-66__20260723T213000Z.jsonl
---
author: oompah
created: 2026-07-23 21:31
---
Agent completed 3 times without closing this issue. Human action required: review the agent run history and task state, then either close the task if the work is done or add specific guidance and move it back to Open.
---
<!-- COMMENTS:END -->
