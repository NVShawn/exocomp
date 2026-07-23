---
id: EXOCOMP-66
type: feature
status: Open
priority: 2
title: Package deterministic OTP release archives and identity manifests
parent: EXOCOMP-42
children: []
blocked_by:
- EXOCOMP-65
labels: []
assignee: null
created_at: '2026-07-23T21:06:23.964610Z'
updated_at: '2026-07-23T21:10:27.211163Z'
work_branch: null
target_branch: null
review_url: null
review_number: null
merged_at: null
---
## Summary

Build on the pinned builders to package versioned node and coordinator OTP releases for linux-amd64 and linux-arm64. Normalize archive ordering, ownership, modes, and timestamps using the tagged source epoch so equivalent inputs produce stable archives/reproducible fields. Include ERTS and emit a machine-readable manifest per archive containing product/version/architecture, source commit and tag, builder digest, Elixir/OTP/ERTS versions, dependency-lock identity, exact non-interactive build command, file inventory, size, and SHA-256. Keep cryptographic signing, SBOM generation, and offline-bundle assembly in EXOCOMP-44. Add tests for naming/layout, ERTS presence, manifest schema/identity, and deterministic normalization. Acceptance: four versioned archives plus manifests are generated for one version and relevant Make gates pass.

## Acceptance Criteria

- [ ] Define acceptance criteria.

## Notes

