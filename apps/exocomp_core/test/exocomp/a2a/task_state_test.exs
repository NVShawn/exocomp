defmodule Exocomp.A2A.TaskStateTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.TaskState

  test "values/0 returns all valid state atoms" do
    states = TaskState.values()
    assert :submitted in states
    assert :working in states
    assert :input_required in states
    assert :completed in states
    assert :canceled in states
    assert :failed in states
    assert :unknown in states
    assert length(states) == 7
  end

  test "valid?/1 returns true for all known states" do
    for state <- TaskState.values() do
      assert TaskState.valid?(state), "expected #{state} to be valid"
    end
  end

  test "valid?/1 returns false for an unknown atom" do
    refute TaskState.valid?(:not_a_real_state)
  end

  test "terminal?/1 returns true for terminal states" do
    assert TaskState.terminal?(:completed)
    assert TaskState.terminal?(:canceled)
    assert TaskState.terminal?(:failed)
    assert TaskState.terminal?(:unknown)
  end

  test "terminal?/1 returns false for non-terminal states" do
    refute TaskState.terminal?(:submitted)
    refute TaskState.terminal?(:working)
    refute TaskState.terminal?(:input_required)
  end
end
