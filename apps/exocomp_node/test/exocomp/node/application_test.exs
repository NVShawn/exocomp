# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.ApplicationTest do
  use ExUnit.Case, async: true

  test "starts the node supervision tree in test mode" do
    assert Mix.env() == :test
    assert {:ok, _applications} = Application.ensure_all_started(:exocomp_node)
    assert is_pid(Process.whereis(Exocomp.Node.Supervisor))
    assert is_pid(Process.whereis(Exocomp.Node.TaskRegistry))
  end
end
