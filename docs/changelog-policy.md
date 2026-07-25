# Changelog Policy

`CHANGELOG.md` is the concise, human-readable record of changes that affect
users, operators, integrators, or contributors. It is not a commit log.

## Adding entries

Add an entry under `Unreleased` in the same change that introduces a notable
behavior, command, configuration, compatibility, security, dependency,
packaging, or governance change. Use the `Added`, `Changed`, `Deprecated`,
`Removed`, `Fixed`, or `Security` heading that best fits.

Write entries in present tense from the reader's perspective. Link an issue or
pull request when that context will remain useful. Do not disclose unresolved
vulnerability details; use a neutral placeholder in `Security` until the
coordinated advisory is public.

Routine refactors, formatting, test-only changes, and internal build
maintenance need no entry unless they change a supported workflow or release
artifact.

## Cutting a release

At release time, maintainers:

1. move all `Unreleased` entries into a version heading with an ISO date;
2. remove empty categories from that version;
3. create a fresh empty `Unreleased` section;
4. confirm the version follows Semantic Versioning;
5. generate release notes using the
   [release-notes template](release-notes-template.md); and
6. verify the tag, changelog, release notes, and artifact manifests all name
   the same version and commit.

Security entries link the advisory only after coordinated publication.
Correcting a released changelog entry uses a normal reviewed change; do not
silently rewrite published release history.
