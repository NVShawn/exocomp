defmodule Exocomp.Node.Collectors.UptimeTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Collectors.Uptime

  @fixtures Path.expand("../../../fixtures/proc", __DIR__)

  # Helper: write content to a temp file and return its path.
  defp tmp_file(content) do
    path =
      Path.join(System.tmp_dir!(), "exocomp_test_uptime_#{:erlang.unique_integer([:positive])}")

    File.write!(path, content)
    on_exit(fn -> File.rm(path) end)
    path
  end

  describe "collect/1 with valid fixture" do
    setup do
      {:ok, path: Path.join(@fixtures, "uptime_valid")}
    end

    test "returns an observation map with required envelope fields", %{path: path} do
      obs = Uptime.collect(proc_uptime: path)

      assert is_map(obs)
      assert is_binary(obs.observed_at)
      assert obs.source == Exocomp.Node.Collectors.Uptime
      assert is_integer(obs.collector_version) and obs.collector_version >= 1
      assert is_integer(obs.duration_us) and obs.duration_us >= 0
      assert is_map(obs.measurements)
    end

    test "parses uptime_seconds as a float with unit 'seconds'", %{path: path} do
      obs = Uptime.collect(proc_uptime: path)
      m = obs.measurements.uptime_seconds

      assert Map.has_key?(m, :value)
      assert Map.has_key?(m, :unit)
      assert m.unit == "seconds"
      assert_in_delta m.value, 12_345.67, 0.001
    end
  end

  describe "collect/1 with malformed fixture" do
    test "returns a malformed partial error" do
      path = Path.join(@fixtures, "uptime_malformed")
      obs = Uptime.collect(proc_uptime: path)
      m = obs.measurements.uptime_seconds

      assert m.error == :malformed
      assert is_binary(m.reason)
    end
  end

  describe "collect/1 when file is unavailable" do
    test "returns an unavailable partial error" do
      obs = Uptime.collect(proc_uptime: "/nonexistent/path/uptime")
      m = obs.measurements.uptime_seconds

      assert m.error == :unavailable
      assert is_binary(m.reason)
    end
  end

  describe "collect/1 with oversized content" do
    test "returns an output_limit partial error" do
      # Build a string > 256 bytes (the max for /proc/uptime)
      big_content = String.duplicate("1 ", 200)
      path = tmp_file(big_content)

      obs = Uptime.collect(proc_uptime: path)
      m = obs.measurements.uptime_seconds

      assert m.error == :output_limit
    end
  end

  describe "observed_at timestamp" do
    test "is a valid ISO 8601 UTC string" do
      path = Path.join(@fixtures, "uptime_valid")
      obs = Uptime.collect(proc_uptime: path)

      assert {:ok, dt, _offset} = DateTime.from_iso8601(obs.observed_at)
      assert dt.time_zone == "Etc/UTC"
    end
  end
end
