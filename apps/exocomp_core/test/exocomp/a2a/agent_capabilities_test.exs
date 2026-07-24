defmodule Exocomp.A2A.AgentCapabilitiesTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.AgentCapabilities

  test "can be constructed with default values" do
    caps = %AgentCapabilities{}
    assert caps.streaming == false
    assert caps.pushNotifications == false
    assert caps.stateTransitionHistory == false
  end

  test "can be constructed with all capabilities enabled" do
    caps = %AgentCapabilities{
      streaming: true,
      pushNotifications: true,
      stateTransitionHistory: true
    }

    assert caps.streaming == true
    assert caps.pushNotifications == true
    assert caps.stateTransitionHistory == true
  end

  test "can be constructed with partial capabilities" do
    caps = %AgentCapabilities{streaming: true}
    assert caps.streaming == true
    assert caps.pushNotifications == false
    assert caps.stateTransitionHistory == false
  end
end
