---
id: EXOCOMP-9
type: feature
status: Open
priority: 1
title: Implement node configuration, identity, and mTLS startup
parent: EXOCOMP-1
children: []
blocked_by:
- EXOCOMP-7
labels: []
assignee: null
created_at: '2026-07-23T19:08:54.530229Z'
updated_at: '2026-07-23T20:29:15.243819Z'
work_branch: epic-EXOCOMP-1
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 9ed23e93-cc15-463b-8450-9264ef0df13b
oompah.work_branch: epic-EXOCOMP-1
---
## Summary

Plan: [Milestone 1 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-1-node-agent.md)

Goal
Implement node configuration, identity, and mTLS startup.

Implementation
Implement versioned JSON configuration and environment overrides for node ID, listen address, certificates, trust root, diagnostic service allow-list, llama paths/checksums, and timeouts; validate certificate identity and secure private-key permissions before starting the operational listener.

Testing
Test missing and malformed config, unknown versions, bad permissions, invalid chains, wrong SAN/node ID, atomic reload, and fixture certificates.

Acceptance Criteria
- [ ] Insecure or inconsistent identity prevents listener startup.
- [ ] Valid fixture identity starts the TLS listener.
- [ ] Secrets and key paths are redacted from errors and logs.
- [ ] Focused configuration and TLS tests pass.

Quality Gate
Run the focused tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 20:27
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 20:27
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
