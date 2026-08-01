# Restricted Profile-Action Helper

`profile_action_helper` is a small, separately compiled privileged boundary
for the typed Ceph recovery action. It reads exactly one bounded request from
standard input and accepts no command-line arguments. It is not a shell,
command dispatcher, or profile/configuration loader.

## Request protocol

The request is one ASCII line, at most 4096 bytes including the final newline,
with exactly five tab-separated fields:

```text
protocol_version  profile_id  profile_version  action_id  target_unit
```

For example:

```text
1	ceph	1	restart_failed_daemon	ceph-osd@1.service
```

The parser rejects missing or extra fields, embedded newlines, NUL bytes,
non-ASCII or malformed encoded bytes, empty fields, and oversized input. The
only shipped capability in this helper is Ceph profile v1 with the typed
`restart_failed_daemon` action.

Recognized daemon units are `ceph-osd@<decimal>`, `ceph-mon@<id>`,
`ceph-mgr@<id>`, `ceph-mds@<id>`, `ceph-radosgw@<id>`, and `ceph-crash`, with
an optional `.service` suffix. IDs are bounded and contain only ASCII letters,
digits, `-`, `_`, and `.`; OSD IDs are decimal digits only. Shell
metacharacters, paths, whitespace, and arbitrary unit names are rejected.

## Execution boundary

Before a restart, the helper invokes the fixed executable
`/usr/bin/systemctl` directly with:

```text
show --no-pager --plain --property=LoadState,ActiveState --value <unit>
```

It proceeds only for exact `loaded/inactive` or `loaded/failed` state output.
Active, transitional, unloaded, and malformed states fail closed. Only then
does it invoke the fixed argv:

```text
restart <unit>
```

There is no shell or PATH lookup. The child receives a small fixed environment
with paging and color disabled. Both commands have hard timeouts and bounded
combined output; command failures never trigger a retry.

The focused native gate is:

```bash
make test-profile-action-helper
```

The helper binary can be compiled for inspection with
`make build-profile-action-helper`. Bundle assembly validates the ELF machine
against `--arch`. Native amd64 assembly can use the default `_build` output;
arm64 (and any cross-target build) must provide a helper compiled for the
target and pass it explicitly, for example:

```bash
make CC=aarch64-linux-gnu-gcc \
  PROFILE_ACTION_HELPER_BUILD_DIR=_build/profile-action-helper-arm64 \
  build-profile-action-helper
PROFILE_ACTION_HELPER_ARM64=_build/profile-action-helper-arm64/profile_action_helper \
  make bundle-arm64
```

The resulting `bin/profile-action-helper` is listed in both bundle manifests,
represented as its own SPDX package, and installed root-owned with an exact
no-argument sudoers authorization for the node account.
