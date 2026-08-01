---
id: EXOCOMP-176
type: task
status: In Progress
priority: 1
title: Package the Mission Control release and OCI image
parent: EXOCOMP-135
children: []
blocked_by:
- EXOCOMP-136
- EXOCOMP-137
start_blocked_by: []
labels: []
assignee: null
created_at: '2026-07-30T14:18:27.819781Z'
updated_at: '2026-08-01T13:28:26.534380Z'
work_branch: epic-EXOCOMP-135--task-EXOCOMP-176
target_branch: null
review_url: null
review_number: null
merged_at: null
oompah.duplicate_screening:
  schema_version: 1
  task_fingerprint: 4a6f8158709e1ee2895f9ef8fd058289fc251a62fe0f746557d674cc2bb84598
  detector_version: duplicate-detector-v1
  verdict: no_duplicate
  checked_at: '2026-08-01T13:11:05.945025+00:00'
  matched_identifiers: []
  evidence: 'Focus handoff: duplicate_detector


    Duplicate preflight verdict: no_duplicate


    Matches: none


    Evidence: Reviewed active task records for EXOCOMP-135, 136, 137, 177, 178, 184,
    and 202. EXOCOMP-135 is the parent epic; 178 is documentation, 184 is downstream
    qualification, and 136/137 are application/database foundations with packaging
    explicitly out of scope. Historical merged tasks EXOCOMP-66, 44, 67, 68, 114,
    and 115 cover prior M6 node/coordinator artifacts, not this active Mission Control
    packaging task.'
  claim_id: null
  claim_owner: null
  claimed_at: null
  claim_expires_at: null
  retry_count: 0
  retry_after: null
oompah.agent_run_id: 0da8f466-fed8-443f-9132-80271fe7a18f
oompah.work_branch: epic-EXOCOMP-135--task-EXOCOMP-176
oompah.integration:
  version: 2
  state: working
  attempts: 0
  task_branch: epic-EXOCOMP-135--task-EXOCOMP-176
  base_branch: epic-EXOCOMP-135
  base_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
  updated_at: '2026-08-01T13:11:27.164487+00:00'
oompah.task_costs:
  total_input_tokens: 1157401
  total_output_tokens: 4784
  total_cost_usd: 0.0
  by_model:
    haiku:
      input_tokens: 1157401
      output_tokens: 4784
      cost_usd: 0.0
  runs:
  - profile: default
    model: haiku
    input_tokens: 1157401
    output_tokens: 4784
    cost_usd: 0.0
    recorded_at: '2026-08-01T13:11:05.938373+00:00'
oompah.work_contributors:
  runs:
  - run_id: EXOCOMP-176__20260801T130906Z
    provider_id: prov-52e94e83
    provider_name: Codex
    model_id: gpt-5.6-luna
    focus: duplicate_detector
    source_branch: epic-EXOCOMP-135--task-EXOCOMP-176
    source_sha: 8f80aebfb70d4dbc405d5ab4436c00ca523ff9ef
    completed_at: '2026-08-01T13:11:05.995656+00:00'
---
## Summary

Plan: plans/mission-control.md, Deployment and Operations.

Deliverables:
- Add a production Mission Control OTP release and reproducible OCI image using the repository pinned builder conventions.
- Provide explicit noninteractive database migrate and server commands.
- Run as an unprivileged user with a read-only root filesystem except documented state paths.
- Add manifest, checksum, SBOM, provenance, and license coverage.

Acceptance:
- Packaging tests start the image against PostgreSQL, run migrations once, restart safely, reject missing secrets, and inspect runtime dependencies.
- No build tools, source tree, credentials, or test fixtures are shipped.

Out of scope: Kubernetes manifests and final qualification.
Quality gate: focused packaging tests plus repository release-check targets.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-08-01 13:08
---
Duplicate screening dispatched (profile: default, task remains Open)
---
author: oompah
created: 2026-08-01 13:09
---
Focus: Duplicate Investigator
---
author: oompah
created: 2026-08-01 13:11
---
Run #1 [attempt=1, profile=default, role=fast -> Codex/gpt-5.6-luna]
- Turns: 1, Tool calls: 34
- Tokens: 1.2M in / 4.8K out [1.2M total]
- Cost: $0.0000
- Exit: normal, Duration: 2m 9s
- Log: EXOCOMP-176__20260801T130906Z.jsonl
---
author: oompah
created: 2026-08-01 13:11
---
Agent dispatched (profile: default)
---
author: oompah
created: 2026-08-01 13:11
---
Focus: DevOps Engineer
---
author: oompah
created: 2026-08-01 13:11
---
Understanding: package Mission Control as a reproducible production OTP release and pinned OCI image, with explicit noninteractive migration/server commands, unprivileged read-only runtime, supply-chain metadata, and focused PostgreSQL/restart/secret/dependency tests. I will inspect existing release conventions first, then implement and verify the packaging surface.
---
author: oompah
created: 2026-08-01 13:28
---
Implementation: added conditional root  OTP release registration, digest-pinned multi-stage OCI Containerfile, UID 10001/read-only state contract, explicit migrate/server/healthcheck entrypoint, reproducible OCI metadata packager (manifest/checksum/SPDX SBOM/SLSA provenance/license coverage), pinned image build and PostgreSQL restart harness scripts, Make targets, Docker context exclusions, and operator documentation.
---
author: oompah
created: 2026-08-01 13:28
---
Verification: make[1]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176'
python3 -m unittest discover -s tests -p 'test_mission_control_packaging.py' -v
make[1]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176', make[1]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176'
python3 -m unittest discover -s tests -p 'test_package_release.py' -v
python3 -m unittest discover -s tests -p 'test_release_input_normalizer.py' -v
python3 -m unittest discover -s tests -p 'test_operator_docs.py' -v
python3 -m unittest discover -s tests -p 'test_mission_control_packaging.py' -v
make[1]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176', make[1]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176'
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
make[1]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176', make[1]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176'
make[2]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176'
compliance: all checks passed
make[2]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176'
make[2]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176'
make[2]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176'
make[2]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176'
python3 -m unittest discover -s tests -p 'test_mission_control_packaging.py' -v
make[2]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176'
make[1]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176', make[1]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176'
compliance: links checks passed
make[1]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176', and make[1]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176'
compliance: licenses checks passed
make[1]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176' pass; shellcheck, sh syntax checks, Python compilation, and  pass. make[1]: Entering directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176'
docker run --rm --init --user "$(id -u):$(id -g)" --platform linux/amd64 --pull always --env ELIXIR_VERSION=1.20.2 --env OTP_VERSION=28.5.0.3 --env GLIBC_BASELINE=2.36 --env MIX_HOME=/workspace/.mix-home --env HEX_HOME=/workspace/.hex-home --volume "/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176:/workspace" --workdir /workspace docker.io/hexpm/elixir:1.20.2-erlang-28.5.0.3-debian-bookworm-20260713-slim@sha256:9f522dfe44ec958c4c40a8f8d1bb6912ef11a77a36f7ef6db2878ade9608216d sh -c 'mix local.hex --force --quiet && mix format --check-formatted'
make[1]: Leaving directory '/home/shedwards/.oompah/worktrees/exocomp/EXOCOMP-176' could not run because the sandbox Podman runtime requires a writable /run/user/1000/libpod; the Mission Control image/PostgreSQL integration remains for the dependency-provided application checkout.
---
<!-- COMMENTS:END -->
