#!/bin/sh

set -eu

actual_elixir="$(elixir -e 'IO.write(System.version())')"
otp_root="$(erl -noshell -eval 'io:format("~s", [code:root_dir()]), halt().')"
actual_otp="$(tr -d '\n' <"${otp_root}/releases/28/OTP_VERSION")"
actual_glibc="$(getconf GNU_LIBC_VERSION | awk '{print $2}')"

if [ "${actual_elixir}" != "${ELIXIR_VERSION}" ]; then
  echo "expected Elixir ${ELIXIR_VERSION}, found ${actual_elixir}" >&2
  exit 1
fi

if [ "${actual_otp}" != "${OTP_VERSION}" ]; then
  echo "expected OTP ${OTP_VERSION}, found ${actual_otp}" >&2
  exit 1
fi

if [ "${actual_glibc}" != "${GLIBC_BASELINE}" ]; then
  echo "expected glibc ${GLIBC_BASELINE}, found ${actual_glibc}" >&2
  exit 1
fi

echo "Elixir ${actual_elixir} / OTP ${actual_otp} / glibc ${actual_glibc}"
