# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Bench.ApplicationTest do
  use ExUnit.Case, async: true

  test "starts the bench supervision tree in test mode" do
    assert Mix.env() == :test
    assert {:ok, _applications} = Application.ensure_all_started(:bench)
    assert is_pid(Process.whereis(Bench.Supervisor))
  end

  test "declares the OTP applications required by the standalone harness" do
    applications = Application.spec(:bench, :applications)

    assert :inets in applications
    assert :public_key in applications
  end
end
