---
id: EXOCOMP-118
type: bug
status: In Progress
priority: 1
title: Make the shipped node bundle install and start cleanly
parent: EXOCOMP-117
children: []
blocked_by: []
labels: []
assignee: null
created_at: '2026-07-26T03:58:30.973367Z'
updated_at: '2026-07-26T03:59:26.030375Z'
work_branch: epic-EXOCOMP-117
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 595769bb-eb20-448f-af30-0e751949a9b3
oompah.work_branch: epic-EXOCOMP-117
---
## Summary

Context
The v0.1.0-rc.2 clean-host evidence shows the installed node crashes because production config opens /var/lib/exocomp/replay_ledger.dets while the installer owns /var/lib/exocomp-node. The bundled llama-server also fails with a missing libllama-server-impl.so, documented archive and checksum paths do not match the extracted bundle, and scripts/state-backup.sh is not shipped.

Implementation
Align production runtime paths with installer-owned directories and permissions. Package every llama-server runtime dependency. Make the documented checksum and install commands match the delivered archive layout. Include the backup and restore utility in the installed and offline payloads. Relevant areas include config/config.exs, scripts/assemble-bundle.sh, installer assets, systemd units, and docs/installation.md plus docs/lifecycle.md.

Testing
Add regression tests that install the assembled bundle into a clean root, start the node service without host Erlang or network access, execute the documented verification and install commands verbatim, and complete backup and restore using only shipped files. Run make test-installer, make test-bundle, make test-release-packaging, and the clean-systemd VM scenario.

Acceptance Criteria
- The installed node service remains active and owns a writable durable replay ledger.
- Bundled llama-server starts on a clean host with all runtime libraries present.
- Published verification and installation commands succeed verbatim.
- Shipped backup and restore preserve protected state.
- Focused tests and relevant Make gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-26 03:59
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-26 03:59
---
Focus: Duplicate Investigator
---
<!-- COMMENTS:END -->
