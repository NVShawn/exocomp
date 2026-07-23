# Exclude integration and systemd tests by default.
#
# These tests require a VM or privileged container running systemd as PID 1
# and must be run as root.  They are tagged @moduletag :integration and
# @moduletag :systemd.  Standard CI runs in an unprivileged Alpine container
# that lacks systemd, so these tests must be explicitly opted in.
#
# To run integration tests:
#   make test-integration
# or:
#   MIX_ENV=test mix test --only integration apps/exocomp_node/test/integration/
ExUnit.start(exclude: [:integration, :systemd])
