defmodule Exocomp.ProtocolTest do
  use ExUnit.Case, async: true

  test "reports the supported A2A protocol version" do
    assert Exocomp.Protocol.version() == "1.0"
  end
end
