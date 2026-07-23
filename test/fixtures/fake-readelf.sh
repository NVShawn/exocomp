#!/bin/sh
# Fake readelf for testing inspect-release-deps.sh.
#
# Usage: fake-readelf.sh [-d] [--] <elf_file>
#
# Reads SONAME metadata from a sidecar .readelf-d file placed alongside the
# fake ELF file. This lets tests control exactly which NEEDED entries are
# reported without building real ELF binaries.
#
# The sidecar file must be named <elf_file>.readelf-d and contain lines in
# the format that real `readelf -d` outputs, for example:
#
#   0x0000000000000001 (NEEDED)   Shared library: [libc.so.6]
#   0x0000000000000001 (NEEDED)   Shared library: [libm.so.6]
#
# If no sidecar exists, the script outputs nothing (static binary).
#
# The special path "INVALID_ELF" causes the script to exit with status 1,
# simulating a non-ELF file that readelf rejects.

set -eu

# Strip all leading flags (arguments starting with '-') to find the filename.
elf_file=""
for arg in "$@"; do
  case "${arg}" in
    -*)
      # Skip flag
      ;;
    *)
      elf_file="${arg}"
      break
      ;;
  esac
done

if [ -z "${elf_file}" ]; then
  echo "fake-readelf: missing elf file argument" >&2
  exit 2
fi

case "${elf_file}" in
  *INVALID_ELF*)
    echo "fake-readelf: not an ELF file: ${elf_file}" >&2
    exit 1
    ;;
esac

sidecar="${elf_file}.readelf-d"
if [ -f "${sidecar}" ]; then
  cat "${sidecar}"
fi

exit 0
