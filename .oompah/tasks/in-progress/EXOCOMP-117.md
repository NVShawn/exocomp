---
id: EXOCOMP-117
type: epic
status: In Progress
priority: 0
title: Remediate v0.1.0-rc.2 M6 qualification failures
parent: null
children:
- EXOCOMP-118
- EXOCOMP-119
- EXOCOMP-120
- EXOCOMP-121
- EXOCOMP-122
- EXOCOMP-123
blocked_by: []
labels:
- ci-fix
assignee: null
created_at: '2026-07-26T03:57:27.844799Z'
updated_at: '2026-07-27T11:09:56.499842Z'
work_branch: epic-EXOCOMP-117
target_branch: main
review_url: https://github.com/NVShawn/exocomp/pull/18
review_number: '18'
merged_at: null
oompah.review_url: https://github.com/NVShawn/exocomp/pull/18
oompah.review_number: '18'
oompah.work_branch: epic-EXOCOMP-117
oompah.target_branch: main
oompah.agent_run_id: b04ff248-8bbd-48e0-801a-78ec3dc96315
---
## Summary

Triggered by: EXOCOMP-47

Context
Signed qualification evidence is published under docs/release-evidence/v0.1.0-rc.2 and records a publication-blocking result on clean amd64 and full-system arm64 guests.

Scope
Coordinate focused child fixes for shipped runtime/install correctness, production PKI and enrollment startup, deterministic and cryptographically complete bundles, portable cross-architecture tests, and a real shipped-artifact M5 performance gate. Finish with a new signed candidate and repeat the complete clean-host matrix.

Testing
Each child must add regression coverage and run its relevant Make targets. Final qualification must run release-check, test-release-packaging, test-installer, test-bundle, test-release-matrix on amd64 and arm64, repository tests, and live systemd scenarios from the exact signed candidate.

Acceptance Criteria
- Every failure recorded for v0.1.0-rc.2 has an implemented and tested fix.
- A new signed candidate passes all M6-CRIT items on clean amd64 and full-system arm64 guests.
- Signed indexed evidence is committed and merged.
- The release is reproducible and publication-ready.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

## Comments
<!-- COMMENTS:BEGIN -->
author: oompah
created: 2026-07-27 11:04
---
YOLO: CI tests failed on MR #18. Fix the failing tests so this MR can merge. Do NOT rewrite the feature — only fix test failures. IMPORTANT: Paths in CI logs are not trustworthy. Run tests locally to get accurate paths and errors.
---
author: oompah
created: 2026-07-27 11:04
---
Agent dispatched (profile: deep)
---
author: oompah
created: 2026-07-27 11:04
---
Focus: CI Failure Fixer
---
author: oompah
created: 2026-07-27 11:04
---
Understanding: This epic tracks CI failures on MR #18 (v0.1.0-rc.2 M6 qualification). My role as CI Failure Fixer is to identify and fix the failing tests so the MR can merge. I will: (1) identify the source branch for MR #18, (2) check out that branch, (3) fetch actual CI failure logs from GitHub Actions, (4) reproduce failures locally, (5) apply minimal fixes, (6) push and verify. Starting investigation now.
---
author: oompah
created: 2026-07-27 11:08
---
Discovery: The CI failure on PR #18 (branch epic-EXOCOMP-117) is a Python version compatibility issue. tests/test_m5_qualification.py imports 'tomllib' which is stdlib only in Python 3.11+. The CI runner uses ubuntu-22.04 with Python 3.10 as default (python3). Error: ModuleNotFoundError: No module named 'tomllib'. Fix: implement a minimal pure-Python TOML subset parser as a fallback when tomllib is unavailable, avoiding any external dependency. The TOML baseline files have simple structure (key-value pairs + [section.subsection] headers) that a small parser can handle.
---
author: oompah
created: 2026-07-27 11:09
---
Implementation: Fixed ModuleNotFoundError for 'tomllib' in tests/test_m5_qualification.py. Added a try/except import at the top of the file: when tomllib is unavailable (Python <3.11), a minimal pure-Python TOML subset parser is provided as a class-based fallback. The fallback handles: (1) comment stripping, (2) [section.subsection] headers, (3) string, int, float, and bool values. No external dependencies added. All 28 Python tests pass locally.
---
author: oompah
created: 2026-07-27 11:09
---
Verification: All 28 Python tests pass locally (python3 -m unittest discover -s tests -v). Fallback TOML parser verified against real baseline files — all values parsed correctly including floats, strings, and nested sections. Fix pushed to epic-EXOCOMP-117.
---
<!-- COMMENTS:END -->
