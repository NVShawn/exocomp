defmodule Exocomp.A2A.ArtifactTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{Artifact, TextPart}

  test "can be constructed with required fields" do
    part = %TextPart{text: "result"}
    artifact = %Artifact{artifactId: "art-001", parts: [part]}
    assert artifact.artifactId == "art-001"
    assert artifact.parts == [part]
    assert artifact.name == nil
    assert artifact.description == nil
    assert artifact.index == nil
    assert artifact.append == false
    assert artifact.lastChunk == false
    assert artifact.metadata == nil
  end

  test "can be constructed with all fields" do
    artifact = %Artifact{
      artifactId: "art-002",
      name: "Summary",
      description: "A generated summary",
      parts: [],
      index: 0,
      append: true,
      lastChunk: true,
      metadata: %{"source" => "llm"}
    }

    assert artifact.name == "Summary"
    assert artifact.description == "A generated summary"
    assert artifact.index == 0
    assert artifact.append == true
    assert artifact.lastChunk == true
    assert artifact.metadata == %{"source" => "llm"}
  end

  test "raises when required field artifactId is missing" do
    assert_raise ArgumentError, fn ->
      struct!(Artifact, parts: [])
    end
  end

  test "raises when required field parts is missing" do
    assert_raise ArgumentError, fn ->
      struct!(Artifact, artifactId: "art-xyz")
    end
  end
end
