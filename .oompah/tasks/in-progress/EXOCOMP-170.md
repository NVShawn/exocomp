---
id: EXOCOMP-170
type: task
status: In Progress
priority: 2
title: Build Mission Control administration LiveViews
parent: EXOCOMP-133
children: []
blocked_by:
- EXOCOMP-164
- EXOCOMP-142
- EXOCOMP-144
- EXOCOMP-172
- EXOCOMP-174
- EXOCOMP-175
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:17:05.961611Z'
updated_at: '2026-08-01T15:47:48.757746Z'
work_branch: epic-EXOCOMP-133--task-EXOCOMP-170
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 912d0e697c43d201e7de8f75c098513a3b78cf5e583f82651ccc38c1c36207ff
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T15:30:02.928042+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active task records and comments for EXOCOMP-164, EXOCOMP-166,
    EXOCOMP-142, EXOCOMP-144, EXOCOMP-172, EXOCOMP-174, and EXOCOMP-175. Their scopes
    are shell/navigation, cluster detail, backend invitations/PKI, webhook storage,
    and retention jobs. EXOCOMP-164 only provides an admin placeholder and explicitly
    excludes feature pages; none duplicates the administration LiveViews.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: b2a13da6-f3c7-44ef-8fe1-ba4aad82a43e
oompah.work_branch: epic-EXOCOMP-133--task-EXOCOMP-170
oompah.integration:
  version: 2
  state: ready
  attempts: 0
  task_branch: epic-EXOCOMP-133--task-EXOCOMP-170
  head_sha: 90cbd830cef6ed050f965e3a233180787a07732c
  submitted_at: '2026-08-01T15:47:47.953381+00:00'
  updated_at: '2026-08-01T15:47:47.953381+00:00'
oompah.task_costs:
  total_input_tokens: 849994
  total_output_tokens: 4451
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 849994
      output_tokens: 4451
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 849994
    output_tokens: 4451
    cost_usd: 0.0
    recorded_at: '2026-08-01T15:30:02.925571+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-170__20260801T152809Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-133--task-EXOCOMP-170
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T15:30:02.946564+00:00'
---
## Summary

Plan: plans/mission-control.md, User Interface.

Deliverables:
- Add admin pages for invitation creation, cluster certificate/status display, revocation, OIDC role mappings, retention settings, and webhook endpoint navigation.
- Show invitation plaintext once and clear it after navigation.
- Require confirmation for cluster revocation and record the admin action.

Acceptance:
- LiveView tests cover admin access, viewer/operator denial, invitation one-time display, revocation confirmation, invalid role mapping, retention bounds, and organization isolation.
- Secrets and private keys are never rendered.

