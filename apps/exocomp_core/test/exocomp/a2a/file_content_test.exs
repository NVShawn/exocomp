defmodule Exocomp.A2A.FileContentTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.FileContent

  test "can be constructed with required fields" do
    fc = %FileContent{name: "report.pdf", mimeType: "application/pdf"}
    assert fc.name == "report.pdf"
    assert fc.mimeType == "application/pdf"
    assert fc.uri == nil
    assert fc.bytes == nil
  end

  test "can be constructed with uri" do
    fc = %FileContent{
      name: "image.png",
      mimeType: "image/png",
      uri: "https://example.com/image.png"
    }

    assert fc.uri == "https://example.com/image.png"
  end

  test "can be constructed with bytes" do
    fc = %FileContent{
      name: "data.bin",
      mimeType: "application/octet-stream",
      bytes: "dGVzdA=="
    }

    assert fc.bytes == "dGVzdA=="
  end

  test "raises when required field name is missing" do
    assert_raise ArgumentError, fn ->
      struct!(FileContent, mimeType: "text/plain")
    end
  end

  test "raises when required field mimeType is missing" do
    assert_raise ArgumentError, fn ->
      struct!(FileContent, name: "file.txt")
    end
  end
end
