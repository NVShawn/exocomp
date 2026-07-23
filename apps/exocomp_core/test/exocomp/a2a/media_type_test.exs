defmodule Exocomp.A2A.MediaTypeTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{ContentTypeNotSupportedError, Version}

  test "'application/a2a+json' is accepted" do
    assert :ok = Version.parse_content_type("application/a2a+json")
  end

  test "'application/json' is rejected with ContentTypeNotSupportedError (-32005)" do
    assert {:error, %ContentTypeNotSupportedError{code: -32005}} =
             Version.parse_content_type("application/json")
  end

  test "'text/plain' is rejected with ContentTypeNotSupportedError (-32005)" do
    assert {:error, %ContentTypeNotSupportedError{code: -32005}} =
             Version.parse_content_type("text/plain")
  end

  test "nil is rejected with ContentTypeNotSupportedError (-32005)" do
    assert {:error, %ContentTypeNotSupportedError{code: -32005}} =
             Version.parse_content_type(nil)
  end

  test "'application/a2a+json; charset=utf-8' (with params) is accepted" do
    assert :ok = Version.parse_content_type("application/a2a+json; charset=utf-8")
  end
end
