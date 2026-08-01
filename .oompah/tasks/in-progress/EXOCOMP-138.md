---
id: EXOCOMP-138
type: task
status: In Progress
priority: 2
title: Add organizations and mandatory organization scoping
parent: EXOCOMP-128
children: []
blocked_by:
- EXOCOMP-137
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:13:52.527968Z'
updated_at: '2026-08-01T15:04:47.040275Z'
work_branch: epic-EXOCOMP-128--task-EXOCOMP-138
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: b57985a586a1fecab1d858a2031f9281b4717e71f7474e35c4c224a033076109
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T14:43:21.430666+00:00'
  matched_identifiers: []
  evidence: "Based on my comprehensive investigation of the codebase and related planning\
    \ documents, I can now provide my duplicate investigation verdict.\n\n## Investigation\
    \ Summary\n\nI searched across multiple locations:\n1. **Plans and Documentation**:\
    \ Reviewed `plans/mission-control.md`, the definitive source for Mission Control\
    \ architecture\n2. **Codebase**: Searched `apps/` directory for any existing organization\
    \ implementations\u2014found none\n3. **Task References**: Searched for EXOCOMP-137\
    \ (blocking dependency), EXOCOMP-158 (organization-scoped conversations peer),\
    \ and other related peers\n4. **Database/Schema**: Searched for organization_id\
    \ fields, Organization models, migration files\u2014found nothing\n5. **Phoenix\
    \ Apps**: Confirmed no mission_control app exists yet in the umbrella\n\n## Key\
    \ Findings\n\n- **No existing organizations table or schema** in the codebase\n\
    - **EXOCOMP-158** (peer task) has submitted work on \"organization-scoped conversations\"\
    \ but:\n  - Is in terminal state (submitted-result), excluded per duplicate-investigation\
    \ rules\n  - Focused on conversations, not the foundational organizations table\
    \ itself\n  - Would logically depend on organizations existing first\n- **EXOCOMP-137**\
    \ (blocking dependency) has no discoverable scope information\n- **No active,\
    \ open task** describes the same work: \"Add organizations table and schema with\
    \ stable generated identifier, test/dev seed, reusable scoping helper for tenant-owned\
    \ queries\"\n\n## Conclusion\n\nEXOCOMP-138 is a foundational, prerequisite task\
    \ for the Mission Control feature. While peer tasks like EXOCOMP-158 have started\
    \ and depend on organization scoping, none of them duplicate the specific deliverables\
    \ of EXOCOMP-138:\n- Organizations table and schema\n- Test/dev seed\n- Reusable\
    \ scoping helper\n- Foreign-key and unique-constraint examples\n\n---\n\n**Focus\
    \ handoff: duplicate_detector**\n\n**Duplicate preflight verdict: no_duplicate**\n\
    \n**Matches: none**\n\n**Evidence:** Comprehensive search of plans/mission-control.md\
    \ (architectural sourc"
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: a2b5866b-0502-4e8e-93a7-d61e62041633
oompah.work_branch: epic-EXOCOMP-128--task-EXOCOMP-138
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-128--task-EXOCOMP-138
  base_branch: epic-EXOCOMP-128
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T14:43:34.681365+00:00'
oompah.task_costs:
  total_input_tokens: 146
  total_output_tokens: 5601
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 146
      output_tokens: 5601
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 146
    output_tokens: 5601
    cost_usd: 0.0
    recorded_at: '2026-08-01T14:43:21.429838+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-138__20260801T144129Z
    provider_id: prov-651d553c
    provider_name: Claude
    model_id: haiku
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-128--task-EXOCOMP-138
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T14:43:21.436299+00:00'
---
## Summary

Plan: plans/mission-control.md, Organization and Operator Identity.

Deliverables:
- Add the organizations table and schema with a stable generated identifier.
- Add a test/dev seed for the initial organization.
- Add a small reusable scoping helper that requires organization_id for tenant-owned queries and inserts.
- Add foreign-key and unique-constraint examples used by later contexts.

Acceptance:
- Inserts without an organization fail closed.
- Tests prove records from one organization cannot be read, updated, or deleted through another organization scope.
- No global unscoped list function is exposed.

