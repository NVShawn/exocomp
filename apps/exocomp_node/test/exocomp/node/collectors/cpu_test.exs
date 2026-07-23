defmodule Exocomp.Node.Collectors.CPUTest do
  use ExUnit.Case, async: true

  alias Exocomp.Node.Collectors.CPU

  @fixtures Path.expand("../../../fixtures/proc", __DIR__)

  defp tmp_file(content) do
    path =
      Path.join(
        System.tmp_dir!(),
        "exocomp_test_cpu_#{:erlang.unique_integer([:positive])}"
      )

    File.write!(path, content)
    on_exit(fn -> File.rm(path) end)
    path
  end

  defp valid_opts do
    [
      proc_stat: Path.join(@fixtures, "stat_valid"),
      proc_cpuinfo: Path.join(@fixtures, "cpuinfo_valid")
    ]
  end

  describe "collect/1 with valid fixtures" do
    test "returns observation envelope" do
      obs = CPU.collect(valid_opts())

      assert is_binary(obs.observed_at)
      assert obs.source == Exocomp.Node.Collectors.CPU
      assert obs.collector_version >= 1
      assert is_integer(obs.duration_us)
    end

    test "tick measurements are integers with unit 'ticks'" do
      obs = CPU.collect(valid_opts())
      m = obs.measurements

      tick_keys = [
        :cpu_user_ticks,
        :cpu_nice_ticks,
        :cpu_system_ticks,
        :cpu_idle_ticks,
        :cpu_iowait_ticks,
        :cpu_irq_ticks,
        :cpu_softirq_ticks,
        :cpu_steal_ticks
      ]

      for key <- tick_keys do
        assert Map.has_key?(m, key), "missing key #{key}"
        assert m[key].unit == "ticks", "expected 'ticks' unit for #{key}"
        assert is_integer(m[key].value), "expected integer value for #{key}"
      end
    end

    test "tick values match fixture values" do
      obs = CPU.collect(valid_opts())
      m = obs.measurements

      # From stat_valid: "cpu  100000 2000 50000 800000 1000 500 200 100"
      assert m.cpu_user_ticks.value == 100_000
      assert m.cpu_nice_ticks.value == 2_000
      assert m.cpu_system_ticks.value == 50_000
      assert m.cpu_idle_ticks.value == 800_000
      assert m.cpu_iowait_ticks.value == 1_000
      assert m.cpu_irq_ticks.value == 500
      assert m.cpu_softirq_ticks.value == 200
      assert m.cpu_steal_ticks.value == 100
    end

    test "cpu_count is 2 from fixture" do
      obs = CPU.collect(valid_opts())
      m = obs.measurements

      assert m.cpu_count.value == 2
      assert m.cpu_count.unit == "cores"
    end

    test "cpu_model is parsed from fixture" do
      obs = CPU.collect(valid_opts())
      m = obs.measurements

      assert m.cpu_model.value == "Intel(R) Core(TM) i7-8650U CPU @ 1.90GHz"
      assert m.cpu_model.unit == "string"
    end
  end

  describe "collect/1 with malformed /proc/stat" do
    test "tick fields return malformed errors" do
      path = Path.join(@fixtures, "stat_malformed")

      obs =
        CPU.collect(
          proc_stat: path,
          proc_cpuinfo: Path.join(@fixtures, "cpuinfo_valid")
        )

      m = obs.measurements

      # user ticks has "not_a_number" in the fixture
      assert m.cpu_user_ticks.error == :malformed
    end
  end

  describe "collect/1 when /proc/stat has no aggregate line" do
    test "all tick fields return malformed errors" do
      path = Path.join(@fixtures, "stat_no_aggregate")

      obs =
        CPU.collect(
          proc_stat: path,
          proc_cpuinfo: Path.join(@fixtures, "cpuinfo_valid")
        )

      for key <- [:cpu_user_ticks, :cpu_idle_ticks] do
        assert obs.measurements[key].error == :malformed
      end
    end
  end

  describe "collect/1 when /proc/cpuinfo has no model name" do
    test "cpu_count is correct but cpu_model returns unavailable" do
      obs =
        CPU.collect(
          proc_stat: Path.join(@fixtures, "stat_valid"),
          proc_cpuinfo: Path.join(@fixtures, "cpuinfo_no_model")
        )

      assert obs.measurements.cpu_count.value == 2
      assert obs.measurements.cpu_model.error == :unavailable
    end
  end

  describe "collect/1 when /proc/stat is missing" do
    test "tick fields return unavailable errors" do
      obs =
        CPU.collect(
          proc_stat: "/nonexistent/stat",
          proc_cpuinfo: Path.join(@fixtures, "cpuinfo_valid")
        )

      assert obs.measurements.cpu_user_ticks.error == :unavailable
    end
  end

  describe "collect/1 when /proc/cpuinfo is missing" do
    test "cpuinfo fields return unavailable errors" do
      obs =
        CPU.collect(
          proc_stat: Path.join(@fixtures, "stat_valid"),
          proc_cpuinfo: "/nonexistent/cpuinfo"
        )

      assert obs.measurements.cpu_count.error == :unavailable
      assert obs.measurements.cpu_model.error == :unavailable
    end
  end

  describe "collect/1 partial independence" do
    test "missing stat does not affect cpuinfo fields" do
      obs =
        CPU.collect(
          proc_stat: "/nonexistent/stat",
          proc_cpuinfo: Path.join(@fixtures, "cpuinfo_valid")
        )

      # Tick fields have errors
      assert obs.measurements.cpu_user_ticks.error == :unavailable

      # cpuinfo fields succeed
      assert obs.measurements.cpu_count.value == 2
      assert is_binary(obs.measurements.cpu_model.value)
    end
  end

  describe "collect/1 with oversized /proc/stat" do
    test "tick fields return output_limit error" do
      big = "cpu  " <> Enum.map_join(1..8, " ", fn _ -> "999999" end) <> "\n"
      big_content = String.duplicate(big, 5000)
      path = tmp_file(big_content)

      obs =
        CPU.collect(
          proc_stat: path,
          proc_cpuinfo: Path.join(@fixtures, "cpuinfo_valid")
        )

      assert obs.measurements.cpu_user_ticks.error == :output_limit
    end
  end
end
