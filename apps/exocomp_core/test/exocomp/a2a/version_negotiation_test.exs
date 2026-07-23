defmodule Exocomp.A2A.VersionNegotiationTest do
  use ExUnit.Case, async: true

  alias Exocomp.A2A.{UnsupportedOperationError, Version}

  test "A2A-Version '1.0' is accepted" do
    assert :ok = Version.check_version("1.0")
  end

  test "A2A-Version '2.0' is rejected with UnsupportedOperationError (-32004)" do
    assert {:error, %UnsupportedOperationError{code: -32004}} = Version.check_version("2.0")
  end

  test "A2A-Version '0.9' is rejected with UnsupportedOperationError (-32004)" do
    assert {:error, %UnsupportedOperationError{code: -32004}} = Version.check_version("0.9")
  end

  test "missing A2A-Version header (nil) is rejected with UnsupportedOperationError (-32004)" do
    assert {:error, %UnsupportedOperationError{code: -32004}} = Version.check_version(nil)
  end

  test "empty string A2A-Version is rejected with UnsupportedOperationError (-32004)" do
    assert {:error, %UnsupportedOperationError{code: -32004}} = Version.check_version("")
  end
end