Out of scope: tenant administration UI and billing.
Quality gate: focused Ecto tests plus make fmt-check and make lint.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 14:41
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 14:41
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 14:43
---
Run #1 [attempt=1, profile=default, role=fast -> Claude/haiku]
- Turns: 44, Tool calls: 22
- Tokens: 146 in / 5.6K out [5.7K total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 2s
- Log: EXOCOMP-138__20260801T144129Z.jsonl
---
author: oompah
created: 2026-08-01 14:43
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 14:43
---
Focus: Frontend Developer
---
author: oompah
created: 2026-08-01 14:43
---
Understanding: I will inspect the existing Ecto schemas, migrations, query APIs, seeds, and test conventions; then add organizations with stable generated identifiers, reusable fail-closed organization scoping, tenant constraints, and focused cross-organization tests. I will run make fmt-check, make lint, and focused tests before submitting.
---
author: oompah
created: 2026-08-01 14:45
---
Discovery: this branch has no Ecto or Mission Control app yet; later sibling branches independently add apps/exocomp_mission_control with Ecto/PostgreSQL. I’ll establish the minimal Mission Control Ecto foundation here so later contexts can consume an Organization schema, Repo, migrations, seed, and fail-closed scoped query helper.
---
author: oompah
created: 2026-08-01 14:57
---
Implementation: added the Mission Control Ecto app/repository, UUID-backed Organization schema/context, idempotent initial seed, reusable fail-closed OrganizationScope query/changeset helpers, and OrganizationScopedRecord CRUD examples. Added organizations and scoped-record migrations with non-null FK, restrict-on-delete, slug uniqueness, and per-organization composite uniqueness. Focused tests cover missing-scope inserts plus cross-organization read/update/delete isolation.
---
author: oompah
created: 2026-08-01 15:04
---
Verification: focused Mission Control tests pass (15 tests, 0 failures), migration modules compile, and explicit format-check passes for all changed Elixir files. make[1]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-138'
docker run --rm --init --user "$(id -u):$(id -g)" --platform linux/amd64 --pull always --env ELIXIR_VERSION=1.20.2 --env OTP_VERSION=28.5.0.3 --env GLIBC_BASELINE=2.36 --env MIX_HOME=/workspace/.mix-home --env HEX_HOME=/workspace/.hex-home --volume "/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-138:/workspace" --workdir /workspace docker.io/hexpm/elixir:1.20.2-erlang-28.5.0.3-debian-bookworm-20260713-slim@sha256:9f522dfe44ec958c4c40a8f8d1bb6912ef11a77a36f7ef6db2878ade9608216d sh -c 'mix local.hex --force --quiet && mix format --check-formatted'
make[1]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-138' and the Elixir phase of make[1]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-138'
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
docker run --rm --init --user "$(id -u):$(id -g)" --platform linux/amd64 --pull always --env ELIXIR_VERSION=1.20.2 --env OTP_VERSION=28.5.0.3 --env GLIBC_BASELINE=2.36 --env MIX_HOME=/workspace/.mix-home --env HEX_HOME=/workspace/.hex-home --volume "/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-138:/workspace" --workdir /workspace docker.io/hexpm/elixir:1.20.2-erlang-28.5.0.3-debian-bookworm-20260713-slim@sha256:9f522dfe44ec958c4c40a8f8d1bb6912ef11a77a36f7ef6db2878ade9608216d sh -c 'mix local.hex --force --quiet && mix deps.get && \
	mix format --check-formatted && \
	MIX_ENV=test mix compile --force --warnings-as-errors'
make[1]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-138' could not run because this environment has no usable Docker/Podman builder (container invocation fails on read-only Podman configuration); lint's offline builder/compliance checks passed before that container step.
---
author: oompah
created: 2026-08-01 15:04
---
Verification correction: focused Mission Control tests pass (15 tests, 0 failures), migration modules compile, and explicit format-check passes for all changed Elixir files. The Makefile fmt-check and lint container phases are unavailable here because Docker/Podman cannot initialize; lint offline builder and compliance checks passed.
---
<!-- COMMENTS:END -->
