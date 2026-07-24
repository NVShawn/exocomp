defmodule Exocomp.A2A.FilePartTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{FilePart, FileContent}

  test "can be constructed with required file field" do
    fc = %FileContent{name: "doc.txt", mimeType: "text/plain"}
    part = %FilePart{file: fc}
    assert part.file == fc
    assert part.type == "file"
    assert part.metadata == nil
  end

  test "type field is always 'file'" do
    fc = %FileContent{name: "a", mimeType: "application/octet-stream"}
    part = %FilePart{file: fc}
    assert part.type == "file"
  end

  test "can be constructed with metadata" do
    fc = %FileContent{name: "img.jpg", mimeType: "image/jpeg"}
    part = %FilePart{file: fc, metadata: %{"caption" => "a photo"}}
    assert part.metadata == %{"caption" => "a photo"}
  end

  test "raises when required field file is missing" do
    assert_raise ArgumentError, fn ->
      struct!(FilePart, [])
    end
  end
end
