---
id: EXOCOMP-89
type: feature
status: In Progress
priority: 1
title: Verify node mTLS identity and safely adopt resolved addresses
parent: EXOCOMP-15
children: []
blocked_by:
- EXOCOMP-88
labels: []
assignee: null
created_at: '2026-07-24T02:42:56.090929Z'
updated_at: '2026-07-24T03:18:39.064828Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: c61e8db2-6eed-4a6d-a33b-76d5a0957d37
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Implement the authenticated node probe boundary for coordinator discovery. Connect to explicit DNS-resolved IP candidates while retaining the configured hostname as identity/SNI context, validate the peer chain against coordinator trust, and require the configured certificate_identity (for example the expected URI SAN) without consulting reverse DNS. Fetch and validate the node Agent Card and health response with a per-request timeout, trying multiple resolved addresses without allowing an identity mismatch to pass. Update Registry.addresses only after both DNS resolution and mTLS identity verification succeed; preserve the last verified addresses on DNS, transport, certificate, or payload failure. Return typed outcomes for healthy, degraded, timeout, unreachable, and identity mismatch, and emit redacted audit events. Add focused TLS tests for correct/wrong identity, multiple addresses, changed-address adoption, failed-change preservation, and malformed/failed Agent Card or health responses. Build on EXOCOMP-12 and EXOCOMP-14 and run affected Make targets.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 03:18
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 03:18
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 03:18
---
Understanding: Screening EXOCOMP-89 for duplication before any implementation. I will search existing tasks and project docs for authenticated coordinator probes, mTLS identity verification, resolved-address adoption, typed probe outcomes, and Agent Card/health validation; then inspect full candidate task records to determine whether any one task covers the same underlying work.
---
<!-- COMMENTS:END -->
