defmodule Exocomp.A2A.VersionTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{
    ContentTypeNotSupportedError,
    UnsupportedOperationError,
    Version
  }

  test "reports the supported protocol versions" do
    assert Version.supported_versions() == ["1.0"]
  end

  test "accepts A2A version 1.0" do
    assert Version.check_version("1.0") == :ok
  end

  test "rejects unsupported and missing A2A versions" do
    assert {:error, %UnsupportedOperationError{}} = Version.check_version("2.0")
    assert {:error, %UnsupportedOperationError{}} = Version.check_version(nil)
  end

  test "accepts only the A2A JSON media type" do
    assert Version.parse_content_type("application/a2a+json") == :ok

    assert {:error, %ContentTypeNotSupportedError{}} =
             Version.parse_content_type("application/json")

    assert {:error, %ContentTypeNotSupportedError{}} = Version.parse_content_type(nil)
  end
end
