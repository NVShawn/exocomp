#!/bin/sh

set -eu

actual_elixir="$(elixir -e 'IO.write(System.version())')"
otp_root="$(erl -noshell -eval 'io:format("~s", [code:root_dir()]), halt().')"
actual_otp="$(tr -d '\n' <"${otp_root}/releases/28/OTP_VERSION")"

if [ "${actual_elixir}" != "${ELIXIR_VERSION}" ]; then
  echo "expected Elixir ${ELIXIR_VERSION}, found ${actual_elixir}" >&2
  exit 1
fi

if [ "${actual_otp}" != "${OTP_VERSION}" ]; then
  echo "expected OTP ${OTP_VERSION}, found ${actual_otp}" >&2
  exit 1
fi

echo "Elixir ${actual_elixir} / OTP ${actual_otp}"
