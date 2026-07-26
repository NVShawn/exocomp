---
id: EXOCOMP-119
type: feature
status: In Progress
priority: 1
title: Start production coordinator PKI and enrollment services
parent: EXOCOMP-117
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-26T03:58:31.966643Z'
updated_at: '2026-07-26T04:10:17.006433Z'
work_branch: epic-EXOCOMP-117
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: f90c7d94-f2eb-40d4-b0ca-a2287203e574
oompah.work_branch: epic-EXOCOMP-117
---
## Summary

Context
The v0.1.0-rc.2 production coordinator reports healthy while its listener, PKI state, and enrollment processes are nil. Domain modules and fixture-only integration tests exist, but the shipped service cannot perform token issuance, node enrollment, or renewal.

Implementation
Wire the production coordinator supervision tree and runtime configuration to initialize protected PKI state, start the authenticated listener and enrollment token service, expose the supported enrollment and renewal flow, and fail health when required components are absent. Use installer-created paths and least-privilege ownership. Do not expose secrets in logs or command history. Relevant areas include apps/exocomp_coordinator, production config, systemd and installer assets, and PKI/enrollment operator docs.

Testing
Add release-mode integration coverage that starts coordinator and node from installed artifacts, initializes PKI, issues a short-lived node-bound token, enrolls a node, rejects replay and wrong identity, renews over mTLS, restarts both services, and proves durable state recovery. Run make test, make test-installer, make test-bundle, and the clean-host live scenario.

Acceptance Criteria
- Production startup has live listener, PKI, token, and enrollment components.
- A clean installed node enrolls and renews against the installed coordinator.
- Token replay, identity mismatch, bad trust root, and missing audit fail closed.
- Service health reflects missing required components.
- Focused tests and relevant Make gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-26 04:07
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-26 04:07
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-26 04:07
---
Understanding: Duplicate-detector pass only. I will search existing tasks and project decisions for production coordinator PKI, enrollment, renewal, listener, and health work; inspect the full records of credible candidates; then either archive this issue as a confirmed duplicate or record a no-duplicate handoff for an implementation agent.
---
author: oompah
created: 2026-07-26 04:10
---
Discovery: No confirmed duplicate. Full records reviewed for EXOCOMP-17, EXOCOMP-19, EXOCOMP-20, EXOCOMP-60, EXOCOMP-77, EXOCOMP-107, EXOCOMP-117, and EXOCOMP-123. EXOCOMP-77 starts validated PKI/token services only through a test-oriented isolated tree and explicitly excludes certificate issuance/node enrollment; EXOCOMP-107 supplies node-side client/install/scheduling; EXOCOMP-19 supplies the coordinator listener/A2A modules; EXOCOMP-20 verifies internal/fixture paths; EXOCOMP-123 is later release requalification. Current production Application.start/2 omits Listener, PKI.State, and EnrollmentToken while Health.check/0 only considers inventory/registry/audit, directly confirming EXOCOMP-119 owns the remaining shipped-runtime integration rather than repeating a prior task.
---
<!-- COMMENTS:END -->
