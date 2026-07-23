defmodule Bench.ApplicationTest do
  use ExUnit.Case, async: true

  test "starts the bench supervision tree in test mode" do
    assert Mix.env() == :test
    assert {:ok, _applications} = Application.ensure_all_started(:bench)
    assert is_pid(Process.whereis(Bench.Supervisor))
  end
end
