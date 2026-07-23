# Exocomp VERSION

Release date: YYYY-MM-DD

Source commit: FULL_GIT_SHA

## Summary

Describe the release's purpose and its most important operator impact.

## Highlights

- Notable capability or improvement.

## Upgrade and compatibility

- Supported source versions:
- Configuration or protocol changes:
- Required migrations:
- Rollback limits and procedure:

## Security

List published advisories and mitigations, or state that no security advisories
are included. Do not disclose embargoed details.

## Artifacts

For every amd64 and arm64 node release, coordinator release, complete offline
bundle, and runtime-only bundle, record:

- artifact filename;
- SHA-256;
- signature filename and verification identity;
- SBOM filename;
- provenance filename; and
- manifest and license-inventory filenames.

## Bundled components

Record the exact Erlang/OTP version, `llama.cpp` commit/build, Qwen GGUF
repository revision and SHA-256, and every Hex dependency lock revision.
Confirm the matching license and notice inventory is present.

## Known issues

- Issue and practical workaround.

## Verification

- Clean-host amd64 qualification result:
- Clean-host arm64 qualification result:
- Offline installation result:
- Upgrade and rollback result:
- Uninstall/data-retention result:
