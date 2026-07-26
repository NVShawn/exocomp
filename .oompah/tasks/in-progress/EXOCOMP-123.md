---
id: EXOCOMP-123
type: task
status: In Progress
priority: 1
title: Requalify the remediated M6 release candidate
parent: EXOCOMP-117
children: []
blocked_by:
- EXOCOMP-118
- EXOCOMP-119
- EXOCOMP-120
- EXOCOMP-121
- EXOCOMP-122
labels: []
assignee: null
created_at: '2026-07-26T03:58:35.710500Z'
updated_at: '2026-07-26T07:57:40.156439Z'
work_branch: epic-EXOCOMP-117
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 900ae188-7a8d-4419-8fb8-02c30e0114d1
oompah.work_branch: epic-EXOCOMP-117
oompah.task_costs:
  total_input_tokens: 669727
  total_output_tokens: 4922
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 669727
      output_tokens: 4922
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 669727
    output_tokens: 4922
    cost_usd: 0.0
    recorded_at: '2026-07-26T07:57:17.437765+00:00'
---
## Summary

Context
v0.1.0-rc.2 has signed indexed failure evidence. After the sibling remediation tasks land on main, create a new signed candidate and repeat the complete qualification without reusing unverified results from the failed candidate.

Implementation
Build the exact candidate twice for amd64 and arm64. Run repository and release Make gates, offline verification and installation, production PKI initialization, enrollment and renewal, multi-node diagnostics, failed-service recovery, shipped-artifact M5 gates, hardening inspection, upgrade and automatic rollback, backup and restore, and default plus purge uninstall. Use clean systemd guests; full-system QEMU arm64 is accepted. Record signed indexed evidence and the accepted qualification identity.

Testing
Execute make release-check, make test-release-packaging, make test-installer, make test-bundle, make test-release-matrix for both architectures, make test, and every documented live scenario from the exact signed tag. Verify checksums, signatures, SBOM, provenance, licenses, file ownership, no-network behavior, reproducibility, and protected-state preservation.

Acceptance Criteria
- Every M6-CRIT item records passing evidence on both architectures.
- All required live scenarios pass using only shipped artifacts.
- The complete bundle is reproducible and publication-ready.
- Signed indexed evidence is committed, reviewed, and merged.
- No task is closed based solely on fixture or source-tree tests.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-26 07:54
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-26 07:54
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-26 07:57
---
Agent completed successfully in 177s (674649 tokens)
---
author: oompah
created: 2026-07-26 07:57
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 12
- Tokens: 669.7K in / 4.9K out [674.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 57s
- Log: EXOCOMP-123__20260726T075424Z.jsonl
---
author: oompah
created: 2026-07-26 07:57
---
Agent completed without closing this issue (177s (674649 tokens)). Escalating from 'default' to 'standard'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-26 07:57
---
Agent dispatched (profile: standard)
---
author: oompah
created: 2026-07-26 07:57
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
