defmodule Exocomp.Core.ApplicationTest do
  use ExUnit.Case, async: true

  test "starts the core supervision tree in test mode" do
    assert Mix.env() == :test
    assert {:ok, _applications} = Application.ensure_all_started(:exocomp_core)
    assert is_pid(Process.whereis(Exocomp.Core.Supervisor))
  end
end
