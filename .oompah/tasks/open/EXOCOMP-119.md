---
id: EXOCOMP-119
type: feature
status: Open
priority: 1
title: Start production coordinator PKI and enrollment services
parent: EXOCOMP-117
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-26T03:58:31.966643Z'
updated_at: '2026-07-26T03:59:14.405076Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
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

