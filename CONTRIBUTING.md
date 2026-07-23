# Contributing to Exocomp

Thank you for helping improve Exocomp. Contributions may be code,
documentation, tests, design feedback, or reproducible bug reports.

By submitting a contribution, you agree that it is licensed under the
[Apache License 2.0](LICENSE), as described by section 5 of that license,
unless you conspicuously mark it `Not a Contribution`.

## Before opening a change

1. Search existing issues and pull requests to avoid duplicate work.
2. For a security vulnerability, follow [SECURITY.md](SECURITY.md) and do not
   open a public issue.
3. Keep a change focused. Include tests for code behavior and update
   user-facing documentation when commands or behavior change.
4. Confirm that new dependencies or bundled artifacts have redistribution
   terms in [`licenses/components.toml`](licenses/components.toml) and notices
   in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Development workflow

The current repository requires Git, GNU Make, Bash, and Python 3.11 or newer.
Later application milestones also pin Elixir and Erlang/OTP versions in their
builder configuration.

```bash
make init
make fmt-check
make test
make lint
```

Use existing Make targets because they carry the repository's supported flags
and sequencing. Before requesting review, run `make release-check` when your
change affects licensing, notices, governance, dependencies, documentation
links, or release material.

Source files owned by Exocomp use SPDX headers:

```text
SPDX-FileCopyrightText: 2026 Exocomp contributors
SPDX-License-Identifier: Apache-2.0
```

Use the comment syntax appropriate for the file. Generated and third-party
files retain their upstream notices instead.

## Pull requests

A reviewable pull request:

- explains the user or operator impact;
- links the issue it resolves;
- includes focused tests and their results;
- updates `CHANGELOG.md` for user-visible changes;
- contains no secrets, credentials, private keys, model data, or unrelated
  generated artifacts; and
- identifies any new dependency, runtime, model, or license obligation.

Maintainers may ask for changes to preserve safety, compatibility, test
coverage, documentation, or release obligations. All contributors must follow
the [Code of Conduct](CODE_OF_CONDUCT.md).
