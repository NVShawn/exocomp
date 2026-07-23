defmodule Exocomp.A2A.DataPartTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.DataPart

  test "can be constructed with required data field" do
    part = %DataPart{data: %{"key" => "value"}}
    assert part.data == %{"key" => "value"}
    assert part.type == "data"
    assert part.metadata == nil
  end

  test "type field is always 'data'" do
    part = %DataPart{data: %{}}
    assert part.type == "data"
  end

  test "can be constructed with metadata" do
    part = %DataPart{data: %{"x" => 1}, metadata: %{"schema" => "v1"}}
    assert part.metadata == %{"schema" => "v1"}
  end

  test "raises when required field data is missing" do
    assert_raise ArgumentError, fn ->
      struct!(DataPart, [])
    end
  end
end
