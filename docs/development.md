# Development

Development and release builds run in immutable builder images, so host Elixir
and Erlang installations are not required. Docker or a Docker-compatible
container engine is required. Release dependency inspection also requires
GNU binutils `readelf` on the host.

```shell
make init
make test
make lint
make fmt-check
```

## Architecture-specific releases

Release builds require a clean Git checkout and an explicit target:

```shell
make build-amd64
make build-arm64
# Equivalent parameterized invocation:
make build ARCH=amd64
```

Each target first verifies that the container engine can execute the requested
architecture. On a non-native host, install and enable binfmt/QEMU emulation
before running the target. A missing engine, inaccessible daemon, or unavailable
emulation fails with an actionable error.

Both targets create separate `exocomp_node` and `exocomp_coordinator` OTP
releases with ERTS included under `_build/release/<architecture>/rel`. The exact
Elixir, Erlang/OTP, Debian/glibc baseline, architecture-specific image digests,
and supported architecture mapping are recorded in `release/builders.lock`.
`.tool-versions` provides the same language versions for editor tooling.

For a rootless Podman service, preserve host ownership on the mounted workspace:

```shell
make _CONTAINER_USER_FLAG=--userns=keep-id build-amd64
make _CONTAINER_USER_FLAG=--userns=keep-id test-release-matrix
```
