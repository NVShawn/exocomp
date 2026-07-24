---
id: EXOCOMP-88
type: feature
status: In Progress
priority: 1
title: Resolve inventory hostnames into normalized address candidates
parent: EXOCOMP-15
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-24T02:42:48.305068Z'
updated_at: '2026-07-24T02:51:32.531877Z'
work_branch: epic-EXOCOMP-2
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 5d37f51f-8fa6-47c7-8729-7d8dfdd624aa
oompah.work_branch: epic-EXOCOMP-2
---
## Summary

Implement the coordinator DNS discovery component described in plans/milestone-2-coordinator.md. Add a supervised, dependency-injectable resolver that reads configured hostnames from Exocomp.Coordinator.Inventory, resolves all IPv4/IPv6 addresses with normal DNS (never reverse DNS), normalizes/deduplicates deterministic results, and reports resolution success/failure as structured audit/health events. Keep resolved results as candidates until an authenticated probe approves adoption; DNS success alone must not replace Registry.addresses. Cover successful resolution, multiple addresses, address-set changes, empty/NXDOMAIN/timeout/error results, and refresh after inventory changes using deterministic resolver fakes. Integrate with the EXOCOMP-14 Inventory/Registry/Audit foundation and run focused tests plus affected Make targets.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-24 02:49
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-24 02:49
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-24 02:51
---
Understanding: Duplicate screening initiated for EXOCOMP-88 (Resolve inventory hostnames into normalized address candidates). Searching for any existing tasks covering DNS hostname resolution, IPv4/IPv6 address normalization/deduplication, and address candidate tracking in the coordinator context.
---
<!-- COMMENTS:END -->
