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
labels: []
assignee: null
created_at: '2026-07-23T23:01:30.250567Z'
updated_at: '2026-07-24T01:33:04.787389Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Integrate EXOCOMP-75 PKI bootstrap and EXOCOMP-76 enrollment tokens into the coordinator application and operator workflow. Extend the EXOCOMP-14 supervision tree so runtime services start only from validated protected state and expose health/errors without secrets. Add configuration for explicit online-state and offline-root-backup paths and an operator-facing initialization entry point using the repository convention (prefer a Mix task if no CLI exists). Initialization output must clearly identify the offline backup path and root fingerprint, must never print private keys or protection inputs, and must distinguish newly initialized, already initialized, and invalid-state outcomes with stable exit behavior. Wire the enrollment issue/consume boundary needed by EXOCOMP-17 without implementing CSR issuance or node-side enrollment. Add integration tests covering clean initialization followed by application start, idempotent rerun, missing/corrupt/insecure material startup failure, explicit backup output, token issue/consume through the supervised service, restart replay rejection, audit outage fail-closed behavior, and captured log/output redaction. Verify private paths/modes and assert no root private key is retained online. Run all affected Make targets: make fmt-check, make build, make test, and make lint. Acceptance: coordinator startup uses validated PKI state, operator initialization is explicit and safe, token operations are supervised/audited/fail-closed, cross-cutting security tests pass, and the EXOCOMP-17 interface is documented in module contracts.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

