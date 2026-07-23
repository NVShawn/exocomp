defmodule Exocomp.Coordinator.ApplicationTest do
  use ExUnit.Case, async: true

  test "starts the coordinator supervision tree in test mode" do
    assert Mix.env() == :test
    assert {:ok, _applications} = Application.ensure_all_started(:exocomp_coordinator)
    assert is_pid(Process.whereis(Exocomp.Coordinator.Supervisor))
  end
end
