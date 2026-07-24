defmodule Exocomp.A2A.AgentCardTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{AgentCard, AgentCapabilities, AgentSkill}

  test "can be constructed with required fields" do
    card = %AgentCard{
      name: "My Agent",
      description: "A helpful agent",
      url: "https://example.com/agent",
      version: "1.0.0"
    }

    assert card.name == "My Agent"
    assert card.description == "A helpful agent"
    assert card.url == "https://example.com/agent"
    assert card.version == "1.0.0"
    assert card.capabilities == nil
    assert card.skills == []
    assert card.defaultInputModes == nil
    assert card.defaultOutputModes == nil
  end

  test "can be constructed with all fields" do
    caps = %AgentCapabilities{streaming: true}
    skill = %AgentSkill{id: "chat", name: "Chat"}

    card = %AgentCard{
      name: "Full Agent",
      description: "An agent with all fields",
      url: "https://example.com",
      version: "2.0",
      capabilities: caps,
      skills: [skill],
      defaultInputModes: ["text/plain"],
      defaultOutputModes: ["text/plain"]
    }

    assert card.capabilities == caps
    assert card.skills == [skill]
    assert card.defaultInputModes == ["text/plain"]
    assert card.defaultOutputModes == ["text/plain"]
  end

  test "raises when required fields are missing" do
    assert_raise ArgumentError, fn ->
      struct!(AgentCard, name: "Only Name")
    end
  end
end
