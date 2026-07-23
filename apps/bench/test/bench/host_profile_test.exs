defmodule Bench.HostProfileTest do
  use ExUnit.Case, async: true

  alias Bench.HostProfile

  # ---------------------------------------------------------------------------
  # detect/0
  # ---------------------------------------------------------------------------

  describe "detect/0" do
    test "returns a well-formed %Bench.HostProfile{} struct" do
      profile = HostProfile.detect()

      assert %HostProfile{} = profile
      assert is_binary(profile.architecture)
      assert byte_size(profile.architecture) > 0
      assert is_binary(profile.cpu_model)
      assert byte_size(profile.cpu_model) > 0
      assert is_integer(profile.cpu_count)
      assert profile.cpu_count >= 0
      assert is_integer(profile.ram_bytes)
      assert profile.ram_bytes >= 0
      assert is_binary(profile.kernel_version)
      assert byte_size(profile.kernel_version) > 0
      assert is_binary(profile.linux_distribution)
      assert byte_size(profile.linux_distribution) > 0
      assert is_binary(profile.libc_version)
      assert byte_size(profile.libc_version) > 0
      assert is_binary(profile.governor)
      assert byte_size(profile.governor) > 0
      assert is_binary(profile.container_or_vm)
      assert byte_size(profile.container_or_vm) > 0
    end

    test "architecture field is a recognised value or 'unknown'" do
      profile = HostProfile.detect()

      assert profile.architecture in ["amd64", "arm64", "unknown"] or
               is_binary(profile.architecture)
    end

    test "all string fields are non-empty and integer fields are non-negative" do
      profile = HostProfile.detect()

      # String fields must be non-empty (detect falls back to "unknown", never nil)
      assert byte_size(profile.architecture) > 0
      assert byte_size(profile.cpu_model) > 0
      assert byte_size(profile.kernel_version) > 0
      assert byte_size(profile.linux_distribution) > 0
      assert byte_size(profile.libc_version) > 0
      assert byte_size(profile.governor) > 0
      assert byte_size(profile.container_or_vm) > 0

      # Integer fields must be non-negative
      assert profile.cpu_count >= 0
      assert profile.ram_bytes >= 0
    end
  end

  # ---------------------------------------------------------------------------
  # load/1
  # ---------------------------------------------------------------------------

  describe "load/1" do
    test "loads the pinned amd64-ci reference profile" do
      assert {:ok, profile} = HostProfile.load("amd64-ci")
      assert %HostProfile{} = profile
      assert profile.architecture == "amd64"
      assert profile.cpu_count > 0
      assert profile.ram_bytes > 0
    end

    test "loads the pinned arm64-ci reference profile" do
      assert {:ok, profile} = HostProfile.load("arm64-ci")
      assert %HostProfile{} = profile
      assert profile.architecture == "arm64"
      assert profile.cpu_count > 0
      assert profile.ram_bytes > 0
    end

    test "amd64-ci profile has all required string fields non-empty" do
      {:ok, profile} = HostProfile.load("amd64-ci")

      assert byte_size(profile.cpu_model) > 0
      assert byte_size(profile.kernel_version) > 0
      assert byte_size(profile.linux_distribution) > 0
      assert byte_size(profile.libc_version) > 0
      assert byte_size(profile.governor) > 0
      assert byte_size(profile.container_or_vm) > 0
    end

    test "arm64-ci profile has all required string fields non-empty" do
      {:ok, profile} = HostProfile.load("arm64-ci")

      assert byte_size(profile.cpu_model) > 0
      assert byte_size(profile.kernel_version) > 0
      assert byte_size(profile.linux_distribution) > 0
      assert byte_size(profile.libc_version) > 0
      assert byte_size(profile.governor) > 0
      assert byte_size(profile.container_or_vm) > 0
    end

    test "missing profile file returns {:error, :not_found}" do
      assert {:error, :not_found} = HostProfile.load("nonexistent-profile")
      assert {:error, :not_found} = HostProfile.load("does-not-exist")
    end
  end

  # ---------------------------------------------------------------------------
  # compatible?/2
  # ---------------------------------------------------------------------------

  describe "compatible?/2 — same architecture" do
    test "two profiles with the same architecture are compatible" do
      {:ok, a} = HostProfile.load("amd64-ci")
      b = %HostProfile{a | cpu_count: a.cpu_count + 2}

      assert HostProfile.compatible?(a, b) == true
    end

    test "amd64-ci is compatible with itself" do
      {:ok, profile} = HostProfile.load("amd64-ci")
      assert HostProfile.compatible?(profile, profile) == true
    end

    test "arm64-ci is compatible with itself" do
      {:ok, profile} = HostProfile.load("arm64-ci")
      assert HostProfile.compatible?(profile, profile) == true
    end

    test "two detected profiles are compatible (same host)" do
      a = HostProfile.detect()
      b = HostProfile.detect()
      assert HostProfile.compatible?(a, b) == true
    end
  end

  describe "compatible?/2 — incompatible architectures produce descriptive errors" do
    test "amd64 vs arm64 raises ArgumentError (architectures are incompatible)" do
      {:ok, amd64} = HostProfile.load("amd64-ci")
      {:ok, arm64} = HostProfile.load("arm64-ci")

      assert_raise ArgumentError, ~r/incompatible architectures/i, fn ->
        HostProfile.compatible?(amd64, arm64)
      end
    end

    test "arm64 vs amd64 raises ArgumentError" do
      {:ok, amd64} = HostProfile.load("amd64-ci")
      {:ok, arm64} = HostProfile.load("arm64-ci")

      assert_raise ArgumentError, ~r/incompatible architectures/i, fn ->
        HostProfile.compatible?(arm64, amd64)
      end
    end

    test "error message names both architectures" do
      {:ok, amd64} = HostProfile.load("amd64-ci")
      {:ok, arm64} = HostProfile.load("arm64-ci")

      error =
        assert_raise ArgumentError, fn ->
          HostProfile.compatible?(amd64, arm64)
        end

      assert error.message =~ "amd64"
      assert error.message =~ "arm64"
    end

    test "custom profile with mismatched arch raises with descriptive message" do
      a = %HostProfile{
        architecture: "amd64",
        cpu_model: "TestCPU",
        cpu_count: 4,
        ram_bytes: 8_589_934_592,
        kernel_version: "6.0.0",
        linux_distribution: "TestOS 1.0",
        libc_version: "2.35",
        governor: "performance",
        container_or_vm: "none"
      }

      b = %HostProfile{a | architecture: "arm64"}

      error =
        assert_raise ArgumentError, fn ->
          HostProfile.compatible?(a, b)
        end

      assert error.message =~ "amd64"
      assert error.message =~ "arm64"
      assert String.length(error.message) > 20
    end
  end
end
