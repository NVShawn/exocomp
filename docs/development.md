# Development

The build runs in an immutable builder image, so host Elixir and Erlang
installations are not required. Docker or a Docker-compatible container engine
is the only prerequisite.

```shell
make init
make build
make test
make lint
make fmt-check
```

`make build` creates separate `exocomp_node` and `exocomp_coordinator` OTP
releases with ERTS included. The exact Elixir, Erlang/OTP, Alpine, and builder
image versions are pinned in the Makefile; `.tool-versions` provides the same
language versions for editor tooling.
