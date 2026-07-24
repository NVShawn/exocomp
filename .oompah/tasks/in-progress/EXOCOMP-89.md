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
updated_at: '2026-07-24T03:19:32.601326Z'
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
author: oompah
created: 2026-07-24 03:19
---
Discovery: Duplicate screening found no confirmed duplicate. Full tracker records reviewed: EXOCOMP-15 is the parent epic and explicitly decomposes authenticated probing into EXOCOMP-89; EXOCOMP-88 only resolves and stores DNS candidates without adopting Registry.addresses; EXOCOMP-90 owns scheduling/backoff/state transitions; EXOCOMP-91 owns bounded concurrent execution; EXOCOMP-92 owns cross-component integration verification. EXOCOMP-12 provides the node-side mTLS A2A/Agent Card service, while EXOCOMP-14 provides Inventory/Registry/Audit infrastructure. The milestone-2 plan specifically requires hostname identity context, no reverse-DNS trust, and address adoption only after DNS plus mTLS verification, which is uniquely EXOCOMP-89's implementation boundary.
---
<!-- COMMENTS:END -->
