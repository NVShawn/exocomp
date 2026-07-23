---
id: EXOCOMP-41
type: chore
status: Merged
priority: 2
title: Add licensing and open-source governance files
parent: EXOCOMP-6
children: []
blocked_by: []
labels:
- focus-complete:duplicate_detector
assignee: null
created_at: '2026-07-23T19:12:00.656358Z'
updated_at: '2026-07-23T23:31:20.635735Z'
work_branch: epic-EXOCOMP-6
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.agent_run_id: 1d3c8c0c-4411-4430-beff-eece92b3b1f8
oompah.work_branch: epic-EXOCOMP-6
oompah.task_costs:
  total_input_tokens: 437102
  total_output_tokens: 11855
  total_cost_usd: 0.0
  by_model:
    unknown:
      input_tokens: 437102
      output_tokens: 11855
      cost_usd: 0.0
  runs:
  - profile: default
    model: unknown
    input_tokens: 437083
    output_tokens: 5499
    cost_usd: 0.0
    recorded_at: '2026-07-23T19:25:30.493726+00:00'
  - profile: quick
    model: unknown
    input_tokens: 19
    output_tokens: 6356
    cost_usd: 0.0
    recorded_at: '2026-07-23T19:28:01.512921+00:00'
---
## Summary

Plan: [Milestone 6 design](https://github.com/NVShawn/exocomp/blob/main/plans/milestone-6-release.md)

Goal
Add licensing and open-source governance files.

Implementation
Add Apache-2.0 LICENSE, third-party/runtime/model notices, contribution guide, code of conduct, security policy with private reporting instructions, release-note template, changelog policy, and maintainer release checklist; verify all bundled licenses permit redistribution.

Testing
Add automated required-file, link, license-header where applicable, dependency-license, and notice inventory checks; test an intentionally missing/incompatible entry.

Acceptance Criteria
- [ ] Apache-2.0 and governance files are complete.
- [ ] Every dependency, llama.cpp, and model artifact has compatible recorded terms.
- [ ] Security reporting does not require public disclosure.
- [ ] Automated checks detect missing/incompatible notices.

Quality Gate
Run the focused release/documentation tests and all repository Make targets affected by this change.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-23 19:20
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 19:20
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 19:23
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-07-23 19:23
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 19:25
---
Agent completed successfully in 148s (442582 tokens)
---
author: oompah
created: 2026-07-23 19:25
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/default]
- Turns: 1, Tool calls: 21
- Tokens: 437.1K in / 5.5K out [442.6K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 28s
- Log: EXOCOMP-41__20260723T192304Z.jsonl
---
author: oompah
created: 2026-07-23 19:25
---
Agent completed without landing — no commits found on origin for branch `epic-EXOCOMP-6`. Escalating from 'default' to 'quick'. Retrying in 10s (1/3).
---
author: oompah
created: 2026-07-23 19:25
---
Agent dispatched (profile: quick)
---
author: oompah
created: 2026-07-23 19:25
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-07-23 19:27
---
Focus handoff: duplicate_detector

**Outcome:** No duplicate found. EXOCOMP-41 is a unique, well-scoped task.

**Evidence reviewed:**
- EXOCOMP-6 (parent epic): M6 open-source release — confirmed EXOCOMP-41 is a distinct child covering licensing/governance only
- EXOCOMP-42: OTP release artifacts — distinct scope (build reproducibility, not licensing)
- EXOCOMP-43: Hardened installers/uninstallers — distinct scope
- EXOCOMP-44: Offline bundles, SBOMs, provenance — closest to EXOCOMP-41 (both mention 'licenses') but EXOCOMP-44 focuses on bundling/signing artifacts while EXOCOMP-41 focuses on the governance files themselves (LICENSE, NOTICE, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, CHANGELOG, release checklist, and automated compliance checks)
- EXOCOMP-45, EXOCOMP-46, EXOCOMP-47: Documentation and qualification — distinct scope
- No other tasks in the system mention Apache-2.0 licensing, code of conduct, or security policy
- Confirmed: no LICENSE, NOTICE, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, or CHANGELOG files exist in the repository yet

**Remaining work:** Implement all governance files per the description:
- Apache-2.0 LICENSE
- NOTICE files (third-party/runtime/model)
- CONTRIBUTING.md
- CODE_OF_CONDUCT.md
- SECURITY.md (with private vulnerability reporting)
- CHANGELOG.md / release note template
- Maintainer release checklist
- Automated checks: required-file presence, link validation, license-header, dependency-license compatibility, notice inventory
- Tests for missing/incompatible entries

**Key risk:** The dependency/license compatibility check needs to enumerate all bundled components (llama.cpp, Qwen GGUF model, Elixir/OTP dependencies) — verify each has Apache-2.0-compatible terms.

**Recommended next focus:** chore (governance/compliance file setup with automated checks)
---
author: oompah
created: 2026-07-23 19:28
---
Agent completed successfully in 133s (6375 tokens)
---
author: oompah
created: 2026-07-23 19:28
---
Run #2 [attempt=2, profile=quick, role=fast -> Claude/default]
- Turns: 37, Tool calls: 24
- Tokens: 19 in / 6.4K out [6.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 13s
- Log: EXOCOMP-41__20260723T192549Z.jsonl
---
author: oompah
created: 2026-07-23 19:28
---
Focus handoff from `duplicate_detector` is complete. Queued a fresh agent run for the next applicable focus. The next agent should begin with the preceding Focus handoff comment.
---
author: oompah
created: 2026-07-23 19:28
---
Agent dispatched (profile: quick)
---
author: oompah
created: 2026-07-23 19:28
---
Focus: Maintenance Engineer
---
author: oompah
created: 2026-07-23 19:39
---
Understanding: Add the complete Apache-2.0 governance surface, record redistribution terms for planned runtime and model inputs, add offline compliance checks with negative tests, run every affected Make target, then commit and push the issue branch.
---
author: oompah
created: 2026-07-23 19:39
---
Discovery: The repository is a pre-application skeleton with no mix.lock or vendored artifacts. Planned inputs are Erlang/OTP under Apache-2.0, llama.cpp under MIT, the official Qwen2.5 1.5B Instruct GGUF under Apache-2.0, and build-time Elixir under Apache-2.0. Future Hex lock entries must fail unless inventoried.
---
author: oompah
created: 2026-07-23 19:39
---
Implementation: Added canonical LICENSE and NOTICE files; contribution, conduct, security, changelog, release-note, and maintainer policies; human and TOML component inventories; SPDX coverage; and Make-backed checks for required files, links, canonical license text, headers, Hex dependencies, redistribution compatibility, and notice headings.
---
author: oompah
created: 2026-07-23 19:39
---
Verification: make compliance-check, make test-compliance, make fmt-check, make check-links, make check-licenses, make test, make lint, and make release-check all pass. Nine tests include missing governance and notice entries, an incompatible GPL-3.0-only license, an uninventoried Hex dependency, a broken link, and a missing SPDX header. LICENSE matches the canonical Apache text byte for byte.
---
author: oompah
created: 2026-07-23 19:39
---
Completion: Delivered and pushed commit 886a6abab473b5724477582d954a8929e3be8e58 on EXOCOMP-41. The branch matches origin, the worktree is clean, all acceptance criteria are covered, and no follow-up task is required.
---
author: oompah
created: 2026-07-23 19:40
---
Run #1 [attempt=1, profile=quick, role=fast -> Codex/default]
- Turns: 0, Tool calls: 66
- Tokens: 0 in / 0 out [0 total]
- Cost: $0.0000
- Exit: terminated, Duration: 12m 0s
- Log: EXOCOMP-41__20260723T192811Z.jsonl
---
author: oompah
created: 2026-07-23 19:40
---
Added Apache-2.0 licensing, complete open-source governance and release documentation, compatible runtime and model notices, and failure-tested compliance automation; all affected Make quality gates pass in pushed commit 886a6ab.
---
<!-- COMMENTS:END -->
