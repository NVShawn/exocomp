---
id: EXOCOMP-77
type: task
status: In Progress
priority: 1
title: Integrate coordinator PKI initialization and enrollment operations
parent: EXOCOMP-16
children: []
blocked_by:
- EXOCOMP-75
- EXOCOMP-76
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T23:01:30.250567Z'
updated_at: '2026-07-24T01:35:02.370925Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 1223f98e-ed99-44eb-9d55-f2d3f7ba9366
oompah.work_branch: epic-EXOCOMP-2
oompah.task_costs:
  total_input_tokens: 271298
  total_output_tokens: 2037
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 271298
      output_tokens: 2037
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 271298
    output_tokens: 2037
    cost_usd: 0.0
    recorded_at: '2026-07-24T01:34:41.597005+00:00'
---
## Summary

Integrate EXOCOMP-75 PKI bootstrap and EXOCOMP-76 enrollment tokens into the coordinator application and operator workflow. Extend the EXOCOMP-14 supervision tree so runtime services start only from validated protected state and expose health/errors without secrets. Add configuration for explicit online-state and offline-root-backup paths and an operator-facing initialization entry point using the repository convention (prefer a Mix task if no CLI exists). Initialization output must clearly identify the offline backup path and root fingerprint, must never print private keys or protection inputs, and must distinguish newly initialized, already initialized, and invalid-state outcomes with stable exit behavior. Wire the enrollment issue/consume boundary needed by EXOCOMP-17 without implementing CSR issuance or node-side enrollment. Add integration tests covering clean initialization followed by application start, idempotent rerun, missing/corrupt/insecure material startup failure, explicit backup output, token issue/consume through the supervised service, restart replay rejection, audit outage fail-closed behavior, and captured log/output redaction. Verify private paths/modes and assert no root private key is retained online. Run all affected Make targets: make fmt-check, make build, make test, and make lint. Acceptance: coordinator startup uses validated PKI state, operator initialization is explicit and safe, token operations are supervised/audited/fail-closed, cross-cutting security tests pass, and the EXOCOMP-17 interface is documented in module contracts.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 01:33
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 01:33
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 01:33
---
Understanding: Screening EXOCOMP-77 for duplication only. I will search existing tasks and project docs for coordinator PKI initialization, protected-state startup, and enrollment issue/consume integration; inspect full candidate task descriptions/comments; then either archive as a confirmed duplicate or document no duplicate and hand off to implementation.
---
author: oompah
created: 2026-07-24 01:34
---
Discovery: No duplicate confirmed. EXOCOMP-16 comments #19-23 explicitly created EXOCOMP-77 as the distinct integration child after separating PKI bootstrap into EXOCOMP-75 and durable enrollment tokens into EXOCOMP-76. EXOCOMP-14 supplies the supervision/inventory/audit foundation, while EXOCOMP-17 is the node-side consumer. None covers EXOCOMP-77's operator Mix task, protected-state startup validation, supervised issue/consume boundary, or cross-cutting integration/security verification.
---
author: oompah
created: 2026-07-24 01:34
---
Focus handoff: duplicate_detector

Outcome: Duplicate screening found no duplicate; EXOCOMP-77 should proceed to implementation.

Evidence: Local search reviewed plans/milestone-2-coordinator.md and related docs; the worktree has no .oompah/tasks mirror. Full tracker histories were reviewed for EXOCOMP-14, EXOCOMP-16, EXOCOMP-17, EXOCOMP-75, and EXOCOMP-76. EXOCOMP-16 explicitly decomposed its scope into EXOCOMP-75 (bootstrap/state validation), EXOCOMP-76 (durable token service), and EXOCOMP-77 (supervision/operator/API integration). EXOCOMP-14 is foundational infrastructure and EXOCOMP-17 is the downstream node-side consumer.

Relevant areas: apps/exocomp_coordinator/lib/exocomp/coordinator/application.ex; PKI bootstrap and enrollment-token modules delivered by EXOCOMP-75/76; coordinator config and tests; plans/milestone-2-coordinator.md.

Remaining work/risks: Integrate validated PKI state into startup; add the safe operator initialization entry point and stable outcomes; expose supervised issue/consume contracts without CSR issuance; add end-to-end startup, replay, audit-outage, permission, root-absence, and redaction tests; run fmt-check/build/test/lint. Ensure the implementation checkout contains the completed EXOCOMP-75 and EXOCOMP-76 commits. No code was changed during screening.

Recommended next focus: feature.
---
author: oompah
created: 2026-07-24 01:34
---
Agent completed successfully in 91s (273335 tokens)
---
author: oompah
created: 2026-07-24 01:34
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 11
- Tokens: 271.3K in / 2.0K out [273.3K total]
- Cost: $0.0000
- Exit: normal, Duration: 1m 31s
- Log: EXOCOMP-77__20260724T013313Z.jsonl
---
author: oompah
created: 2026-07-24 01:34
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-24 01:34
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 01:34
---
Focus: Security Auditor
---
author: oompah
created: 2026-07-24 01:35
---
Understanding: Security Auditor focus for EXOCOMP-77. I will conduct a thorough security review of the PKI initialization and enrollment operations integration. Key security concerns to audit: (1) secret/key material exposure in logs or output, (2) file permission enforcement for private keys, (3) replay attack prevention in enrollment tokens, (4) audit-log fail-closed behavior, (5) root CA key absence verification online, (6) input validation for enrollment tokens, (7) OWASP Top 10 in coordinator paths, (8) supervision tree startup validation. I will explore the codebase to understand what EXOCOMP-75/76 delivered, then review for vulnerabilities before handing off to the feature agent.
---
<!-- COMMENTS:END -->
