#!/bin/sh

set -eu

command_name="${1:-}"
shift

case "${command_name}" in
  info | pull)
    exit 0
    ;;
  run)
    platform=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --platform)
          platform="$2"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done

    case "${platform}" in
      linux/amd64)
        echo "x86_64"
        ;;
      linux/arm64)
        echo "aarch64"
        ;;
      *)
        echo "unexpected platform '${platform}'" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    echo "unexpected container command '${command_name}'" >&2
    exit 1
    ;;
esac
