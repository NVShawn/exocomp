defmodule Exocomp.A2A.AgentSkillTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.AgentSkill

  test "can be constructed with required fields" do
    skill = %AgentSkill{id: "summarize", name: "Summarize"}
    assert skill.id == "summarize"
    assert skill.name == "Summarize"
    assert skill.description == nil
    assert skill.inputModes == nil
    assert skill.outputModes == nil
  end

  test "can be constructed with all fields" do
    skill = %AgentSkill{
      id: "translate",
      name: "Translate",
      description: "Translates text between languages",
      inputModes: ["text/plain"],
      outputModes: ["text/plain"]
    }

    assert skill.id == "translate"
    assert skill.name == "Translate"
    assert skill.description == "Translates text between languages"
    assert skill.inputModes == ["text/plain"]
    assert skill.outputModes == ["text/plain"]
  end

  test "raises when required field id is missing" do
    assert_raise ArgumentError, fn ->
      struct!(AgentSkill, name: "No ID")
    end
  end

  test "raises when required field name is missing" do
    assert_raise ArgumentError, fn ->
      struct!(AgentSkill, id: "no-name")
    end
  end
end
