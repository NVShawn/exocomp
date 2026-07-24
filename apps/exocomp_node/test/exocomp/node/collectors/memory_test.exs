defmodule Exocomp.Node.Collectors.MemoryTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Collectors.Memory

  @fixtures Path.expand("../../../fixtures/proc", __DIR__)

  defp tmp_file(content) do
    path =
      Path.join(
        System.tmp_dir!(),
        "exocomp_test_meminfo_#{:erlang.unique_integer([:positive])}"
      )

    File.write!(path, content)
    on_exit(fn -> File.rm(path) end)
    path
  end

  describe "collect/1 with valid fixture" do
    setup do
      {:ok, path: Path.join(@fixtures, "meminfo_valid")}
    end

    test "returns observation envelope", %{path: path} do
      obs = Memory.collect(proc_meminfo: path)

      assert is_binary(obs.observed_at)
      assert obs.source == Exocomp.Node.Collectors.Memory
      assert obs.collector_version >= 1
      assert is_integer(obs.duration_us)
    end

    test "all five measurement keys are present", %{path: path} do
      obs = Memory.collect(proc_meminfo: path)
      keys = Map.keys(obs.measurements)

      assert :mem_total_bytes in keys
      assert :mem_free_bytes in keys
      assert :mem_available_bytes in keys
      assert :swap_total_bytes in keys
      assert :swap_free_bytes in keys
    end

    test "values are correct and in bytes (kB * 1024)", %{path: path} do
      obs = Memory.collect(proc_meminfo: path)
      m = obs.measurements

      assert m.mem_total_bytes.value == 16_384_000 * 1024
      assert m.mem_total_bytes.unit == "bytes"

      assert m.mem_free_bytes.value == 8_192_000 * 1024
      assert m.mem_available_bytes.value == 10_240_000 * 1024
      assert m.swap_total_bytes.value == 4_096_000 * 1024
      assert m.swap_free_bytes.value == 4_096_000 * 1024
    end
  end

  describe "collect/1 with partial fixture (one field malformed)" do
    test "successful fields are ok, malformed field is an error" do
      path = Path.join(@fixtures, "meminfo_partial")
      obs = Memory.collect(proc_meminfo: path)
      m = obs.measurements

      # MemFree has "not_a_number" in the fixture
      assert m.mem_free_bytes.error == :malformed

      # Other fields should succeed
      assert m.mem_total_bytes.unit == "bytes"
      assert m.mem_available_bytes.unit == "bytes"
      assert m.swap_total_bytes.unit == "bytes"
      assert m.swap_free_bytes.unit == "bytes"
    end
  end

  describe "collect/1 with missing fields fixture" do
    test "missing fields return unavailable errors" do
      path = Path.join(@fixtures, "meminfo_missing_fields")
      obs = Memory.collect(proc_meminfo: path)
      m = obs.measurements

      # MemTotal is present
      assert m.mem_total_bytes.unit == "bytes"

      # MemFree, MemAvailable, SwapTotal, SwapFree are absent
      assert m.mem_free_bytes.error == :unavailable
      assert m.mem_available_bytes.error == :unavailable
      assert m.swap_total_bytes.error == :unavailable
      assert m.swap_free_bytes.error == :unavailable
    end
  end

  describe "collect/1 when file is unavailable" do
    test "all measurements return unavailable error" do
      obs = Memory.collect(proc_meminfo: "/nonexistent/meminfo")
      m = obs.measurements

      for {_k, v} <- m do
        assert v.error == :unavailable
      end
    end
  end

  describe "collect/1 with oversized content" do
    test "all measurements return output_limit error" do
      big_content = String.duplicate("MemTotal: 1024 kB\n", 10_000)
      path = tmp_file(big_content)

      obs = Memory.collect(proc_meminfo: path)

      for {_k, v} <- obs.measurements do
        assert v.error == :output_limit
      end
    end
  end
end
