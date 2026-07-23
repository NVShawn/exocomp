defmodule Bench.Sampler.BehaviourTest do
  use ExUnit.Case, async: true

  test "behaviour module is defined" do
    assert Code.ensure_loaded?(Bench.Sampler.Behaviour)
  end

  test "behaviour defines the expected callbacks" do
    callbacks = Bench.Sampler.Behaviour.behaviour_info(:callbacks)
    assert {:init, 1} in callbacks
    assert {:collect, 1} in callbacks
    assert {:terminate, 1} in callbacks
  end
end