Out of scope: webhook delivery-attempt implementation.
Quality gate: focused LiveView tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 15:27
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 15:28
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 15:30
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 37
- Tokens: 850.0K in / 4.5K out [854.4K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 4s
- Log: EXOCOMP-170__20260801T152809Z.jsonl
---
author: oompah
created: 2026-08-01 15:31
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 15:31
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 15:31
---
Understanding: I will inspect the mission-control plan and existing LiveView/auth/domain patterns, implement the requested admin navigation and guarded workflows with one-time invitation display and secret-safe rendering, add focused LiveView coverage, then run the relevant Makefile quality gates and submit the branch.
---
author: oompah
created: 2026-08-01 15:33
---
Discovery: the reusable base is in the EXOCOMP-164 branch (Phoenix app, authenticated live_session, Components, RequireRole, and /admin shell); this task branch is still at the roadmap commit. The dependency history also confirms invitation and certificate concerns are secret/digest-only and webhook contexts return plaintext secrets only at creation. I will bring the shell base into this branch for a buildable implementation, then add an organization-scoped admin context and focused LiveViews around those contracts.
---
author: oompah
created: 2026-08-01 15:43
---
Implementation: added organization-scoped Administration context and safe admin records, expanded /admin into invitations, clusters/certificates, role mappings, retention, and webhook pages, added confirmation-gated cluster revocation with recorded AdminAction, transient one-time invitation token rendering/clearing, and focused context/LiveView tests. Secret material is excluded from records and templates.
---
author: oompah
created: 2026-08-01 15:46
---
Verification: local mix format and git diff --check pass; all Mission Control .ex/.exs files parse, and an OTP smoke run passed invitation digest/one-time consumption, invalid-role, and retention-bound checks.  cannot start because local Elixir 1.18.3 is below the project's 1.20.2 requirement. make[1]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-170'
docker run --rm --init --user "$(id -u):$(id -g)" --platform linux/amd64 --pull always --env ELIXIR_VERSION=1.20.2 --env OTP_VERSION=28.5.0.3 --env GLIBC_BASELINE=2.36 --env MIX_HOME=/workspace/.mix-home --env HEX_HOME=/workspace/.hex-home --volume "/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-170:/workspace" --workdir /workspace docker.io/hexpm/elixir:1.20.2-erlang-28.5.0.3-debian-bookworm-20260713-slim@sha256:9f522dfe44ec958c4c40a8f8d1bb6912ef11a77a36f7ef6db2878ade9608216d sh -c 'mix local.hex --force --quiet && mix format --check-formatted'
make[1]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-170' and make[1]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-170'
./scripts/test-release-builders.sh
Test 1: valid release (amd64) — expect PASS
  PASS: valid amd64 release accepted
Test 2: valid release (arm64) — expect PASS
  PASS: valid arm64 release accepted
Test 3: release with undeclared dependency — expect FAIL
  PASS: release with undeclared dependency correctly rejected
Test 4: dep-report.json produced after valid run
  PASS: dep-report.json includes parsed dependencies and interpreter
Test 5: dep-report.json produced after failing run
  PASS: dep-report.json produced on failure and starts with '{'
Test 6: release without ERTS directory — expect exit 2
  PASS: missing ERTS directory correctly rejected with exit code 2
Test 7: unsupported architecture — expect exit 2
  PASS: unsupported architecture correctly rejected
Test 8: missing baseline file — expect exit 2
  PASS: missing baseline file correctly rejected
Test 9: readelf failure — expect exit 2
  PASS: readelf failure correctly rejected with exit code 2

Results: 9 passed, 0 failed

=== Offline structural checks ===
  PASS: test-clean-container.sh exists and is executable
  PASS: test-release-matrix.sh is non-interactive
  PASS: test-clean-container.sh is non-interactive
  PASS: docs/release-qualification.md exists
  PASS: docs/release-qualification.md documents emulated execution
  PASS: docs/release-qualification.md documents wrong-arch diagnostic
  PASS: Makefile has test-release-matrix target

=== Offline fixture: wrong-arch detection ===
  PASS: wrong-arch produces actionable diagnostic

=== Offline fixture: missing runtime dependency detection ===
  PASS: missing dep produces actionable diagnostic

=== Offline fixture: path-independent content digest ===
  PASS: identical trees at different root paths have matching digests
  PASS: one-byte runtime cookie change produces a different tree digest
  PASS: deterministic release packagers exist and are executable
  PASS: packager excludes reusable release cookies

=== Offline mode: skipping build, container, and live negative tests ===

==========================================
Results: 13 passed, 0 failed
==========================================
release builder definitions are pinned and valid
docker run --rm --init --user "$(id -u):$(id -g)" --platform linux/amd64 --pull always --env ELIXIR_VERSION=1.20.2 --env OTP_VERSION=28.5.0.3 --env GLIBC_BASELINE=2.36 --env MIX_HOME=/workspace/.mix-home --env HEX_HOME=/workspace/.hex-home --volume "/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-170:/workspace" --workdir /workspace docker.io/hexpm/elixir:1.20.2-erlang-28.5.0.3-debian-bookworm-20260713-slim@sha256:9f522dfe44ec958c4c40a8f8d1bb6912ef11a77a36f7ef6db2878ade9608216d sh -c 'mix local.hex --force --quiet && mix deps.get && \
	mix format --check-formatted && \
	MIX_ENV=test mix compile --force --warnings-as-errors'
make[1]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-170' reach their Docker steps but are blocked by the sandbox podman error: unable to chmod /run/user/1000/libpod (read-only filesystem).
---
author: oompah
created: 2026-08-01 15:47
---
Completion: pushed commit 90cbd830 on epic-EXOCOMP-133--task-EXOCOMP-170. Delivered routed admin LiveViews for invitations, cluster certificate/status and confirmed revocation, OIDC mappings, bounded retention, and webhook endpoint navigation; added org-scoped secret-safe administration records and focused tests. Branch status is clean and up to date with origin.
---
<!-- COMMENTS:END -->
