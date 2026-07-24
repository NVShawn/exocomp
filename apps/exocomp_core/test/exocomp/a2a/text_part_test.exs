defmodule Exocomp.A2A.TextPartTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.TextPart

  test "can be constructed with required text field" do
    part = %TextPart{text: "Hello, world!"}
    assert part.text == "Hello, world!"
    assert part.type == "text"
    assert part.metadata == nil
  end

  test "type field is always 'text'" do
    part = %TextPart{text: "hi"}
    assert part.type == "text"
  end

  test "can be constructed with metadata" do
    part = %TextPart{text: "content", metadata: %{"lang" => "en"}}
    assert part.metadata == %{"lang" => "en"}
  end

  test "raises when required field text is missing" do
    assert_raise ArgumentError, fn ->
      struct!(TextPart, [])
    end
  end
end
