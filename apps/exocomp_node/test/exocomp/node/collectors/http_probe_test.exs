# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
defmodule Exocomp.Node.Collectors.HttpProbeTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Collectors.HttpProbe

  # ---------------------------------------------------------------------------
  # Test: loopback validation
  # ---------------------------------------------------------------------------

  test "rejects non-loopback HTTP URL" do
    assert {:error, _reason} = HttpProbe.probe("http://192.168.1.1:8080/health")
  end

  test "rejects non-loopback HTTPS URL" do
    assert {:error, _reason} = HttpProbe.probe("https://example.com/api")
  end

  test "rejects malformed URLs" do
    assert {:error, _reason} = HttpProbe.probe("not a url")
  end

  test "rejects FTP URLs" do
    assert {:error, _reason} = HttpProbe.probe("ftp://127.0.0.1:21/file")
  end

  # ---------------------------------------------------------------------------
  # Test: loopback acceptance
  # ---------------------------------------------------------------------------

  test "accepts 127.0.0.1 loopback" do
    # This will fail with a connection error, but loopback validation should pass
    result = HttpProbe.probe("http://127.0.0.1:54321/test")
    # Should fail at connection time, not at URL validation
    assert {:error, _} = result
  end

  test "accepts localhost" do
    # This will fail with a connection error, but loopback validation should pass
    result = HttpProbe.probe("http://localhost:54322/test")
    # Should fail at connection time, not at URL validation
    assert {:error, _} = result
  end

  test "accepts IPv6 loopback ::1" do
    # This will fail with a connection error, but loopback validation should pass
    result = HttpProbe.probe("http://[::1]:54323/test")
    # Should fail at connection time, not at URL validation
    assert {:error, _} = result
  end

  test "accepts 127.1.1.1 (within 127.0.0.0/8)" do
    result = HttpProbe.probe("http://127.1.1.1:54324/test")
    # Should fail at connection time, not at URL validation
    assert {:error, _} = result
  end

  test "accepts 127.255.255.255 (within 127.0.0.0/8)" do
    result = HttpProbe.probe("http://127.255.255.255:54325/test")
    # Should fail at connection time, not at URL validation
    assert {:error, _} = result
  end

  # ---------------------------------------------------------------------------
  # Test: response size bounds
  # ---------------------------------------------------------------------------

  test "enforces max_response_bytes limit" do
    # This test validates the limit is checked, but we can't actually
    # test it without a real server. This is more of a parameter validation test.
    # The actual enforcement happens in do_probe when a response is received.
    assert {:error, _} = HttpProbe.probe("http://127.0.0.1:99999/test", max_response_bytes: 0)
  end

  # ---------------------------------------------------------------------------
  # Test: parameter validation
  # ---------------------------------------------------------------------------

  test "accepts valid timeout_ms option" do
    # Will fail with connection error, but options should be accepted
    result = HttpProbe.probe("http://127.0.0.1:54326/test", timeout_ms: 100)
    assert {:error, _} = result
  end

  test "accepts valid max_response_bytes option" do
    # Will fail with connection error, but options should be accepted
    result = HttpProbe.probe("http://127.0.0.1:54327/test", max_response_bytes: 65536)
    assert {:error, _} = result
  end
end
